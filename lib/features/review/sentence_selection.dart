import 'dart:math';

import 'package:characters/characters.dart';

import '../../data/composita_repository.dart';
import '../../data/kanji_info_repository.dart';
import '../../data/sentences_repository.dart';
import 'reading_splitter.dart' show katakanaToHiragana;
import 'study_scope.dart';

final _rng = Random();

/// Whether composita/sentence testing (C+D) is enabled at all for [scope].
/// Requires the user to have explicitly picked a compositaCeiling -- null
/// means "not opted in yet", not "unrestricted".
bool compositaEnabled(StudyScope scope) => scope.compositaCeiling != null;

/// Whether [composita] is at or easier than [ceiling] -- true
/// unconditionally when there's no ceiling to respect.
///
/// When [charJlptLevel] is provided (the JLPT level of the kanji being
/// studied), a word without a real JLPT tag is allowed if the target
/// kanji's own level is within the ceiling. This relaxes the old rule
/// that required ALL kanji in the word to be within the ceiling (via
/// inferredJlptLevel = hardest kanji), so more composita are available --
/// e.g. 食堂 (食=N4, 堂=N2) becomes eligible when studying 食 at ceiling
/// N4, even though 堂 is N2. Words with a real JLPT tag always use that.
bool compositaWithinCeiling(
  Composita composita,
  int? ceiling, {
  int? charJlptLevel,
}) {
  if (ceiling == null) return true;
  // Prefer the word's own real JLPT tag when available.
  if (composita.jlptLevel != null) {
    return composita.jlptLevel! >= ceiling;
  }
  // Fall back to the inferred level (hardest kanji in the word).
  // Don't use the character's own JLPT level as a proxy — a common N4
  // kanji like 食 appears in N1 words like 飽食, and using the character's
  // easy level would let those hard words through the ceiling.
  final level = composita.inferredJlptLevel;
  return level != null && level >= ceiling;
}

/// Which of [all] (one character's composita) are actually eligible for
/// C+D testing under [scope]: exactly [customSelected] (the words
/// explicitly selected for this character via the composita picker).
/// If no custom selection exists, falls back to ceiling-based filtering
/// using the scope's compositaCeiling.
///
/// [charJlptLevel] is the JLPT level of the kanji whose composita are
/// being filtered -- passed through to [compositaWithinCeiling] to relax
/// the inference for words without a real JLPT tag.
List<Composita> eligibleComposita(
  List<Composita> all,
  StudyScope scope,
  Set<String> customSelected, {
  int? charJlptLevel,
}) {
  // Skip kana-only words — they have no kanji to test.
  bool hasKanji(Composita c) => c.word.runes.any((r) => isKanji(r));

  if (customSelected.isNotEmpty) {
    return all
        .where((c) => customSelected.contains(c.word) && hasKanji(c))
        .toList();
  }
  final ceiling = scope.compositaCeiling;
  return all
      .where((c) =>
          hasKanji(c) &&
          compositaWithinCeiling(c, ceiling, charJlptLevel: charJlptLevel))
      .toList();
}

/// Picks which of [eligible] composita to test next, preferring one whose
/// reading isn't already in [testedWords] -- so a character with several
/// testable readings actually gets exercised on all of them over repeated
/// reviews, instead of always landing on the same (first, usually
/// frequency-ranked) word forever. Falls back to a random entry once
/// everything in [eligible] has already been tested at least once (still
/// worth reviewing, just no longer "new" — random avoids always drilling
/// the same word). Null when [eligible] is empty.
Composita? pickUntested(List<Composita> eligible, Set<String> testedWords) {
  for (final c in eligible) {
    if (!testedWords.contains(c.word)) return c;
  }
  return eligible.isEmpty ? null : eligible[_rng.nextInt(eligible.length)];
}

/// Whether [codeUnit] is a CJK ideograph (kanji).
bool isKanji(int codeUnit) =>
    (codeUnit >= 0x4E00 && codeUnit <= 0x9FFF) ||
    (codeUnit >= 0x3400 && codeUnit <= 0x4DBF);

/// Merges bundled composita with user-added ones, deduplicating by word.
List<Composita> mergeComposita(
  List<Composita> bundled,
  List<Composita>? userAdded,
) {
  if (userAdded == null || userAdded.isEmpty) return bundled;
  final seen = bundled.map((c) => c.word).toSet();
  final merged = [...bundled];
  for (final c in userAdded) {
    if (seen.add(c.word)) merged.add(c);
  }
  return merged;
}

/// Best-effort extraction of [char]'s reading within a composita word.
///
/// Strips trailing okurigana (kana at the end of the word that matches the
/// end of the reading), then splits the remaining reading evenly among the
/// kanji characters. Returns the segment corresponding to [char]'s position.
/// Falls back to the full reading if extraction fails.
String kanjiReadingIn(String char, Composita composita) {
  final word = composita.word;
  final reading = composita.reading;
  final wordChars = word.characters.toList();

  // Use pre-computed splits when available — they're accurate per-character
  // readings from the build script, unlike the naive even-split fallback.
  final splits = composita.splits;
  if (splits != null && splits.length == wordChars.length) {
    for (var i = 0; i < wordChars.length; i++) {
      if (wordChars[i] == char) return splits[i];
    }
  }

  // Fallback: find position of the target character among kanji-only characters.
  final kanjiPositions = <int>[];
  int? targetKanjiIndex;
  for (var i = 0; i < wordChars.length; i++) {
    final c = wordChars[i];
    if (c.length == 1 && isKanji(c.codeUnitAt(0))) {
      if (c == char && targetKanjiIndex == null) {
        targetKanjiIndex = kanjiPositions.length;
      }
      kanjiPositions.add(i);
    }
  }

  if (targetKanjiIndex == null || kanjiPositions.isEmpty) return reading;

  // Strip trailing okurigana: kana characters at the end of the word that
  // match the end of the reading.
  final readingChars = reading.characters.toList();
  var okuriganaCount = 0;
  var wi = wordChars.length - 1;
  var ri = readingChars.length - 1;
  while (wi >= 0 && ri >= 0) {
    final wc = wordChars[wi];
    if (wc.length == 1 && isKanji(wc.codeUnitAt(0))) break;
    if (wc == readingChars[ri]) {
      okuriganaCount++;
      wi--;
      ri--;
    } else {
      break;
    }
  }

  final kanjiReading =
      readingChars.sublist(0, readingChars.length - okuriganaCount);
  final kanjiCount = kanjiPositions.length;
  if (kanjiCount == 0 || kanjiReading.isEmpty) return reading;

  // Split evenly among kanji.
  final charsPerKanji = kanjiReading.length / kanjiCount;
  final start = (targetKanjiIndex * charsPerKanji).round();
  final end = ((targetKanjiIndex + 1) * charsPerKanji).round()
      .clamp(start, kanjiReading.length);
  if (start >= kanjiReading.length) return reading;

  return kanjiReading.sublist(start, end).join();
}

/// Selects up to [limit] composita for introduction, preferring reading
/// diversity so the user sees the kanji used in different readings.
///
/// The input list is already sorted by frequency (from composita.json's
/// pre-sorted order, filtered through eligibleComposita).
///
/// 1. **First pass (greedy reading coverage):** Walk the list in frequency
///    order. For each word, extract the approximate reading of [char] within
///    the word. If that reading hasn't been seen yet **and** it matches a
///    known on/kun reading of the kanji, pick it. Jukujikun words (e.g.
///    河童 かっぱ) where the per-character split doesn't correspond to any
///    real reading are skipped in this pass — they can still be selected in
///    the frequency-fill pass.
/// 2. **Second pass (fill remaining slots):** Fill up to [limit] with the
///    next most frequent words not yet picked.
/// 3. Return the selected composita in their original frequency order.
List<Composita> selectCompositaForIntroduction(
  String char,
  List<Composita> eligible,
  int limit, {
  KanjiInfo? kanjiInfo,
}) {
  // Deduplicate by word first — the DB key is (character, word), so two
  // entries with the same word but different readings (e.g. 旧 read as
  // きゅう vs もと) would collapse into one row anyway. Keep the first
  // (highest-frequency) entry for each word.
  final seenWords = <String>{};
  final deduped = <Composita>[];
  for (final c in eligible) {
    if (seenWords.add(c.word)) deduped.add(c);
  }
  if (deduped.length <= limit) return deduped;

  // Build set of known readings in hiragana (stripping okurigana markers)
  // so the first pass can skip jukujikun words whose per-character split
  // doesn't match any real reading.
  final knownReadings = <String>{};
  if (kanjiInfo != null) {
    for (final on in kanjiInfo.on) {
      knownReadings.add(katakanaToHiragana(on));
    }
    for (final kun in kanjiInfo.kun) {
      // Strip okurigana after "." (e.g. "まな.ぶ" → "まな")
      final dot = kun.indexOf('.');
      knownReadings.add(dot >= 0 ? kun.substring(0, dot) : kun);
    }
    // Also strip trailing "-" bound-form marker (e.g. "かわ-" → "かわ")
    knownReadings.addAll(
      knownReadings.map((r) => r.endsWith('-') ? r.substring(0, r.length - 1) : r).toList(),
    );
  }

  // Count how many eligible words use each reading. Readings that appear
  // in only one word are likely rare/obscure — not worth chasing in the
  // greedy diversity pass (they can still be selected in the frequency
  // fill pass if they rank high enough).
  final readingCounts = <String, int>{};
  for (final c in deduped) {
    final r = kanjiReadingIn(char, c);
    if (knownReadings.isNotEmpty && !knownReadings.contains(r)) continue;
    readingCounts[r] = (readingCounts[r] ?? 0) + 1;
  }

  final picked = <int>{};
  final seenReadings = <String>{};

  // First pass: greedily cover distinct readings, skipping jukujikun
  // and rare readings (those used by only a single eligible word).
  for (var i = 0; i < deduped.length && picked.length < limit; i++) {
    final reading = kanjiReadingIn(char, deduped[i]);
    if (knownReadings.isNotEmpty && !knownReadings.contains(reading)) continue;
    if ((readingCounts[reading] ?? 0) < 2) continue;
    if (seenReadings.add(reading)) picked.add(i);
  }

  // Second pass: fill remaining slots with next most frequent, still
  // skipping jukujikun words whose per-character reading doesn't match
  // any known on/kun reading.
  for (var i = 0; i < deduped.length && picked.length < limit; i++) {
    if (knownReadings.isNotEmpty) {
      final reading = kanjiReadingIn(char, deduped[i]);
      if (!knownReadings.contains(reading)) continue;
    }
    picked.add(i); // add returns false for duplicates, set handles it
  }

  // Return in original (frequency) order.
  final sorted = picked.toList()..sort();
  return [for (final i in sorted) deduped[i]];
}

/// A single-token stand-in "sentence" for [composita], used when it has no
/// real example-sentence coverage -- lets composita-only testing (C: draw/
/// read the word in isolation, no mined sentence context) run through the
/// same [FuriganaSentence]-based card builders as a real sentence (D),
/// since that widget already accepts a plain token list and only cares
/// which one is flagged as the target.
ExampleSentence syntheticSentenceFor(Composita composita) {
  return ExampleSentence(
    sentence: composita.word,
    tokens: [
      SentenceToken(
        surface: composita.word,
        reading: composita.reading,
        isTarget: true,
      ),
    ],
    jlptLevel: composita.effectiveJlptLevel ?? 5,
    source: 'synthetic',
    translation: composita.meaning,
  );
}
