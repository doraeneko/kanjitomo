import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Loads assets/rtk_index.json (char -> Heisig "Remembering the Kanji" 6th
/// edition ordinal index, sourced from KANJIDIC2's own heisig6 dic_ref
/// field -- see kanjirec/scripts/build_rtk_index.py) and serves
/// study-scope lookups ("RTK up to N"). Not every Joyo kanji has an RTK
/// index (5/2140 known glyph-variant gaps); uncovered characters are
/// simply absent, not index 0 -- same convention as jlpt_levels.json.
class RtkIndexRepository {
  static const _asset = 'assets/rtk_index.json';

  Map<String, int> _indexByChar = {};

  Future<void> load() async {
    final raw =
        jsonDecode(await rootBundle.loadString(_asset)) as Map<String, dynamic>;
    _indexByChar = raw.map((char, index) => MapEntry(char, index as int));
  }

  int? indexOf(String char) => _indexByChar[char];

  /// Characters whose RTK index is <= [maxIndex] (e.g. "RTK up to 500").
  List<String> charsUpTo(int maxIndex) {
    return _indexByChar.entries
        .where((e) => e.value <= maxIndex)
        .map((e) => e.key)
        .toList();
  }

  /// Full char -> index map, for syncing into AppDatabase.kanjiStatic.
  Map<String, int> get all => _indexByChar;
}
