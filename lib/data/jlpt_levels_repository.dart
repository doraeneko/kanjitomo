import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Loads assets/jlpt_levels.json (char -> new-style JLPT level, 1=N1
/// hardest .. 5=N5 easiest -- see scripts/build_jlpt_levels.py) and serves
/// level-range lookups for the quiz module. Not every Joyo kanji is
/// JLPT-tested; untested characters are simply absent, not level 0.
class JlptLevelsRepository {
  static const _asset = 'assets/jlpt_levels.json';

  Map<String, int> _levelByChar = {};

  Future<void> load() async {
    final raw =
        jsonDecode(await rootBundle.loadString(_asset)) as Map<String, dynamic>;
    _levelByChar = raw.map((char, level) => MapEntry(char, level as int));
  }

  /// Characters whose level is in [levels] (e.g. {2,3,4,5} for "up to N2").
  List<String> charsInLevels(Set<int> levels) {
    return _levelByChar.entries
        .where((e) => levels.contains(e.value))
        .map((e) => e.key)
        .toList();
  }

  int? levelOf(String char) => _levelByChar[char];

  /// Full char -> level map, for syncing into AppDatabase.kanjiStatic.
  Map<String, int> get all => _levelByChar;
}
