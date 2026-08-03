import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Readings/meaning/component data for a single kanji -- see
/// scripts/build_kanji_info.py (KANJIDIC2 + kradfile-u) for how this is
/// generated. Kana have no entry (see [KanjiInfoRepository.lookup]): they
/// don't have on'yomi/kun'yomi/meanings/component decomposition in the same
/// sense a kanji does.
class KanjiInfo {
  final List<String> on; // on'yomi, katakana
  final List<String>
  kun; // kun'yomi, hiragana (may include okurigana after ".")
  final List<String> meanings; // English
  final List<String> radicals; // visual component characters

  const KanjiInfo({
    required this.on,
    required this.kun,
    required this.meanings,
    required this.radicals,
  });

  factory KanjiInfo.fromJson(Map<String, dynamic> json) {
    return KanjiInfo(
      on: List<String>.from(json['on'] as List),
      kun: List<String>.from(json['kun'] as List),
      meanings: List<String>.from(json['meanings'] as List),
      radicals: List<String>.from(json['radicals'] as List),
    );
  }
}

/// Loads assets/kanji_info.json once and serves lookups by character.
class KanjiInfoRepository {
  static const _asset = 'assets/kanji_info.json';

  Map<String, KanjiInfo> _byChar = {};

  Future<void> load() async {
    final raw =
        jsonDecode(await rootBundle.loadString(_asset)) as Map<String, dynamic>;
    _byChar = raw.map(
      (char, v) =>
          MapEntry(char, KanjiInfo.fromJson(v as Map<String, dynamic>)),
    );
  }

  /// Null for kana, REJECT, or any character absent from the dictionary.
  KanjiInfo? lookup(String char) => _byChar[char];

  /// All Joyo kanji covered by this dictionary -- the browsable universe
  /// for the kanji browser grid.
  List<String> get characters => _byChar.keys.toList();
}
