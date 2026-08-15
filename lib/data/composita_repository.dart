import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// One compound word (jukugo) containing a given kanji -- see
/// kanjirec/scripts/build_composita.py (JMdict_e cross-referenced against a
/// word-level JLPT list) for how this is generated.
class Composita {
  final String word;
  final String reading;
  final String meaning;
  final int? jlptLevel; // 1=N1 hardest .. 5=N5 easiest; null if not JLPT-tagged
  // Set only when [jlptLevel] is null: the hardest level among the word's
  // own constituent kanji, as a heuristic estimate -- word-level JLPT lists
  // only ever cover ~20% of composita (there's no official post-2010
  // N1-N3 vocabulary list), so this fills most of the rest at the cost of
  // being an estimate rather than a real tag. Never trust this over
  // [jlptLevel] when both happen to be present -- they can't be, by
  // construction (see the build script), but keep them semantically
  // distinct rather than merging into one field.
  final int? inferredJlptLevel;
  final int frequencyRank; // 1=most frequent .. 4=untagged/rare
  /// Pre-computed per-character reading split (parallel to word's characters).
  /// Null when the build script couldn't split this word.
  final List<String>? splits;

  const Composita({
    required this.word,
    required this.reading,
    required this.meaning,
    required this.jlptLevel,
    required this.inferredJlptLevel,
    required this.frequencyRank,
    this.splits,
  });

  /// The real tag if there is one, else the heuristic estimate, else null.
  /// Use [isLevelInferred] to tell which one this is when displaying it.
  int? get effectiveJlptLevel => jlptLevel ?? inferredJlptLevel;

  bool get isLevelInferred => jlptLevel == null && inferredJlptLevel != null;

  factory Composita.fromJson(Map<String, dynamic> json) {
    return Composita(
      word: json['word'] as String,
      reading: json['reading'] as String,
      meaning: json['meaning'] as String,
      jlptLevel: json['jlptLevel'] as int?,
      inferredJlptLevel: json['inferredJlptLevel'] as int?,
      frequencyRank: json['frequencyRank'] as int,
      splits: (json['splits'] as List?)?.cast<String>(),
    );
  }
}

/// Loads assets/composita.json once and serves ranked compound-word lookups
/// by character (already sorted by JLPT-tagged-first, then frequency, and
/// capped at ~20/character -- see the build script).
class CompositaRepository {
  static const _asset = 'assets/composita.json';

  Map<String, List<Composita>> _byChar = {};

  Future<void> load() async {
    final raw =
        jsonDecode(await rootBundle.loadString(_asset)) as Map<String, dynamic>;
    _byChar = raw.map(
      (char, list) => MapEntry(
        char,
        (list as List)
            .map((e) => Composita.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
  }

  /// Empty for kana, REJECT, or any character with no JMdict coverage.
  List<Composita> lookup(String char) => _byChar[char] ?? const [];
}

/// Re-ranks [all] for human-facing display (the review engine's own
/// JLPT-ceiling filtering consumes the full, level-balanced list directly
/// instead -- see sentence_selection.dart's compositaWithinCeiling):
/// excludes JMdict's own "untagged/rare" bucket entirely (frequencyRank ==
/// 4, not just deprioritized -- a common kanji's composita list can run
/// well over 100 entries once bundled per JLPT level, many of them obscure
/// e.g. 根本 read ねほん meaning "kabuki script", technically JLPT-tagged
/// via kanji-level inference but not a word most learners want to see
/// first), then sorts by frequency, then JLPT level as a tiebreaker
/// (easier first).
List<Composita> rankComposita(List<Composita> all) {
  final common = all.where((c) => c.frequencyRank < 4).toList()
    ..sort((a, b) {
      final freq = a.frequencyRank.compareTo(b.frequencyRank);
      if (freq != 0) return freq;
      final aLevel = a.effectiveJlptLevel ?? 0;
      final bLevel = b.effectiveJlptLevel ?? 0;
      return bLevel.compareTo(aLevel); // easier (higher N) first
    });
  return common;
}
