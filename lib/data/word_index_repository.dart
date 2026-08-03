import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// One JMdict dictionary entry -- see kanjirec/scripts/build_word_index.py
/// for how this is generated. Unlike [Composita] (per-kanji, capped,
/// Joyo-only), this covers the full JMdict_e dictionary, including
/// kana-only words.
class WordEntry {
  final List<String> kanji; // may be empty for a kana-only word
  final List<String> kana;
  final String meaning;

  const WordEntry({
    required this.kanji,
    required this.kana,
    required this.meaning,
  });

  factory WordEntry.fromJson(Map<String, dynamic> json) {
    return WordEntry(
      kanji: (json['kanji'] as List).cast<String>(),
      kana: (json['kana'] as List).cast<String>(),
      meaning: json['meaning'] as String,
    );
  }
}

/// Loads assets/word_index.json once and serves exact-word JMdict lookups.
/// Entries are stored once and referenced by index from every kanji
/// spelling and kana reading that points to them (see the build script),
/// so this expands that back out into a simple word -> entries map at load
/// time -- a one-time cost, not paid per lookup.
class WordIndexRepository {
  static const _asset = 'assets/word_index.json';

  Map<String, List<WordEntry>> _byWord = {};

  Future<void> load() async {
    final raw =
        jsonDecode(await rootBundle.loadString(_asset)) as Map<String, dynamic>;
    final entries = (raw['entries'] as List)
        .map((e) => WordEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    final index = raw['index'] as Map<String, dynamic>;
    _byWord = index.map(
      (word, indices) => MapEntry(
        word,
        (indices as List).map((i) => entries[i as int]).toList(),
      ),
    );
  }

  /// Exact match only -- looks up [word] as written (kanji, kana, or a mix),
  /// same as any k_ele/r_ele in JMdict. Empty if the word isn't in JMdict.
  List<WordEntry> lookup(String word) => _byWord[word] ?? const [];
}
