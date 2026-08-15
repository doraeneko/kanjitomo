import 'dart:math';

import 'package:flutter/material.dart';

import '../../app_dependencies.dart';
import '../../data/composita_repository.dart';
import '../../data/sentences_repository.dart';
import '../../l10n/app_localizations.dart';
import '../review/furigana_sentence.dart';
import '../review/reading_splitter.dart';
import '../review/review_repository.dart';
import '../review/sentence_selection.dart';
import '../review/study_scope.dart';
import 'quiz_distractors.dart';
import '../../widgets/tts_button.dart';

final _rng = Random();

/// The two question types, randomly mixed within a quiz.
enum QuizQuestionType {
  /// Show kanji, ask for reading.
  kanjiToReading,

  /// Show reading in place of kanji, ask which kanji word fits.
  readingToKanji,
}

class _QuizQuestion {
  final Composita composita;
  final ExampleSentence sentence;
  final QuizQuestionType type;
  final List<String> choices; // 4 choices, one correct
  final int correctIndex;

  /// For kanjiToReading: which specific character within the word is tested.
  final String? targetChar;

  /// For kanjiToReading: the correct reading of [targetChar] only.
  final String? targetReading;

  const _QuizQuestion({
    required this.composita,
    required this.sentence,
    required this.type,
    required this.choices,
    required this.correctIndex,
    this.targetChar,
    this.targetReading,
  });
}

/// Presents multiple-choice quiz questions one at a time. No SRS effect —
/// purely a standalone self-test that shows a score at the end.
class QuizSessionScreen extends StatefulWidget {
  final AppDependencies deps;
  final int questionCount;

  const QuizSessionScreen({
    super.key,
    required this.deps,
    required this.questionCount,
  });

  @override
  State<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends State<QuizSessionScreen> {
  List<_QuizQuestion>? _questions; // null while loading
  int _currentIndex = 0;
  int _correctCount = 0;
  int? _selectedChoice; // null = not answered yet
  bool _showingResults = false;
  Set<String> _seenCharacters = {};

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    TtsButton.stop();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    final repo = ReviewRepository(widget.deps.database);
    final scope = widget.deps.studyScope.scope.value;
    final scopeChars = scope.characters;
    // In the quiz, don't show furigana hints for unknown kanji —
    // treat all kanji in the info repository as "seen" so no readings
    // are revealed as hints.
    final allKanji = widget.deps.kanjiInfo.characters.toSet();
    final questions = await _buildQuestions(allKanji);
    if (mounted) {
      setState(() {
        _seenCharacters = allKanji;
        _questions = questions;
      });
    }
  }

  Future<List<_QuizQuestion>> _buildQuestions(Set<String> _) async {
    final scope = widget.deps.studyScope.scope.value;
    final repo = ReviewRepository(widget.deps.database);

    var scopeChars = scope.characters;

    // Only quiz characters the user has already seen (reviewed at least once).
    final seenChars = await repo.seenCharacters(scopeChars);
    scopeChars = scopeChars.intersection(seenChars);

    final customComposita = await repo.customCompositaForCharacters(scopeChars);
    final userComposita = await repo.allUserCompositaByChar();

    // Gather all eligible composita across scope.
    final pool = <Composita>[];
    for (final char in scopeChars) {
      final bundled = widget.deps.composita.lookup(char);
      final userAdded = userComposita[char];
      final merged = _mergeComposita(bundled, userAdded);
      final eligible = eligibleComposita(
        merged,
        scope,
        customComposita[char] ?? const {},
        charJlptLevel: widget.deps.jlptLevels.levelOf(char),
      );
      pool.addAll(eligible);
    }

    // Deduplicate by word (same word can appear under multiple characters).
    final seen = <String>{};
    final unique = <Composita>[];
    for (final c in pool) {
      if (seen.add(c.word)) unique.add(c);
    }

    // Prefer composita that have sentence coverage.
    final withSentence = <Composita>[];
    final withoutSentence = <Composita>[];
    for (final c in unique) {
      final sents = widget.deps.sentences.lookup(c.word);
      final hasMatch = sents.any((s) {
        final target = s.tokens.where((t) => t.isTarget).firstOrNull;
        return target == null || target.reading == c.reading;
      });
      if (hasMatch) {
        withSentence.add(c);
      } else {
        withoutSentence.add(c);
      }
    }
    withSentence.shuffle(_rng);
    withoutSentence.shuffle(_rng);
    final selected = [
      ...withSentence.take(widget.questionCount),
      if (withSentence.length < widget.questionCount)
        ...withoutSentence.take(widget.questionCount - withSentence.length),
    ];

    return selected.map((composita) {
      // Pick a sentence whose target token reading matches the composita.
      // Some sentences contain the same surface form with a different
      // reading (e.g. 入る as はいる vs いる in 気に入る).
      final realSentences = widget.deps.sentences.lookup(composita.word);
      final matching = realSentences.where((s) {
        final target = s.tokens.where((t) => t.isTarget).firstOrNull;
        return target == null || target.reading == composita.reading;
      }).toList();
      // Don't fall back to mismatched sentences — use synthetic instead.
      final sentence = matching.isNotEmpty
          ? matching[_rng.nextInt(matching.length)]
          : syntheticSentenceFor(composita);

      // Randomly assign question type.
      final type = _rng.nextBool()
          ? QuizQuestionType.kanjiToReading
          : QuizQuestionType.readingToKanji;

      // Generate distractors and build choices.
      List<String> choices;
      int correctIndex;
      String? targetChar;
      String? targetReading;
      if (type == QuizQuestionType.kanjiToReading) {
        // Pick a specific kanji character from the word to test its reading.
        final kanjiLookup = widget.deps.kanjiInfo.lookup;
        final chars = composita.word.split('');
        final splits = composita.splits ??
            splitReading(composita.word, composita.reading, kanjiLookup);

        // Find kanji characters (not kana) that the user has already seen.
        final kanjiIndices = <int>[];
        for (var i = 0; i < chars.length; i++) {
          final c = chars[i].codeUnitAt(0);
          if ((c >= 0x4E00 && c <= 0x9FFF || c >= 0x3400 && c <= 0x4DBF) &&
              seenChars.contains(chars[i])) {
            kanjiIndices.add(i);
          }
        }

        if (kanjiIndices.isNotEmpty && splits != null && splits.length == chars.length) {
          final idx = kanjiIndices[_rng.nextInt(kanjiIndices.length)];
          targetChar = chars[idx];
          targetReading = splits[idx];
          final distractors = charReadingDistractors(
            targetReading!, targetChar!, kanjiLookup, unique,
            wordSplits: splits,
            targetIndex: idx,
          );
          // Choices are full-word readings with only the tested part varied.
          // Remove any distractor that accidentally matches the correct answer.
          final correctFull = splits.join();
          final uniqueDistractors = distractors
              .where((d) => d != correctFull)
              .toSet()
              .toList();
          choices = [correctFull, ...uniqueDistractors];
          choices.shuffle(_rng);
          correctIndex = choices.indexOf(correctFull);
        } else {
          // Fallback: use full word reading if split fails.
          final distractors = readingDistractors(composita.reading, unique);
          choices = [composita.reading, ...distractors];
          choices.shuffle(_rng);
          correctIndex = choices.indexOf(composita.reading);
        }
      } else {
        final distractors = kanjiWordDistractors(
          composita.word,
          unique,
          kanjiLookup: widget.deps.kanjiInfo.lookup,
          scopeCharacters: scopeChars,
          scopeJlptLevel: scope.compositaCeiling,
          jlptLevelOf: widget.deps.jlptLevels.levelOf,
        );
        choices = [composita.word, ...distractors];
        choices.shuffle(_rng);
        correctIndex = choices.indexOf(composita.word);
      }

      return _QuizQuestion(
        composita: composita,
        sentence: sentence,
        type: type,
        choices: choices,
        correctIndex: correctIndex,
        targetChar: targetChar,
        targetReading: targetReading,
      );
    }).toList();
  }

  static List<Composita> _mergeComposita(
    List<Composita> bundled,
    List<Composita>? userAdded,
  ) {
    if (userAdded == null || userAdded.isEmpty) return bundled;
    final seen = bundled.map((c) => c.word).toSet();
    final merged = [...bundled];
    for (final c in userAdded) {
      if (seen.add(c.word)) merged.add(c);
    }
    return merged;
  }

  void _onChoiceSelected(int index) {
    if (_selectedChoice != null) return; // already answered
    setState(() {
      _selectedChoice = index;
      if (index == _questions![_currentIndex].correctIndex) {
        _correctCount++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex + 1 >= _questions!.length) {
      setState(() => _showingResults = true);
      return;
    }
    setState(() {
      _currentIndex++;
      _selectedChoice = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (_questions == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.quizStartTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_showingResults) return _buildResults(l);

    final q = _questions![_currentIndex];
    final answered = _selectedChoice != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.quizProgress(_currentIndex + 1, _questions!.length)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bar.
              LinearProgressIndicator(
                value: (_currentIndex + 1) / _questions!.length,
              ),
              const SizedBox(height: 16),

              // Prompt.
              Text(
                q.type == QuizQuestionType.kanjiToReading
                    ? l.quizPickReading
                    : l.quizPickKanji,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              // Sentence display.
              _buildSentence(q),
              const SizedBox(height: 24),

              // Feedback.
              if (answered) ...[
                _selectedChoice == q.correctIndex
                    ? Text(
                        l.quizCorrect,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.quizWrong,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            q.choices[q.correctIndex],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 8),
                // Show composita info after answering.
                Text(
                  '${q.composita.word} (${q.composita.reading}): ${q.composita.meaning}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Answer buttons.
              ...List.generate(q.choices.length, (i) {
                Color? bgColor;
                if (answered) {
                  if (i == q.correctIndex) {
                    bgColor = Colors.green.shade100;
                  } else if (i == _selectedChoice) {
                    bgColor = Colors.red.shade100;
                  }
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: answered ? null : () => _onChoiceSelected(i),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: bgColor,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        alignment: Alignment.centerLeft,
                      ),
                      child: Text(
                        q.choices[i],
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                );
              }),

              if (answered) ...[
                const SizedBox(height: 8),
                Center(
                  child: ElevatedButton(
                    onPressed: _nextQuestion,
                    child: Text(l.quizNext),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Replaces the target token with per-character sub-tokens so unseen kanji
  /// show their readings as hints (pre-answer only). Returns the original
  /// list if splitting fails or there are no unseen kanji.
  List<SentenceToken> _splitTargetTokens(
    List<SentenceToken> tokens, {
    List<String>? precomputedSplits,
  }) {
    final targetIdx = tokens.indexWhere((t) => t.isTarget);
    if (targetIdx < 0) return tokens;
    final target = tokens[targetIdx];
    final lookup = widget.deps.kanjiInfo.lookup;

    final split = splitTargetToken(
      target, lookup, _seenCharacters,
      precomputedSplits: precomputedSplits,
    );
    if (split == null) return tokens;

    final hasUnseen = split.any((t) => !t.isTarget);
    if (!hasUnseen) return tokens;

    return [
      ...tokens.sublist(0, targetIdx),
      ...split,
      ...tokens.sublist(targetIdx + 1),
    ];
  }

  /// Splits the target token into per-character sub-tokens for a
  /// per-character reading quiz. Only the [quizChar] gets isTarget=true
  /// (its reading will be hidden by hideTargetReading), while other
  /// characters in the same word get isTarget=false (readings shown as
  /// hints). Non-target tokens pass through unchanged.
  List<SentenceToken> _splitForQuizChar(
    List<SentenceToken> tokens,
    String quizChar,
    List<String>? precomputedSplits,
  ) {
    final targetIdx = tokens.indexWhere((t) => t.isTarget);
    if (targetIdx < 0) return tokens;
    final target = tokens[targetIdx];

    final lookup = widget.deps.kanjiInfo.lookup;
    List<String>? segments;
    if (precomputedSplits != null &&
        precomputedSplits.length == target.surface.length &&
        precomputedSplits.join() == target.reading) {
      segments = precomputedSplits;
    }
    segments ??= splitReading(target.surface, target.reading, lookup);
    if (segments == null) return tokens;

    final chars = target.surface.split('');
    if (chars.length != segments.length) return tokens;

    final split = List.generate(chars.length, (i) {
      return SentenceToken(
        surface: chars[i],
        reading: segments![i],
        // Only the tested character is "target" — its reading gets hidden.
        isTarget: chars[i] == quizChar,
      );
    });

    return [
      ...tokens.sublist(0, targetIdx),
      ...split,
      ...tokens.sublist(targetIdx + 1),
    ];
  }

  Widget _buildSentence(_QuizQuestion q) {
    final answered = _selectedChoice != null;
    if (q.type == QuizQuestionType.kanjiToReading) {
      // Show the whole target word with a highlight box. The reading is
      // hidden until answered — the user picks the full-word reading from
      // the choices below.
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: FuriganaSentence(
              tokens: q.sentence.tokens,
              hideTargetReading: !answered,
              emphasizeTargetReading: answered,
              highlightTargetBox: true,
              kanjiLookup: widget.deps.kanjiInfo.lookup,
            ),
          ),
          const SizedBox(width: 8),
          // Hide TTS until answered — it gives away the pronunciation.
          if (answered)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TtsButton(text: q.sentence.sentence),
            ),
        ],
      );
    } else {
      // Reading → Kanji: replace target word's surface with its reading.
      final tokens = q.sentence.tokens.map((t) {
        if (t.isTarget) {
          return SentenceToken(
            surface: t.reading,
            reading: '',
            isTarget: true,
          );
        }
        return t;
      }).toList();
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: FuriganaSentence(
              tokens: tokens,
              highlightTargetBox: true,
              kanjiLookup: widget.deps.kanjiInfo.lookup,
            ),
          ),
          const SizedBox(width: 8),
          if (answered)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TtsButton(text: q.sentence.sentence),
            ),
        ],
      );
    }
  }

  Widget _buildResults(AppLocalizations l) {
    return Scaffold(
      appBar: AppBar(title: Text(l.quizResultTitle)),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l.quizResultScore(_correctCount, _questions!.length),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.quizDone),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
