import 'dart:math';

import 'package:characters/characters.dart';

import '../../data/composita_repository.dart';
import '../../data/kanji_info_repository.dart';
import '../review/reading_splitter.dart';

final _rng = Random();

/// Levenshtein edit distance on two strings (grapheme-cluster-level).
int editDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  final aChars = a.characters.toList();
  final bChars = b.characters.toList();
  final m = aChars.length;
  final n = bChars.length;

  // Single-row DP.
  var prev = List.generate(n + 1, (j) => j);
  for (var i = 1; i <= m; i++) {
    final curr = List.filled(n + 1, 0);
    curr[0] = i;
    for (var j = 1; j <= n; j++) {
      final cost = aChars[i - 1] == bChars[j - 1] ? 0 : 1;
      curr[j] = [
        prev[j] + 1, // deletion
        curr[j - 1] + 1, // insertion
        prev[j - 1] + cost, // substitution
      ].reduce(min);
    }
    prev = curr;
  }
  return prev[n];
}

// ---------------------------------------------------------------------------
// Phonetic confusion operators for Japanese reading distractors
// ---------------------------------------------------------------------------

/// Voicing (dakuten) pairs: unvoiced ↔ voiced.
const _voicingPairs = <String, String>{
  'か': 'が', 'が': 'か',
  'き': 'ぎ', 'ぎ': 'き',
  'く': 'ぐ', 'ぐ': 'く',
  'け': 'げ', 'げ': 'け',
  'こ': 'ご', 'ご': 'こ',
  'さ': 'ざ', 'ざ': 'さ',
  'し': 'じ', 'じ': 'し',
  'す': 'ず', 'ず': 'す',
  'せ': 'ぜ', 'ぜ': 'せ',
  'そ': 'ぞ', 'ぞ': 'そ',
  'た': 'だ', 'だ': 'た',
  'ち': 'ぢ', 'ぢ': 'ち',
  'つ': 'づ', 'づ': 'つ',
  'て': 'で', 'で': 'て',
  'と': 'ど', 'ど': 'と',
};

/// Ha-row cycling: は→ば→ぱ→は, etc.
const _haRowCycle = <String, List<String>>{
  'は': ['ば', 'ぱ'], 'ば': ['は', 'ぱ'], 'ぱ': ['は', 'ば'],
  'ひ': ['び', 'ぴ'], 'び': ['ひ', 'ぴ'], 'ぴ': ['ひ', 'び'],
  'ふ': ['ぶ', 'ぷ'], 'ぶ': ['ふ', 'ぷ'], 'ぷ': ['ふ', 'ぶ'],
  'へ': ['べ', 'ぺ'], 'べ': ['へ', 'ぺ'], 'ぺ': ['へ', 'べ'],
  'ほ': ['ぼ', 'ぽ'], 'ぼ': ['ほ', 'ぽ'], 'ぽ': ['ほ', 'ぼ'],
};

/// Kana in the お-column that take う for long vowels.
const _oColumnKana = {'お', 'こ', 'そ', 'と', 'の', 'ほ', 'も', 'よ', 'ろ',
    'ご', 'ぞ', 'ど', 'ぼ', 'ぽ'};

/// Kana in the い-column that take い for long vowels.
const _iColumnKana = {'い', 'き', 'し', 'ち', 'に', 'ひ', 'み', 'り',
    'ぎ', 'じ', 'ぢ', 'び', 'ぴ'};

/// Consonant-initial kana (can be preceded by っ for gemination).
const _consonantKana = {
  'か', 'き', 'く', 'け', 'こ', 'が', 'ぎ', 'ぐ', 'げ', 'ご',
  'さ', 'し', 'す', 'せ', 'そ', 'ざ', 'じ', 'ず', 'ぜ', 'ぞ',
  'た', 'ち', 'つ', 'て', 'と', 'だ', 'ぢ', 'づ', 'で', 'ど',
  'は', 'ひ', 'ふ', 'へ', 'ほ', 'ば', 'び', 'ぶ', 'べ', 'ぼ',
  'ぱ', 'ぴ', 'ぷ', 'ぺ', 'ぽ',
};

/// Apply one phonetic transformation to [correct] at a time.
/// Returns distinct single-op variants excluding the original.
List<String> _singleTransformations(String correct) {
  final results = <String>{};
  final chars = correct.split('');

  for (var i = 0; i < chars.length; i++) {
    final c = chars[i];

    // 1. Voicing toggle (rendaku): か↔が, た↔だ, etc.
    final voiced = _voicingPairs[c];
    if (voiced != null) {
      results.add(_replace(chars, i, voiced));
    }

    // 2. Ha-row cycling: は↔ば↔ぱ.
    final haAlts = _haRowCycle[c];
    if (haAlts != null) {
      for (final alt in haAlts) {
        results.add(_replace(chars, i, alt));
      }
    }

    // 3. Long vowel: insert/remove う after お-column kana.
    if (_oColumnKana.contains(c)) {
      if (i + 1 < chars.length && chars[i + 1] == 'う') {
        results.add(_removeAt(chars, i + 1));
      } else if (i + 1 >= chars.length || chars[i + 1] != 'う') {
        results.add(_insertAfter(chars, i, 'う'));
      }
    }

    // 5. Long vowel: insert/remove い after い-column kana.
    if (_iColumnKana.contains(c)) {
      if (i + 1 < chars.length && chars[i + 1] == 'い') {
        results.add(_removeAt(chars, i + 1));
      } else if (i + 1 >= chars.length || chars[i + 1] != 'い') {
        results.add(_insertAfter(chars, i, 'い'));
      }
    }

    // 6. Gemination: insert/remove っ before consonant kana.
    if (_consonantKana.contains(c) && i > 0) {
      if (chars[i - 1] == 'っ') {
        results.add(_removeAt(chars, i - 1));
      } else if (chars[i - 1] != 'っ') {
        results.add(_insertBefore(chars, i, 'っ'));
      }
    }

    // 7. ん insertion/removal before consonant kana.
    if (_consonantKana.contains(c) && i > 0) {
      if (chars[i - 1] == 'ん') {
        results.add(_removeAt(chars, i - 1));
      } else if (chars[i - 1] != 'ん' && chars[i - 1] != 'っ') {
        results.add(_insertBefore(chars, i, 'ん'));
      }
    }
  }

  results.remove(correct);
  return results.toList();
}

/// Generate confusable readings by applying 1 or 2 phonetic transformations
/// to [correct]. Single-op variants are generated first; if fewer than
/// [minCount], double-op variants (applying a second transformation to each
/// single-op result) are added.
///
/// All variants are filtered to be within ±1 character of the correct
/// reading's length, so no distractor is obviously too long or too short.
List<String> confusableReadings(String correct, {int minCount = 6}) {
  final correctLen = correct.length;
  bool plausibleLength(String s) => (s.length - correctLen).abs() <= 1;

  final singles = _singleTransformations(correct)
      .where(plausibleLength).toList();
  final results = <String>{...singles};

  // If we already have enough, return early.
  if (results.length >= minCount) {
    return results.toList();
  }

  // Apply a second transformation to each single-op variant.
  for (final variant in singles) {
    if (results.length >= minCount * 2) break;
    for (final double in _singleTransformations(variant)) {
      if (double != correct && plausibleLength(double)) results.add(double);
    }
  }

  return results.toList();
}

String _replace(List<String> chars, int i, String replacement) {
  return [...chars.sublist(0, i), replacement, ...chars.sublist(i + 1)].join();
}

String _removeAt(List<String> chars, int i) {
  return [...chars.sublist(0, i), ...chars.sublist(i + 1)].join();
}

String _insertAfter(List<String> chars, int i, String insertion) {
  return [...chars.sublist(0, i + 1), insertion, ...chars.sublist(i + 1)].join();
}

String _insertBefore(List<String> chars, int i, String insertion) {
  return [...chars.sublist(0, i), insertion, ...chars.sublist(i)].join();
}

/// Picks 3 distractor readings from [pool] for a full-word reading quiz.
///
/// Generates distractors exclusively from phonetic transformations of
/// [correct] (1 or 2 ops applied). Every distractor is guaranteed to look
/// like a plausible misreading of the correct answer.
List<String> readingDistractors(String correct, List<Composita> pool) {
  final confusable = confusableReadings(correct);

  if (confusable.length <= 3) {
    return confusable.toList()..shuffle(_rng);
  }

  // Prefer single-op variants (more plausible), shuffle, take 3.
  confusable.shuffle(_rng);
  return confusable.take(3).toList();
}

/// Picks 3 distractor readings for a per-character reading quiz.
///
/// Generates distractors exclusively by applying 1–2 phonetic
/// transformations to [correctReading]. No pool/on-kun fallback — every
/// distractor is a plausible confusion of the correct answer.
///
/// When [wordSplits] and [targetIndex] are provided, returns **full-word
/// readings** where only the tested character's portion is swapped
/// (e.g. ひゃっきん → ひゃっぎん).
List<String> charReadingDistractors(
  String correctReading,
  String targetChar,
  KanjiInfo? Function(String) kanjiLookup,
  List<Composita> pool, {
  List<String>? wordSplits,
  int? targetIndex,
}) {
  final correctLen = correctReading.length;
  bool plausibleLength(String s) => (s.length - correctLen).abs() <= 1;

  // Collect all valid on/kun readings of the tested kanji so we can
  // exclude any confusable variant that accidentally matches a real
  // alternative reading (which would be a second correct answer).
  final validReadings = <String>{correctReading};
  final info = kanjiLookup(targetChar);
  if (info != null) {
    for (final on in info.on) {
      validReadings.add(katakanaToHiragana(on));
    }
    for (final kun in info.kun) {
      var reading = kun.startsWith('-') ? kun.substring(1) : kun;
      final dot = reading.indexOf('.');
      if (dot >= 0) reading = reading.substring(0, dot);
      if (reading.isNotEmpty) validReadings.add(reading);
    }
  }

  final confusable = confusableReadings(correctReading);
  // Remove any confusable variant that is actually a valid reading.
  final candidates = <String>{
    ...confusable.where((v) => !validReadings.contains(v)),
  };

  // If confusable transformations alone aren't enough (common for short
  // readings like し where only voicing gives じ but じ might be a valid
  // reading too), add on/kun readings of similar length as fallback
  // distractors (these ARE real readings, just not the tested one).
  if (candidates.length < 3 && info != null) {
    for (final on in info.on) {
      final hira = katakanaToHiragana(on);
      if (hira != correctReading && plausibleLength(hira)) {
        candidates.add(hira);
      }
    }
    for (final kun in info.kun) {
      var reading = kun.startsWith('-') ? kun.substring(1) : kun;
      final dot = reading.indexOf('.');
      if (dot >= 0) reading = reading.substring(0, dot);
      if (reading.isNotEmpty &&
          reading != correctReading &&
          plausibleLength(reading)) {
        candidates.add(reading);
      }
    }
  }

  // Shuffle and pick 3, preferring confusable variants.
  final confusableSet = confusable.toSet();
  final sorted = candidates.toList()
    ..sort((a, b) {
      final aConf = confusableSet.contains(a) ? 0 : 1;
      final bConf = confusableSet.contains(b) ? 0 : 1;
      return aConf.compareTo(bConf);
    });
  final picked = sorted.take(3).toList()..shuffle(_rng);

  // If we have word splits, assemble full-word readings and verify none
  // accidentally matches the correct full-word reading.
  if (wordSplits != null && targetIndex != null && targetIndex < wordSplits.length) {
    final correctFull = wordSplits.join();
    return picked.map((alt) {
      final parts = [...wordSplits];
      parts[targetIndex] = alt;
      return parts.join();
    }).where((r) => r != correctFull).toList();
  }

  return picked;
}

// ---------------------------------------------------------------------------
// Kanji word distractors with radical-based visual similarity
// ---------------------------------------------------------------------------

/// Picks 3 distractor words from [pool] for a kanji quiz question.
///
/// When [kanjiLookup] is provided, prefers words where one kanji is swapped
/// for a visually similar kanji (sharing radicals). Falls back to the
/// shared-character / similar-length heuristic.
List<String> kanjiWordDistractors(
  String correctWord,
  List<Composita> pool, {
  KanjiInfo? Function(String)? kanjiLookup,
  Set<String>? scopeCharacters,
  int? scopeJlptLevel,
  int? Function(String)? jlptLevelOf,
}) {
  final candidates = pool
      .map((c) => c.word)
      .toSet()
      .where((w) => w != correctWord)
      .toList();

  if (candidates.length <= 3) return candidates..shuffle(_rng);

  // Build radical-similarity scores if we have kanji lookup.
  final radicalScores = <String, int>{};
  if (kanjiLookup != null) {
    final correctChars = correctWord.split('');
    // Build a map: for each kanji in correctWord, find its radicals.
    final correctRadicals = <String, Set<String>>{};
    for (final ch in correctChars) {
      final info = kanjiLookup(ch);
      if (info != null && info.radicals.isNotEmpty) {
        correctRadicals[ch] = info.radicals.toSet();
      }
    }

    if (correctRadicals.isNotEmpty) {
      for (final word in candidates) {
        var score = 0;
        final wordChars = word.split('');
        for (final wc in wordChars) {
          if (wc == correctWord) continue;
          final wcInfo = kanjiLookup(wc);
          if (wcInfo == null) continue;
          final wcRadicals = wcInfo.radicals.toSet();
          for (final entry in correctRadicals.entries) {
            if (wc == entry.key) {
              score += 2;
            } else {
              final shared = wcRadicals.intersection(entry.value).length;
              if (shared > 0) score += shared;
            }
          }
        }

        if (scopeCharacters != null || scopeJlptLevel != null) {
          var eligible = true;
          for (final wc in wordChars) {
            final code = wc.codeUnitAt(0);
            if (code < 0x4E00 || code > 0x9FFF) continue;
            if (scopeCharacters != null && scopeCharacters.contains(wc)) {
              continue;
            }
            if (jlptLevelOf != null && scopeJlptLevel != null) {
              final level = jlptLevelOf(wc);
              if (level != null && level >= scopeJlptLevel) continue;
            }
            eligible = false;
            break;
          }
          if (!eligible) score = -1;
        }

        radicalScores[word] = score;
      }
    }
  }

  final correctChars = correctWord.characters.toSet();
  final correctLen = correctWord.characters.length;

  candidates.sort((a, b) {
    final aRad = radicalScores[a] ?? 0;
    final bRad = radicalScores[b] ?? 0;
    if (aRad != bRad) return bRad.compareTo(aRad);

    final aShared = a.characters.where(correctChars.contains).length;
    final bShared = b.characters.where(correctChars.contains).length;
    if (aShared != bShared) return bShared.compareTo(aShared);

    final aDiff = (a.characters.length - correctLen).abs();
    final bDiff = (b.characters.length - correctLen).abs();
    return aDiff.compareTo(bDiff);
  });

  return candidates.take(3).toList()..shuffle(_rng);
}
