import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// A seeded keyword+story pair, split apart at build time (see
/// kanjirec/scripts/build_stories.py) so kanjitomo can show just the short
/// keyword as a pre-draw recall hint while keeping the fuller story for
/// after the answer is revealed.
class StorySeed {
  final String keyword;
  final String story;

  const StorySeed({required this.keyword, required this.story});
}

/// Loads assets/stories.json (char -> the user's own pre-written personal
/// keyword+mnemonic, see kanjirec/scripts/build_stories.py) -- the initial
/// seed for kanji_notes on first run (see AppDatabase.seedStories()), not a
/// live source read at display time. Once seeded, kanji_notes is the single
/// source of truth: it starts out equal to this bundle but is freely
/// user-editable from then on, so nothing else needs to merge two sources.
class StoriesRepository {
  static const _asset = 'assets/stories.json';

  Map<String, StorySeed> _byChar = {};

  Future<void> load() async {
    final raw =
        jsonDecode(await rootBundle.loadString(_asset)) as Map<String, dynamic>;
    _byChar = raw.map((char, value) {
      final map = value as Map<String, dynamic>;
      return MapEntry(
        char,
        StorySeed(
          keyword: map['keyword'] as String,
          story: map['story'] as String,
        ),
      );
    });
  }

  /// Full char -> {keyword, story} map, for seeding AppDatabase.kanjiNotes.
  Map<String, StorySeed> get all => _byChar;
}
