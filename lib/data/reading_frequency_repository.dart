import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Per-kanji reading frequency data derived from composita word splits.
/// Maps each kanji to {reading (hiragana): frequency data}.
/// Used to dim/italicize obscure readings that appear in only rare words.
class ReadingFrequencyRepository {
  static const _asset = 'assets/reading_frequency.json';

  Map<String, Map<String, ({int count, int weighted})>> _byChar = {};
  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final raw =
        jsonDecode(await rootBundle.loadString(_asset)) as Map<String, dynamic>;
    _byChar = raw.map(
      (char, v) => MapEntry(
        char,
        {
          for (final entry in v as List)
            (entry as Map<String, dynamic>)['reading'] as String: (
              count: entry['count'] as int,
              weighted: entry['weighted'] as int,
            ),
        },
      ),
    );
    _loaded = true;
  }

  /// Returns the composita word count for a specific reading of a kanji,
  /// or null if no frequency data exists for that kanji/reading pair.
  int? count(String kanji, String reading) => _byChar[kanji]?[reading]?.count;

  /// Returns the weighted frequency score for a specific reading of a kanji,
  /// or null if no frequency data exists for that kanji/reading pair.
  int? weighted(String kanji, String reading) =>
      _byChar[kanji]?[reading]?.weighted;

  /// Whether a reading is "rare" — only appears in very low-frequency words.
  /// Uses weighted score (which factors in word frequency rank) rather than
  /// raw word count to avoid greying out readings used by common words.
  bool isRare(String kanji, String reading) {
    final w = weighted(kanji, reading);
    return w != null && w <= 45;
  }
}
