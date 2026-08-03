import '../../data/kanji_info_repository.dart';

/// Converts katakana to hiragana, leaving everything else (including
/// existing hiragana) untouched -- lets a search query typed in either
/// kana script match on'yomi (kanji_info.json stores these in katakana) or
/// kun'yomi (stored in hiragana) alike, since a learner searching by
/// reading rarely thinks about which script a given entry happens to use.
String toHiragana(String s) {
  final buffer = StringBuffer();
  for (final rune in s.runes) {
    buffer.writeCharCode(
      rune >= 0x30A1 && rune <= 0x30F6 ? rune - 0x60 : rune,
    );
  }
  return buffer.toString();
}

/// Strips kanji_info.json's own reading markup: "." separates a kun'yomi
/// stem from its okurigana (まな.ぶ), a trailing "-" marks a bound/prefix
/// form (ひと-) -- neither is part of the reading a user would actually
/// type into a search box.
String _stripReadingMarkup(String reading) =>
    reading.replaceAll('.', '').replaceAll('-', '');

/// Whether [query] (expected already trimmed) matches [character] --
/// covers all three kanji-browser search modes the same box supports: a
/// bare integer matches by exact stroke count (from stroke_paths.json,
/// passed in as [strokeCount] since that lookup is the caller's DB/asset
/// concern, not this pure function's); anything else matches the
/// character itself, any on'yomi/kun'yomi in [info] (either kana script,
/// ignoring the "."/"-" markup), or any meaning phrase (case-insensitive
/// substring). An empty query always matches (no filter applied).
bool matchesKanjiSearch({
  required String character,
  required KanjiInfo? info,
  required int? strokeCount,
  required String query,
}) {
  if (query.isEmpty) return true;

  final asStrokeCount = int.tryParse(query);
  if (asStrokeCount != null) return strokeCount == asStrokeCount;

  if (character == query) return true;
  if (info == null) return false;

  final normalizedQuery = toHiragana(query);
  final matchesReading = [
    ...info.on,
    ...info.kun,
  ].any((r) => toHiragana(_stripReadingMarkup(r)).contains(normalizedQuery));
  if (matchesReading) return true;

  final lowerQuery = query.toLowerCase();
  return info.meanings.any((m) => m.toLowerCase().contains(lowerQuery));
}
