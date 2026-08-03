import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// One word (or particle/punctuation) in a tokenized example sentence, with
/// its hiragana reading -- see kanjirec/scripts/build_sentences.py, which
/// derives every token's reading via the same morphological-analyzer pass
/// regardless of whether the sentence came from Tatoeba or (later) an LLM.
class SentenceToken {
  final String surface;
  final String reading; // hiragana; empty for punctuation/tokens with no reading
  final bool isTarget; // whether this token is the word the card is testing

  const SentenceToken({
    required this.surface,
    required this.reading,
    required this.isTarget,
  });

  factory SentenceToken.fromJson(Map<String, dynamic> json) {
    return SentenceToken(
      surface: json['surface'] as String,
      reading: json['reading'] as String,
      isTarget: json['isTarget'] as bool,
    );
  }
}

class ExampleSentence {
  final String sentence;
  final List<SentenceToken> tokens;
  final int jlptLevel; // 1=N1 hardest .. 5=N5 easiest
  final String source; // "tatoeba" | "llm"
  final String? translation; // null if no linked/generated translation exists

  const ExampleSentence({
    required this.sentence,
    required this.tokens,
    required this.jlptLevel,
    required this.source,
    this.translation,
  });

  factory ExampleSentence.fromJson(Map<String, dynamic> json) {
    return ExampleSentence(
      sentence: json['sentence'] as String,
      tokens: (json['tokens'] as List)
          .map((t) => SentenceToken.fromJson(t as Map<String, dynamic>))
          .toList(),
      jlptLevel: json['jlptLevel'] as int,
      source: json['source'] as String,
      translation: json['translation'] as String?,
    );
  }
}

/// Loads assets/sentences.json once and serves ranked example-sentence
/// lookups by (compound) word -- already capped at ~5/word and ordered
/// curated-first, shortest-first by the build script.
class SentencesRepository {
  static const _asset = 'assets/sentences.json';

  Map<String, List<ExampleSentence>> _byWord = {};

  Future<void> load() async {
    final raw =
        jsonDecode(await rootBundle.loadString(_asset)) as Map<String, dynamic>;
    _byWord = raw.map(
      (word, list) => MapEntry(
        word,
        (list as List)
            .map((e) => ExampleSentence.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
  }

  /// Empty if this word has no level-appropriate sentence coverage (not
  /// every JLPT-tagged word has one, even after mining -- see the build
  /// script's coverage warnings).
  List<ExampleSentence> lookup(String word) => _byWord[word] ?? const [];
}
