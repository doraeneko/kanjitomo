import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Loads assets/kanji_level_rank.json (char -> 0-based rank within its own
/// JLPT level, sorted by newspaper frequency -- see
/// kanjirec/scripts/build_kanji_level_rank.py) and serves the JLPT
/// "sublevel" chunking filter (splitting a whole level, e.g. N1's 985
/// kanji, into smaller frequency-sorted groups). Not every JLPT-leveled
/// kanji has a rank (a small number lack a frequency value entirely);
/// uncovered characters are simply absent, not rank 0 -- same convention
/// as jlpt_levels.json/rtk_index.json.
class KanjiLevelRankRepository {
  static const _asset = 'assets/kanji_level_rank.json';

  Map<String, int> _rankByChar = {};

  Future<void> load() async {
    final raw =
        jsonDecode(await rootBundle.loadString(_asset)) as Map<String, dynamic>;
    _rankByChar = raw.map((char, rank) => MapEntry(char, rank as int));
  }

  int? rankOf(String char) => _rankByChar[char];

  /// Full char -> rank map, for syncing into AppDatabase.kanjiStatic.
  Map<String, int> get all => _rankByChar;
}
