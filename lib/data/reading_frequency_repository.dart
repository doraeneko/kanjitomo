import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Per-kanji reading frequency counts derived from composita word splits.
/// Maps each kanji to {reading (hiragana): count of composita words using it}.
/// Used to dim/italicize obscure readings that appear in only one or two words.
class ReadingFrequencyRepository {
  static const _asset = 'assets/reading_frequency.json';

  Map<String, Map<String, int>> _byChar = {};

  Future<void> load() async {
    final raw =
        jsonDecode(await rootBundle.loadString(_asset)) as Map<String, dynamic>;
    _byChar = raw.map(
      (char, v) => MapEntry(
        char,
        {
          for (final entry in v as List)
            (entry as Map<String, dynamic>)['reading'] as String:
                entry['count'] as int,
        },
      ),
    );
  }

  /// Returns the composita word count for a specific reading of a kanji,
  /// or null if no frequency data exists for that kanji/reading pair.
  int? count(String kanji, String reading) => _byChar[kanji]?[reading];

  /// Whether a reading is "rare" — appears in 2 or fewer composita words.
  bool isRare(String kanji, String reading) {
    final c = count(kanji, reading);
    return c != null && c <= 2;
  }
}
