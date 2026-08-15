import '../../data/kanji_info_repository.dart';
import '../../data/sentences_repository.dart';
import 'sentence_selection.dart';

/// Converts a katakana string to hiragana by shifting code units.
String katakanaToHiragana(String s) {
  final buf = StringBuffer();
  for (final c in s.codeUnits) {
    // Katakana range 0x30A0-0x30FF → hiragana 0x3040-0x309F
    if (c >= 0x30A1 && c <= 0x30F6) {
      buf.writeCharCode(c - 0x60);
    } else {
      buf.writeCharCode(c);
    }
  }
  return buf.toString();
}

bool _isHiragana(int c) => c >= 0x3040 && c <= 0x309F;
bool _isKatakana(int c) => c >= 0x30A0 && c <= 0x30FF;
bool _isKana(int c) => _isHiragana(c) || _isKatakana(c);

/// Extracts the set of possible readings for a kanji from its [KanjiInfo].
///
/// On'yomi are converted from katakana to hiragana.
/// Kun'yomi have okurigana stripped (everything after the dot).
/// Duplicates are removed.
List<String> _readingsFor(KanjiInfo info) {
  final result = <String>{};
  for (final on in info.on) {
    result.add(katakanaToHiragana(on));
  }
  for (final kun in info.kun) {
    // Strip leading '-' (suffix marker).
    var reading = kun.startsWith('-') ? kun.substring(1) : kun;
    // Strip okurigana after the dot.
    final dot = reading.indexOf('.');
    if (dot >= 0) reading = reading.substring(0, dot);
    if (reading.isNotEmpty) result.add(reading);
  }
  return result.toList();
}

/// Splits a composita word's full reading into per-character segments.
///
/// Returns a list parallel to the word's characters (Unicode grapheme clusters).
/// Each entry is the hiragana reading substring for that character position.
/// Returns null if splitting fails (ambiguous paths are fine — first valid
/// solution is returned).
///
/// Algorithm: walk the word left-to-right with recursive backtracking.
/// - Kana characters must match themselves in the reading (consumed 1:1).
/// - Kanji characters try each known reading from [kanjiLookup]; the first
///   assignment where the rest of the word can also be satisfied wins.
List<String>? splitReading(
  String word,
  String reading,
  KanjiInfo? Function(String char) kanjiLookup,
) {
  final wordChars = word.split('');
  final readingChars = reading.split('');
  final result = List<String?>.filled(wordChars.length, null);

  if (_solve(wordChars, readingChars, 0, 0, result, kanjiLookup)) {
    return result.cast<String>();
  }
  return null;
}

bool _solve(
  List<String> wordChars,
  List<String> readingChars,
  int wi, // word index
  int ri, // reading index
  List<String?> result,
  KanjiInfo? Function(String) kanjiLookup,
) {
  // Both exhausted — success.
  if (wi == wordChars.length && ri == readingChars.length) return true;
  // One exhausted, the other not — failure.
  if (wi == wordChars.length || ri == readingChars.length) return false;

  final char = wordChars[wi];
  final charCode = char.codeUnitAt(0);

  if (_isKana(charCode)) {
    // Kana: must match itself in the reading (comparing in hiragana).
    final expected = _isKatakana(charCode)
        ? katakanaToHiragana(char)
        : char;
    final actual = _isKatakana(readingChars[ri].codeUnitAt(0))
        ? katakanaToHiragana(readingChars[ri])
        : readingChars[ri];
    if (expected != actual) return false;
    result[wi] = char; // kana reads as itself
    if (_solve(wordChars, readingChars, wi + 1, ri + 1, result, kanjiLookup)) {
      return true;
    }
    result[wi] = null;
    return false;
  }

  // Kanji: try each known reading.
  if (isKanji(charCode)) {
    final info = kanjiLookup(char);
    if (info == null) {
      // Unknown kanji — try consuming 1..remaining reading chars greedily.
      return _tryLengths(wordChars, readingChars, wi, ri, result, kanjiLookup);
    }
    final readings = _readingsFor(info);
    for (final r in readings) {
      final rChars = r.split('');
      if (ri + rChars.length > readingChars.length) continue;
      // Check if this reading matches the reading at current position.
      var matches = true;
      for (var i = 0; i < rChars.length; i++) {
        if (readingChars[ri + i] != rChars[i]) {
          matches = false;
          break;
        }
      }
      if (!matches) continue;
      result[wi] = r;
      if (_solve(
        wordChars, readingChars, wi + 1, ri + rChars.length,
        result, kanjiLookup,
      )) {
        return true;
      }
    }
    // No known reading worked. For kanji WITH dictionary entries this means
    // the compound uses a non-standard reading (rendaku, special compound
    // reading, etc.) that we can't reliably assign — bail out rather than
    // guess wrong. Only fall back to variable-length consumption for kanji
    // absent from the dictionary entirely.
    return false;
  }

  // Other character (punctuation, etc.) — try matching literally.
  if (readingChars[ri] == char) {
    result[wi] = char;
    if (_solve(wordChars, readingChars, wi + 1, ri + 1, result, kanjiLookup)) {
      return true;
    }
    result[wi] = null;
  }
  return false;
}

/// Fallback: try consuming 1..N reading characters for an unknown character.
bool _tryLengths(
  List<String> wordChars,
  List<String> readingChars,
  int wi,
  int ri,
  List<String?> result,
  KanjiInfo? Function(String) kanjiLookup,
) {
  final remaining = readingChars.length - ri;
  final charsLeft = wordChars.length - wi - 1;
  // Each remaining word char needs at least 1 reading char.
  final maxConsume = remaining - charsLeft;
  for (var len = 1; len <= maxConsume; len++) {
    result[wi] = readingChars.sublist(ri, ri + len).join();
    if (_solve(
      wordChars, readingChars, wi + 1, ri + len,
      result, kanjiLookup,
    )) {
      return true;
    }
  }
  result[wi] = null;
  return false;
}

/// Splits a target [SentenceToken] into per-character sub-tokens using
/// [splitReading] to assign each character its reading segment.
///
/// For reading-cloze cards with unseen-kanji hints:
/// - Characters in [seenCharacters] get `isTarget = true` (reading hidden).
/// - Unseen kanji get `isTarget = false` (reading shown as a hint).
/// - Kana always get `isTarget = true` (reading == surface, so furigana is
///   suppressed naturally).
///
/// If [splitReading] fails, returns null (caller should fall back to the
/// original unsplit token).
List<SentenceToken>? splitTargetToken(
  SentenceToken target,
  KanjiInfo? Function(String) kanjiLookup,
  Set<String> seenCharacters, {
  List<String>? precomputedSplits,
}) {
  // Use pre-computed splits if they match this token's reading; fall back
  // to the algorithmic splitter otherwise (the sentence may use a different
  // reading than composita.json).
  List<String>? segments;
  if (precomputedSplits != null &&
      precomputedSplits.length == target.surface.length &&
      precomputedSplits.join() == target.reading) {
    segments = precomputedSplits;
  }
  final resolved = segments ??
      splitReading(target.surface, target.reading, kanjiLookup);
  if (resolved == null) return null;

  final chars = target.surface.split('');
  if (chars.length != resolved.length) return null;

  return List.generate(chars.length, (i) {
    final char = chars[i];
    final charCode = char.codeUnitAt(0);
    final isCjk = isKanji(charCode);
    // Unseen kanji → isTarget=false so FuriganaSentence shows the reading.
    // Seen kanji + kana → isTarget=true (reading hidden by hideTargetReading).
    final isTargetToken = !isCjk || seenCharacters.contains(char);
    return SentenceToken(
      surface: char,
      reading: resolved[i],
      isTarget: isTargetToken,
    );
  });
}

