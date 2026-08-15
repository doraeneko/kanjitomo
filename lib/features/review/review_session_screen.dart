import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_dependencies.dart';
import '../../core/db/app_database.dart';
import '../../core/db/tables.dart';
import '../../core/kanji_recognizer.dart';
import '../../data/composita_repository.dart';
import '../../data/sentences_repository.dart';
import '../../l10n/app_localizations.dart';
import '../kanji_browser/kanji_detail_content.dart';
import 'draw_and_pick.dart';
import 'furigana_sentence.dart';
import 'review_repository.dart';
import 'reading_splitter.dart';
import 'sentence_selection.dart';
import 'sm2.dart';
import 'study_scope.dart';
import '../../widgets/tts_button.dart';

/// A composita word paired with one of its example sentences -- just
/// enough context to render a sentence-based card without needing to
/// re-derive which word within the sentence's tokens is the target
/// (already flagged via SentenceToken.isTarget). Keeping the full
/// [Composita] (not just its word) also lets the feedback/reveal UI show
/// its meaning, and lets grading record exactly which word was tested.
class _ExampleSentenceRef {
  final Composita composita;
  final ExampleSentence sentence;

  const _ExampleSentenceRef({required this.composita, required this.sentence});
}

/// Result of a draw-and-pick card, shown before advancing so a miss always
/// reveals the correct answer -- auto-grading silently advancing on a wrong
/// guess would defeat the point of testing yourself.
class _DrawFeedback {
  final bool correct;
  final String target;
  final String? userPick; // null when "Don't know" was tapped instead of a pick
  final ExampleSentence? sentence; // drawInSentence only, for the translation
  final Composita? composita; // the word that sentence was testing, if any

  const _DrawFeedback({
    required this.correct,
    required this.target,
    required this.userPick,
    this.sentence,
    this.composita,
  });
}

/// Pre-grade snapshot so a single undo can restore the previous card's
/// state exactly as it was before the user graded it.
class _GradeSnapshot {
  final ReviewCard queueCard;
  final CardStateSnapshot dbSnapshot;
  final bool wasRequeued;
  final _ExampleSentenceRef? sentence;

  const _GradeSnapshot({
    required this.queueCard,
    required this.dbSnapshot,
    required this.wasRequeued,
    this.sentence,
  });
}

/// Presents due (and newly-introduced) review cards one at a time across
/// all three card types, grading each via SM-2. Card-type-specific UI is
/// built inline per card rather than as separate screens/routes, since
/// they share the same session flow (grade -> advance) and queue.
class ReviewSessionScreen extends StatefulWidget {
  final AppDependencies deps;

  const ReviewSessionScreen({
    super.key,
    required this.deps,
  });

  @override
  State<ReviewSessionScreen> createState() => _ReviewSessionScreenState();
}

/// SharedPreferences key for the max new cards per session setting.
const _newCardsPerSessionKey = 'review.new_cards_per_session';
const _maxReviewsPerDayKey = 'review.max_reviews_per_day';
const _learnMoreExtraKey = 'review.learn_more_extra';
const _learnMoreDateKey = 'review.learn_more_date';

class _ReviewSessionScreenState extends State<ReviewSessionScreen> {
  late final ReviewRepository _reviewRepo;
  bool _loading = true;
  List<ReviewCard> _queue = [];
  int _index = 0;
  int _cardsDone = 0;
  bool _revealed = false;
  bool _translationRevealed = false;
  bool _showFeedbackDetails = false;
  _ExampleSentenceRef? _currentSentence;
  _DrawFeedback? _feedback;
  // Key for the FuriganaSentence in readingCloze, used to auto-scroll
  // the highlighted target word into view after layout.
  final _readingClozeTargetKey = GlobalKey();
  String? _currentStoryKeyword;
  String? _currentStory;
  Map<String, Set<String>> _testedWords = {};
  Map<String, Set<String>> _customComposita = {};
  Map<String, List<Composita>> _userComposita = {};
  Set<String> _seenCharacters = {};
  _GradeSnapshot? _lastGradeSnapshot;
  int _remainingBeyondCap = 0;
  Timer? _dueRefreshTimer;

  @override
  void initState() {
    super.initState();
    _reviewRepo = ReviewRepository(widget.deps.database);
    _loadQueue();
  }

  @override
  void dispose() {
    _dueRefreshTimer?.cancel();
    TtsButton.stop();
    super.dispose();
  }

  Future<void> _loadQueue() async {
    final scope = widget.deps.studyScope.scope.value;
    _customComposita = await _reviewRepo.customCompositaForCharacters(scope.characters);
    _userComposita = await _reviewRepo.allUserCompositaByChar();

    // Two sources merged into one queue:
    // 1. Previously-reviewed cards that are due again.
    // 2. Never-reviewed cards (introduced when kanji were added to pool).
    final reviews = await _reviewRepo.dueCards(
      scope,
      excludeNeverReviewed: true,
    );
    final neverReviewed = await _reviewRepo.cardsNeverReviewed(scope);
    // Sort never-reviewed cards so basic kanji cards (draw from meaning,
    // recognition) come before composita cards (reading cloze, draw in
    // sentence). This way you learn the kanji before being tested on its
    // compound words.
    const _cardTypeOrder = {
      CardType.drawFromMeaning: 0,
      CardType.kanjiRecognition: 1,
      CardType.readingCloze: 2,
      CardType.drawInSentence: 3,
    };
    neverReviewed.sort((a, b) =>
        (_cardTypeOrder[a.cardType] ?? 9)
            .compareTo(_cardTypeOrder[b.cardType] ?? 9));
    // Apply max reviews/day cap across sessions: subtract cards already
    // reviewed today so restarting a session doesn't reset the limit.
    final prefs = await SharedPreferences.getInstance();
    final maxReviewsPerDay = prefs.getInt(_maxReviewsPerDayKey) ?? 200;
    final reviewedToday = await _reviewRepo.countReviewedToday();
    final dailyBudget = maxReviewsPerDay <= 0
        ? reviews.length + neverReviewed.length
        : (maxReviewsPerDay - reviewedToday).clamp(0, maxReviewsPerDay);
    final cappedReviews = dailyBudget <= 0
        ? <ReviewCard>[]
        : reviews.take(dailyBudget).toList();
    final remainingBudget = maxReviewsPerDay <= 0
        ? neverReviewed.length
        : (dailyBudget - cappedReviews.length).clamp(0, dailyBudget);
    final maxNewCardsPerDay = prefs.getInt(_newCardsPerSessionKey) ?? 30;
    final newCardCap = maxNewCardsPerDay <= 0
        ? remainingBudget
        : remainingBudget.clamp(0, maxNewCardsPerDay);
    final cappedNew = neverReviewed.take(newCardCap).toList();
    // "Learn more" persistence: _learnMoreExtraKey stores a high-water
    // mark — the total number of reviews the user has committed to today
    // (including learn-more clicks). Subtracting reviewedToday gives the
    // outstanding commitment that should survive leaving mid-session.
    final todayStr = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    final learnMoreDate = prefs.getString(_learnMoreDateKey);
    final learnMoreHighWater = (learnMoreDate == todayStr)
        ? (prefs.getInt(_learnMoreExtraKey) ?? 0)
        : 0;
    final learnMoreRemaining = learnMoreHighWater > 0
        ? (learnMoreHighWater - reviewedToday).clamp(0, learnMoreHighWater)
        : 0;
    // Take extra cards from the combined pool (reviews first, then new),
    // skipping what the caps already loaded.
    final alreadyLoaded = <String>{};
    for (final c in cappedReviews) {
      alreadyLoaded.add('${c.character}|${c.cardType.index}|${c.compositaWord}');
    }
    for (final c in cappedNew) {
      alreadyLoaded.add('${c.character}|${c.cardType.index}|${c.compositaWord}');
    }
    final extraPool = [...reviews, ...neverReviewed]
        .where((c) => !alreadyLoaded.contains('${c.character}|${c.cardType.index}|${c.compositaWord}'))
        .toList();
    final extraCards = learnMoreRemaining > 0
        ? extraPool.take(learnMoreRemaining).toList()
        : <ReviewCard>[];
    // ignore: avoid_print
    print('[_loadQueue] cappedReviews=${cappedReviews.length} cappedNew=${cappedNew.length} '
        'extraCards=${extraCards.length} learnMoreRemaining=$learnMoreRemaining '
        'highWater=$learnMoreHighWater reviewedToday=$reviewedToday');
    final totalAvailable = reviews.length + neverReviewed.length;
    final totalLoaded = cappedReviews.length + cappedNew.length + extraCards.length;
    final due = interleaveByCharacter([...cappedReviews, ...cappedNew, ...extraCards]);

    final testedWords = await _reviewRepo.testedCompositaWordsFor(
      due.map((c) => c.character).toSet(),
      CompositaDirection.reading,
    );
    // Kanji in the learning pool count as "seen" for furigana hints.
    // Kanji NOT in the pool get furigana shown so the user isn't blocked
    // by unknown readings in composita/sentence cards.
    if (!mounted) return;
    setState(() {
      _queue = due;
      _index = 0;
      _loading = false;
      _lastGradeSnapshot = null;
      _remainingBeyondCap = totalAvailable - totalLoaded;
      _testedWords = testedWords;
      _seenCharacters = scope.characters;
      _prepareCurrentCard();
    });
    _loadStoryForCurrentCard();
  }

  /// [char]'s composita actually eligible for C+D testing under [scope]
  /// (see sentence_selection.dart's eligibleComposita) -- _customComposita
  /// and _userComposita are batch-loaded up front in _loadQueue so this
  /// stays a synchronous, no-DB-round-trip helper.
  List<Composita> _eligibleCompositaFor(String char, StudyScope scope) {
    final bundled = widget.deps.composita.lookup(char);
    final merged = mergeComposita(bundled, _userComposita[char]);
    return eligibleComposita(
      merged,
      scope,
      _customComposita[char] ?? const {},
      charJlptLevel: widget.deps.jlptLevels.levelOf(char),
    );
  }


  /// Re-appends [card] to the end of the queue so the user sees it again.
  /// Failed cards repeat until passed (quality >= 3).
  void _requeueFailed(ReviewCard card) {
    _queue.add(card);
  }

  ReviewCard? get _currentCard =>
      _index < _queue.length ? _queue[_index] : null;

  void _prepareCurrentCard() {
    _revealed = false;
    _translationRevealed = false;
    _showFeedbackDetails = false;
    _feedback = null;
    _currentStoryKeyword = null; // stale until _loadStoryForCurrentCard() resolves
    _currentStory = null;
    final card = _currentCard;
    _currentSentence =
        (card != null &&
            card.compositaWord.isNotEmpty &&
            (card.cardType == CardType.readingCloze ||
                card.cardType == CardType.drawInSentence))
        ? _sentenceForWord(card.character, card.compositaWord, card.repetitions)
        : null;
  }

  /// kanji_notes is DB-backed (unlike the preloaded JSON repositories), so
  /// the current card's story keyword is fetched asynchronously here rather
  /// than synchronously in _prepareCurrentCard(). The character guard
  /// protects against a race where the user advances to a different card
  /// before this resolves.
  Future<void> _loadStoryForCurrentCard() async {
    final card = _currentCard;
    if (card == null) return;
    final character = card.character;
    final keyword = await _reviewRepo.getStoryKeyword(character);
    final story = await _reviewRepo.getNote(character);
    if (!mounted || _currentCard?.character != character) return;
    setState(() {
      _currentStoryKeyword = keyword;
      _currentStory = story;
    });
  }

  /// Builds the sentence reference for a specific composita word (read from
  /// the card itself, not picked dynamically). Rotates through available
  /// real sentences based on [repetitions] so the user sees a different
  /// sentence after each successful review, falling back to a synthetic
  /// single-word pseudo-sentence when none exists.
  _ExampleSentenceRef? _sentenceForWord(
    String character,
    String compositaWord,
    int repetitions,
  ) {
    final scope = widget.deps.studyScope.scope.value;
    final eligible = _eligibleCompositaFor(character, scope);
    var composita = eligible.cast<Composita?>().firstWhere(
      (c) => c!.word == compositaWord,
      orElse: () => null,
    );
    // Fall back to the full (unfiltered) composita data when the word isn't
    // in the eligible list (e.g. ceiling changed after the card was created).
    if (composita == null) {
      final bundled = widget.deps.composita.lookup(character);
      final merged = mergeComposita(bundled, _userComposita[character]);
      composita = merged.cast<Composita?>().firstWhere(
        (c) => c!.word == compositaWord,
        orElse: () => null,
      );
    }
    if (composita == null) return null;
    // Filter sentences whose target token reading matches the composita's
    // reading — prevents mismatches like 入る(はいる) in a 気に入る(きにいる)
    // sentence.
    final realSentences = widget.deps.sentences.lookup(composita.word);
    final expectedReading = composita.reading;
    final matching = realSentences.where((s) {
      final target = s.tokens.where((t) => t.isTarget).firstOrNull;
      return target == null || target.reading == expectedReading;
    }).toList();
    // Don't fall back to mismatched sentences — use synthetic instead.
    final sentence = matching.isNotEmpty
        ? matching[repetitions % matching.length]
        : syntheticSentenceFor(composita);
    return _ExampleSentenceRef(composita: composita, sentence: sentence);
  }

  Future<void> _grade(int quality) async {
    final card = _currentCard;
    if (card == null) return;
    final sentenceRef = _currentSentence; // captured before it's reset below
    // Snapshot the card's current DB state before grading so undo can
    // restore it.
    final snapshot = await _reviewRepo.getCardState(
      character: card.character,
      cardType: card.cardType,
      compositaWord: card.compositaWord,
    );
    await _reviewRepo.gradeCard(
      character: card.character,
      cardType: card.cardType,
      compositaWord: card.compositaWord,
      quality: quality,
    );
    // quality >= 3 is SM-2's own pass threshold (below it repetitions resets
    // to 0) -- only a genuine pass marks this specific reading as covered,
    // same bar as "known" everywhere else in this repository.
    if (quality >= 3 && sentenceRef != null) {
      final word = sentenceRef.composita.word;
      await _reviewRepo.recordCompositaTested(
        card.character,
        word,
        CompositaDirection.reading,
      );
      _testedWords.putIfAbsent(card.character, () => {}).add(word);
    }
    if (!mounted) return;
    // Re-queue failed cards so the user sees them again until passed.
    final requeued = quality < 3;
    if (requeued) _requeueFailed(card);
    setState(() {
      _lastGradeSnapshot = _GradeSnapshot(
        queueCard: card,
        dbSnapshot: snapshot,
        wasRequeued: requeued,
        sentence: sentenceRef,
      );
      _index++;
      if (!requeued) _cardsDone++;
      _prepareCurrentCard();
    });
    if (_index >= _queue.length) {
      _refreshRemainingCount();
    } else {
      _loadStoryForCurrentCard();
    }
  }

  Future<void> _onDrawPicked(
    List<Prediction> topCandidates,
    String userPick,
  ) async {
    final card = _currentCard;
    if (card == null) return;
    final candidates = topCandidates
        .map((p) => RecognitionCandidate(p.label))
        .toList();
    final quality = gradeDrawAndPick(
      target: card.character,
      topCandidates: candidates,
      userPick: userPick,
    );
    // Snapshot before grading for undo.
    final snapshot = await _reviewRepo.getCardState(
      character: card.character,
      cardType: card.cardType,
      compositaWord: card.compositaWord,
    );
    // Grade (persist SM-2 state) immediately, but don't advance yet -- show
    // feedback first so a miss always reveals the correct answer instead of
    // silently moving on.
    await _reviewRepo.gradeCard(
      character: card.character,
      cardType: card.cardType,
      compositaWord: card.compositaWord,
      quality: quality,
    );
    // Record composita tested for drawInSentence (same logic as _grade's
    // composita path, but draw cards go through _onDrawPicked, not _grade).
    // drawInSentence tests writing (user draws), not reading.
    final sentenceRef = _currentSentence;
    if (quality >= 3 && sentenceRef != null) {
      final word = sentenceRef.composita.word;
      await _reviewRepo.recordCompositaTested(
        card.character,
        word,
        CompositaDirection.writing,
      );
      _testedWords.putIfAbsent(card.character, () => {}).add(word);
    }
    if (!mounted) return;
    setState(() {
      // Snapshot saved here; _continueAfterFeedback will use it when
      // advancing (it knows the requeue status from _feedback.correct).
      _lastGradeSnapshot = _GradeSnapshot(
        queueCard: card,
        dbSnapshot: snapshot,
        wasRequeued: false, // set correctly in _continueAfterFeedback
        sentence: sentenceRef,
      );
      _feedback = _DrawFeedback(
        correct: userPick == card.character,
        target: card.character,
        userPick: userPick,
        sentence: _currentSentence?.sentence,
        composita: _currentSentence?.composita,
      );
      _showFeedbackDetails = true;
    });
  }

  /// For when the user has no idea, rather than making them draw a guess
  /// just to fill the widget -- grades as a full miss (same as the target
  /// not even appearing in the top-3), same as [_onDrawPicked]'s miss path.
  Future<void> _onDontKnow() async {
    final card = _currentCard;
    if (card == null) return;
    // Snapshot before grading for undo.
    final snapshot = await _reviewRepo.getCardState(
      character: card.character,
      cardType: card.cardType,
      compositaWord: card.compositaWord,
    );
    await _reviewRepo.gradeCard(
      character: card.character,
      cardType: card.cardType,
      compositaWord: card.compositaWord,
      quality: 0,
    );
    if (!mounted) return;
    final sentenceRef = _currentSentence;
    setState(() {
      _lastGradeSnapshot = _GradeSnapshot(
        queueCard: card,
        dbSnapshot: snapshot,
        wasRequeued: false, // set correctly in _continueAfterFeedback
        sentence: sentenceRef,
      );
      _feedback = _DrawFeedback(
        correct: false,
        target: card.character,
        userPick: null,
        sentence: _currentSentence?.sentence,
        composita: _currentSentence?.composita,
      );
      _showFeedbackDetails = true;
    });
  }

  void _continueAfterFeedback() {
    final card = _currentCard;
    final requeued = card != null && _feedback != null && !_feedback!.correct;
    if (requeued) {
      // Re-queue missed draw cards until passed.
      _requeueFailed(card);
    }
    setState(() {
      // Update the snapshot's wasRequeued now that we know whether the
      // card was actually re-appended (draw/don't-know cards defer
      // requeue to this point, after the feedback overlay).
      if (_lastGradeSnapshot != null) {
        _lastGradeSnapshot = _GradeSnapshot(
          queueCard: _lastGradeSnapshot!.queueCard,
          dbSnapshot: _lastGradeSnapshot!.dbSnapshot,
          wasRequeued: requeued,
          sentence: _lastGradeSnapshot!.sentence,
        );
      }
      _index++;
      if (!requeued) _cardsDone++;
      _prepareCurrentCard();
    });
    if (_index >= _queue.length) {
      _refreshRemainingCount();
    } else {
      _loadStoryForCurrentCard();
    }
  }

  Future<void> _undoLastGrade() async {
    final snap = _lastGradeSnapshot;
    if (snap == null || _index <= 0) return;

    // 1. Restore the card's DB state.
    await _reviewRepo.undoGrade(
      character: snap.queueCard.character,
      cardType: snap.queueCard.cardType,
      compositaWord: snap.queueCard.compositaWord,
      snapshot: snap.dbSnapshot,
    );

    // 2. If the card was re-queued (failed), remove the last occurrence
    //    from the queue.
    if (snap.wasRequeued) {
      for (var i = _queue.length - 1; i >= 0; i--) {
        final c = _queue[i];
        if (c.character == snap.queueCard.character &&
            c.cardType == snap.queueCard.cardType &&
            c.compositaWord == snap.queueCard.compositaWord) {
          _queue.removeAt(i);
          break;
        }
      }
    }

    if (!mounted) return;
    // 3. Go back one card and reset its state.
    setState(() {
      _index--;
      if (!snap.wasRequeued) _cardsDone--;
      _lastGradeSnapshot = null;
      _currentSentence = snap.sentence;
      _prepareCurrentCard();
      // Restore the sentence ref that _prepareCurrentCard just recomputed --
      // the snapshot's sentence is the one the user originally saw.
      _currentSentence = snap.sentence;
    });
    _loadStoryForCurrentCard();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final l = AppLocalizations.of(context)!;
    final card = _currentCard;
    final isNew = card != null && card.lastReviewedAt == null;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (card == null) {
          // Queue exhausted — review is done, pop immediately.
          if (context.mounted) Navigator.of(context).pop();
          return;
        }
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l.reviewLeaveDialogTitle),
            content: Text(l.reviewLeaveDialogContent),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l.dialogCancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l.reviewLeaveConfirm),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            card == null
                ? l.reviewTitle
                : isNew
                    ? l.reviewHeaderNew(_cardsDone + 1, _cardsDone + _queue.length - _index)
                    : l.reviewHeader(_cardsDone + 1, _cardsDone + _queue.length - _index),
          ),
          actions: [
            if (_lastGradeSnapshot != null &&
                _feedback == null)
              IconButton(
                icon: const Icon(Icons.undo),
                tooltip: l.reviewUndoTooltip,
                onPressed: _undoLastGrade,
              ),
          ],
        ),
        body: SafeArea(
          child: card == null
              ? _buildQueueExhausted()
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildCard(card),
                ),
        ),
      ),
    );
  }

  /// Load more cards beyond the daily cap. Reloads the queue without any
  /// cap so the user can continue studying.
  Future<void> _loadMore(int count) async {
    _dueRefreshTimer?.cancel();
    setState(() => _loading = true);

    // Persist the "learn more" commitment so leaving mid-session and
    // coming back today reloads with the expanded cap, not the default.
    // Persist a high-water mark: the total reviews the user has committed
    // to today. _loadQueue subtracts reviewedToday to get the outstanding
    // remainder, so as cards are reviewed the commitment shrinks naturally.
    final prefs = await SharedPreferences.getInstance();
    final reviewedSoFar = await _reviewRepo.countReviewedToday();
    final todayStr = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    final learnMoreDate = prefs.getString(_learnMoreDateKey);
    final existingHighWater = (learnMoreDate == todayStr)
        ? (prefs.getInt(_learnMoreExtraKey) ?? 0)
        : 0;
    // High-water = max(previous high-water, current reviewed + new count).
    final newHighWater = (reviewedSoFar + count).clamp(existingHighWater, reviewedSoFar + count);
    await prefs.setInt(_learnMoreExtraKey, newHighWater);
    await prefs.setString(_learnMoreDateKey, todayStr);
    // ignore: avoid_print
    print('[_loadMore] count=$count reviewedSoFar=$reviewedSoFar highWater=$newHighWater');

    final scope = widget.deps.studyScope.scope.value;
    _customComposita = await _reviewRepo.customCompositaForCharacters(scope.characters);
    _userComposita = await _reviewRepo.allUserCompositaByChar();

    final reviews = await _reviewRepo.dueCards(
      scope,
      excludeNeverReviewed: true,
    );
    final neverReviewed = await _reviewRepo.cardsNeverReviewed(scope);
    const cardTypeOrder = {
      CardType.drawFromMeaning: 0,
      CardType.kanjiRecognition: 1,
      CardType.readingCloze: 2,
      CardType.drawInSentence: 3,
    };
    neverReviewed.sort((a, b) =>
        (cardTypeOrder[a.cardType] ?? 9)
            .compareTo(cardTypeOrder[b.cardType] ?? 9));

    // Load up to [count] more cards, no cap applied.
    final all = [...reviews, ...neverReviewed];
    final loaded = all.take(count).toList();
    final due = interleaveByCharacter(loaded);

    final testedWords = await _reviewRepo.testedCompositaWordsFor(
      due.map((c) => c.character).toSet(),
      CompositaDirection.reading,
    );
    if (!mounted) return;
    setState(() {
      _queue = due;
      _index = 0;
      _loading = false;
      _lastGradeSnapshot = null;
      _remainingBeyondCap = all.length - loaded.length;
      _testedWords = testedWords;
      _seenCharacters = scope.characters;
      _prepareCurrentCard();
    });
    _loadStoryForCurrentCard();
  }

  /// Re-queries the actual remaining card count from the DB so the
  /// queue-exhausted screen shows a fresh number, not the stale load-time
  /// snapshot. Also starts a periodic timer to pick up cards that become
  /// due while the user is looking at the "no cards" screen.
  Future<void> _refreshRemainingCount() async {
    final scope = widget.deps.studyScope.scope.value;
    // countDueCards already includes never-reviewed cards (they have a
    // dueDate set at introduction time), so no separate query needed.
    final dueCount = await _reviewRepo.countDueCards(scope);
    if (mounted) setState(() => _remainingBeyondCap = dueCount);

    // Start periodic refresh so newly-due cards appear automatically.
    _dueRefreshTimer?.cancel();
    _dueRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) async {
        final count = await _reviewRepo.countDueCards(scope);
        if (mounted) setState(() => _remainingBeyondCap = count);
      },
    );
  }

  Widget _buildQueueExhausted() {
    final l = AppLocalizations.of(context)!;
    final remaining = _remainingBeyondCap;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(remaining > 0
                ? l.reviewDailyLimitReached(remaining)
                : l.reviewNoCardsDue),
            if (remaining > 0) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final n in [10, 25, 50, 100])
                    if (n <= remaining)
                      OutlinedButton(
                        onPressed: () => _loadMore(n),
                        child: Text(l.reviewContinueCards(n)),
                      ),
                  if (!const [10, 25, 50, 100].contains(remaining) &&
                      remaining < 100)
                    OutlinedButton(
                      onPressed: () => _loadMore(remaining),
                      child: Text(l.reviewContinueCards(remaining)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.reviewReturnButton),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(ReviewCard card) {
    final feedback = _feedback;
    if (feedback != null) {
      return _buildFeedback(feedback);
    }
    switch (card.cardType) {
      case CardType.drawFromMeaning:
        return _buildDrawFromMeaning(card);
      case CardType.kanjiRecognition:
        return _buildKanjiRecognition(card);
      case CardType.readingCloze:
        return _currentSentence == null
            ? _buildDrawFromMeaning(card)
            : _buildReadingCloze(card, _currentSentence!);
      case CardType.drawInSentence:
        return _currentSentence == null
            ? _buildDrawFromMeaning(card)
            : _buildDrawInSentence(card, _currentSentence!);
    }
  }

  Widget _buildFeedback(_DrawFeedback feedback) {
    final l = AppLocalizations.of(context)!;
    // No "Not quite"/miss text on a wrong answer -- the icon (red X) plus
    // the revealed answer below already say it, and this saves the
    // non-scrollable Column below the fixed-size canvas some room.

    final header = <Widget>[
      Icon(
        feedback.correct ? Icons.check_circle : Icons.cancel,
        color: feedback.correct ? Colors.green : Colors.red,
        size: feedback.correct ? 40 : 56,
      ),
      if (!feedback.correct) ...[
        const SizedBox(height: 16),
        Text(l.reviewAnswer(feedback.target), style: const TextStyle(fontSize: 40)),
        if (feedback.userPick != null) ...[
          const SizedBox(height: 8),
          Text(l.reviewYouPicked(feedback.userPick!)),
        ],
      ],
    ];

    final sentence = feedback.sentence;
    final composita = feedback.composita;

    // Both a miss AND a correct answer show the same full kanji-editor info
    // (readings, story, stroke order, composita) -- a bare "Correct!" plus
    // just the sentence translation wasn't offering much to actually learn
    // from. Needs Expanded (a bounded height) since KanjiDetailContent is
    // itself a SingleChildScrollView, which needs a bounded viewport --
    // and the Continue button stays a fixed sibling below it (not inside
    // any scrollable) so it's always reachable without having to scroll
    // past KanjiDetailContent's own, independently long, content first.
    //
    // The composita gloss is capped at a few lines (see _compositaInfoText)
    // rather than left free to grow -- an uncapped gloss here, alongside
    // the header/sentence/translation above it, could exceed the space this
    // Column has before Expanded even gets a turn, overflowing the Column
    // outright (confirmed on-device with 一向's gloss "intently,
    // single-minded, devotedly").
    return Column(
      children: [
        ...header,
        if (sentence != null) ...[
          // Show translation first so the user sees the meaning context
          // before the answer reading.
          if (sentence.translation != null &&
              sentence.source != 'synthetic') ...[
            const SizedBox(height: 16),
            Text(
              sentence.translation!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
              ),
            ),
          ],
          const SizedBox(height: 8),
          // Re-show the sentence, fully revealed -- the bare "Answer: X"
          // line above loses the context (and, for drawInSentence, the
          // actual sentence) the card was testing.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FuriganaSentence(
                  kanjiLookup: widget.deps.kanjiInfo.lookup,
                  tokens: sentence.tokens,
                  emphasizeTargetReading: true,
                  highlightTargetBox: true,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TtsButton(text: sentence.sentence),
              ),
            ],
          ),
          // The specific composita word this sentence was built around --
          // its meaning isn't otherwise shown anywhere in this card.
          if (composita != null) ...[
            const SizedBox(height: 8),
            Center(
              child: _compositaInfoText(
                composita,
                sentence.tokens.firstWhere((t) => t.isTarget).reading,
                highlightChar: feedback.target,
              ),
            ),
          ],
        ],
        const SizedBox(height: 8),
        const Divider(),
        Expanded(
          child: KanjiDetailContent(character: feedback.target, deps: widget.deps),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _continueAfterFeedback,
            child: Text(l.reviewContinue),
          ),
        ),
      ],
    );
  }

  /// The word (bold) + reading + meaning + JLPT level of the composita a
  /// sentence-based card was built around -- mirrors kanji_detail_content
  /// .dart's own (private, so not reusable directly) _CompositaLine
  /// styling, shown so the user learns what the tested word actually means,
  /// not just its reading.
  ///
  /// [reading] is the sentence's OWN tokenized reading for this word, not
  /// [Composita.reading] -- they can disagree for a heteronym (composita.json
  /// picks one JMdict sense/reading per word; the sentence's morphological
  /// analyzer independently reads the word as it appears in that specific
  /// sentence). Showing composita.reading here could contradict the reading
  /// already revealed above it, so the sentence's own reading is the one
  /// that must agree with what the user just saw.
  /// Shows a bottom sheet with kanji info (readings, meaning, keyword, story)
  /// for a single character tapped in a composita word.
  void _showKanjiPopup(String character) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: KanjiDetailContent(
                character: character,
                deps: widget.deps,
                scrollable: false,
                compact: false,
              ),
            );
          },
        );
      },
    );
  }


  Widget _compositaInfoText(
    Composita composita,
    String reading, {
    String? highlightChar,
  }) {
    const wordStyle = TextStyle(fontSize: 28, color: Colors.black87);
    const detailStyle = TextStyle(fontSize: 14, color: Colors.black87);
    // Build the composita word as individual characters, with kanji tappable.
    // The tested character (highlightChar) gets a red underline.
    final wordChars = composita.word.characters.toList();
    final kanjiButtons = wordChars.map((char) {
      final isTested = char == highlightChar;
      if (char.length == 1 && isKanji(char.codeUnitAt(0))) {
        return GestureDetector(
          onTap: () => _showKanjiPopup(char),
          child: Text(
            char,
            style: wordStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: isTested ? Colors.red : null,
              decoration: TextDecoration.underline,
              decorationColor: isTested ? Colors.red : Colors.grey.shade400,
            ),
          ),
        );
      }
      return Text(char, style: wordStyle.copyWith(fontWeight: FontWeight.bold));
    }).toList();

    // Try to show per-character readings separated by dots.
    String displayReading = reading;
    final kanjiLookup = widget.deps.kanjiInfo.lookup;
    final splits = composita.splits ??
        splitReading(composita.word, reading, kanjiLookup);
    if (splits != null && splits.length == wordChars.length) {
      displayReading = splits.join('・');
    }

    final suffix = ' ($displayReading): ${composita.meaning}';
    final levelText = composita.effectiveJlptLevel != null
        ? (composita.isLevelInferred
            ? ' [N${composita.effectiveJlptLevel}?]'
            : ' [N${composita.effectiveJlptLevel}]')
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: kanjiButtons,
        ),
        Text(
          '$suffix$levelText',
          style: detailStyle,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // The drawing canvas is deliberately kept OUT of any SingleChildScrollView
  // -- a scrollable ancestor's own drag recognizer competes with the
  // canvas's raw pointer Listener for any vertical stroke and can win,
  // which reads as "the screen scrolls while I'm drawing" (see
  // drawing_canvas.dart's own doc comment on the same underlying gesture-
  // arena issue, and the original build plan's "canvas must not be a
  // SingleChildScrollView descendant" note).
  //
  // Just as importantly, the info block above the canvas is a PLAIN
  // (non-Expanded) Column, not a reactively-sized flex child: DrawAndPick
  // Widget's own height changes continuously while drawing (a "Recognizing
  // ..." line and the candidate buttons appear/disappear after every single
  // stroke), and an Expanded sibling above it would resize in response,
  // visibly shifting the canvas up and down mid-stroke -- confirmed
  // on-device as a "wobbling" canvas. A plain child's position depends only
  // on what's above it, never on a sibling below reflowing.
  Widget _buildDrawFromMeaning(ReviewCard card) {
    final l = AppLocalizations.of(context)!;
    final info = widget.deps.kanjiInfo.lookup(card.character);
    final keyword = _currentStoryKeyword;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (info != null) ...[
          // Capped defensively -- a kanji with an unusually long reading or
          // meaning list sits in this same plain, non-scrollable Column
          // above the fixed-size canvas (see this method's own doc comment
          // on why it can't be Expanded/scrollable).
          if (info.on.isNotEmpty)
            Text(
              l.reviewOnyomi(info.on.join('、')),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (info.kun.isNotEmpty)
            Text(
              l.reviewKunyomi(info.kun.join('、')),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (info.meanings.isNotEmpty)
            Text(
              l.reviewMeaning(info.meanings.join(', ')),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
        // Only the keyword, not the fuller story -- that's saved for after
        // the answer is revealed (the kanji editor, or a miss).
        if (keyword != null && keyword.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l.reviewKeyword(keyword),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
        const SizedBox(height: 16),
        Text(l.reviewDrawFromMeaningPrompt),
        const SizedBox(height: 8),
        Center(
          child: DrawAndPickWidget(
            key: ValueKey('${card.character}-${card.cardType}'),
            recognizer: widget.deps.recognizer,
            onPicked: _onDrawPicked,
            onDontKnow: _onDontKnow,
          ),
        ),
      ],
    );
  }

  /// "B" from the Learning rework: kanji shown, recall its reading(s) +
  /// meaning from memory, self-graded -- the mirror image of
  /// [_buildDrawFromMeaning] ("A": meaning shown, kanji drawn). Structurally
  /// a trimmed [_buildReadingCloze] (reveal, then Again/Good) but for a
  /// bare kanji instead of a sentence blank -- no composita/sentence
  /// involved at all, so [_grade]'s composita-recording branch naturally
  /// no-ops for this card type (_currentSentence is only ever set for
  /// readingCloze/drawInSentence).
  Widget _buildKanjiRecognition(ReviewCard card) {
    final l = AppLocalizations.of(context)!;
    final info = widget.deps.kanjiInfo.lookup(card.character);
    final keyword = _currentStoryKeyword;
    final story = _currentStory;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.reviewKanjiRecognitionPrompt),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    card.character,
                    style: const TextStyle(fontSize: 72),
                  ),
                ),
                const SizedBox(height: 24),
                if (_revealed && info != null) ...[
                  if (info.on.isNotEmpty) Text(l.reviewOnyomi(info.on.join('、'))),
                  if (info.kun.isNotEmpty) Text(l.reviewKunyomi(info.kun.join('、'))),
                  if (info.meanings.isNotEmpty)
                    Text(l.reviewMeaning(info.meanings.join(', '))),
                  if (keyword != null && keyword.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      keyword,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                  if (story != null && story.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      story,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => DraggableScrollableSheet(
                            initialChildSize: 0.8,
                            minChildSize: 0.4,
                            maxChildSize: 0.95,
                            expand: false,
                            builder: (context, scrollController) => Padding(
                              padding: const EdgeInsets.all(16),
                              child: KanjiDetailContent(
                                character: card.character,
                                deps: widget.deps,
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: Text(l.reviewShowDetails),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (!_revealed)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _revealed = true),
              child: Text(l.reviewReveal),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _grade(2),
                  child: Text(l.reviewAgain),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _grade(4),
                  child: Text(l.reviewGood),
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// Tiny right-aligned label showing the sentence origin: a Tatoeba link
  /// for mined sentences, "LLM-generated" for LLM ones, nothing for
  /// synthetic pseudo-sentences (the bare word is self-evident).
  Widget _buildSentenceSourceLabel(ExampleSentence sentence) {
    if (sentence.source == 'synthetic') return const SizedBox.shrink();
    final text = sentence.source == 'tatoeba' ? 'Tatoeba' : 'LLM-generated';
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          text,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ),
    );
  }

  /// A "Show translation" reveal, independent of the reading/drawing
  /// grading flow -- available any time, purely a comprehension aid, so it
  /// doesn't touch SM-2 state. Omitted entirely when this sentence has no
  /// linked/generated translation (not every mined sentence has one -- see
  /// the build script's coverage warning).
  Widget _buildTranslationToggle(ExampleSentence sentence) {
    final l = AppLocalizations.of(context)!;
    final translation = sentence.translation;
    if (translation == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            onPressed: () => setState(
              () => _translationRevealed = !_translationRevealed,
            ),
            child: Text(
              _translationRevealed ? l.reviewHideTranslation : l.reviewShowTranslation,
            ),
          ),
          if (_translationRevealed)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 8),
              // Capped rather than left to grow unbounded -- drawInSentence
              // places this toggle as a plain (non-scrollable) sibling next
              // to the fixed-size canvas (see _buildDrawInSentence's own
              // doc comment on why it can't be Expanded/scrollable itself),
              // so an uncapped translation there could squeeze the toggle
              // button itself out of its interactable area. Same cap
              // applies harmlessly in readingCloze's already-scrollable
              // context.
              child: Text(
                translation,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildReadingCloze(ReviewCard card, _ExampleSentenceRef ref) {
    final l = AppLocalizations.of(context)!;
    final targetReading = ref.sentence.tokens
        .firstWhere((t) => t.isTarget)
        .reading;
    // Auto-scroll to the highlighted target word after layout so a long
    // sentence doesn't leave the red box below the fold.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _readingClozeTargetKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 300),
            alignment: 0.3);
      }
    });
    // Use unsplit tokens so the target word stays as a single Wrap child
    // with one consistent red highlight box. Splitting into per-character
    // sub-tokens caused misaligned furigana and inconsistent box heights.
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.reviewReadingClozePrompt),
                const SizedBox(height: 24),
                FuriganaSentence(
                  kanjiLookup: widget.deps.kanjiInfo.lookup,
                  targetKey: _readingClozeTargetKey,
                  tokens: ref.sentence.tokens,
                  hideTargetReading: !_revealed,
                  emphasizeTargetReading: _revealed,
                  highlightTargetBox: true,
                  highlightCharacter: card.character,
                  seenCharacters: _seenCharacters,
                ),
                Row(
                  children: [
                    Expanded(child: _buildSentenceSourceLabel(ref.sentence)),
                    TtsButton(text: ref.sentence.sentence),
                  ],
                ),
                if (_revealed) ...[
                  const SizedBox(height: 8),
                  Text(
                    targetReading,
                    style: const TextStyle(
                      fontSize: 28,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                _buildTranslationToggle(ref.sentence),
                if (_revealed) ...[
                  const SizedBox(height: 8),
                  _compositaInfoText(
                    ref.composita,
                    targetReading,
                    highlightChar: card.character,
                  ),
                  const SizedBox(height: 8),
                  _compositaKanjiRow(ref.composita),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (!_revealed)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _revealed = true),
              child: Text(l.reviewReveal),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _grade(2),
                  child: Text(l.reviewAgain),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _grade(4),
                  child: Text(l.reviewGood),
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// A compact row of the composita word's kanji characters, each tappable
  /// to show a kanji detail popup. Used before reveal in readingCloze so the
  /// user can identify which word is being tested and look up components.
  /// Shows each kanji in the composita word with its meaning, similar to
  /// the kanji browser's detail view. Each kanji is tappable for full info.
  Widget _compositaKanjiRow(Composita composita) {
    final wordChars = composita.word.characters.toList();
    final kanjiChars = wordChars
        .where((c) => c.length == 1 && isKanji(c.codeUnitAt(0)))
        .toList();
    if (kanjiChars.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: kanjiChars.map((char) {
        final info = widget.deps.kanjiInfo.lookup(char);
        final meaning = info?.meanings.join(', ') ?? '';
        return GestureDetector(
          onTap: () => _showKanjiPopup(char),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: char,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.grey,
                    ),
                  ),
                  if (meaning.isNotEmpty)
                    TextSpan(
                      text: ' — $meaning',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // See _buildDrawFromMeaning's doc comment: the canvas stays out of any
  // SingleChildScrollView, AND the info above it is not an Expanded/
  // Flexible sibling -- either would reactively resize as DrawAndPickWidget
  // 's own height changes after every stroke (Recognizing.../candidates
  // appearing and disappearing), visibly shifting the canvas mid-stroke.
  //
  // Unlike _buildDrawFromMeaning's short readings/keyword text, the
  // sentence can wrap across several lines -- uncapped in length. A fixed
  // height for this block was tried first (confirmed on-device as a ~79px
  // bottom overflow on a short one-line sentence, where the fixed block
  // was mostly empty padding the canvas/candidates needed); a flat
  // percentage-of-screen-height CAP was tried next, but that's still just
  // a guess disconnected from what's actually available once the AppBar/
  // padding/Don't-know button are accounted for -- confirmed on-device as
  // a smaller (~5px) but still real overflow once a longer sentence
  // wrapped to 2 lines and used the whole cap. This version instead
  // measures the ACTUAL available height via LayoutBuilder and reserves
  // [_drawAndPickWorstCaseHeight] (DrawAndPickWidget's own tallest state,
  // canvas + Clear + a fully expanded candidate picker) plus the other
  // fixed siblings up front, so the sentence block only ever gets
  // whatever's genuinely left over -- guaranteed not to overflow
  // regardless of how many lines the sentence wraps to; it just scrolls
  // internally past that point instead.
  //
  // The translation toggle is deliberately kept OUT of that scrollable/
  // capped sentence box, as a plain sibling instead (matching
  // _buildReadingCloze) -- confirmed on-device as a real bug when it lived
  // inside: once the sentence box got squeezed small (a long sentence
  // leaves little of the reserved budget spare), the toggle button's
  // clipped/scrolled-past position could land outside its own
  // interactable area, reading as "the button doesn't do anything" even
  // though the tap handler itself was never broken. _buildTranslationToggle
  // caps its own revealed text (maxLines) precisely so it's safe to place
  // here, unscrollable, next to the fixed-size canvas.
  //
  // Unlike the other reserved siblings, the toggle's own height genuinely
  // varies (collapsed vs. revealed, and revealed can wrap 1-3 lines) --
  // a single flat guess here undercounted a revealed 2-line translation
  // and caused a real bottom overflow on-device (confirmed on a Galaxy A54
  // with the system font-size setting bumped to 1.1x, which inflates every
  // text-driven measurement here, not just this one -- see the textScale
  // use below). [_translationToggleReservedHeight] measures the actual
  // current text instead of guessing.
  //
  // DrawAndPickWidget's reserved budget is split in two: the canvas itself
  // ([_drawAndPickCanvasHeight], DrawingCanvas's displaySize + its gap) is a
  // fixed dp size that does NOT grow with the system font scale, only the
  // Clear button/candidate-picker TEXT below it does. Multiplying the whole
  // budget by textScale (as an earlier version of this fix did) inflated
  // the canvas portion too, for no reason -- on the same Galaxy A54 that
  // needed the translation-toggle fix above, that overcounted the reserved
  // total by ~25dp it didn't need to, squeezing the sentence box down to
  // its 60dp floor even for a short sentence.
  static const double _drawAndPickCanvasHeight = 260 + 12;
  static const double _drawAndPickTextWorstCase = 160;

  double _translationToggleReservedHeight(String? translation, double maxWidth) {
    final scaler = MediaQuery.textScalerOf(context);
    const outerTopPadding = 8.0;
    const buttonHeight = 40.0;
    final reservedButton = outerTopPadding + scaler.scale(buttonHeight);
    if (translation == null || !_translationRevealed) return reservedButton;
    final painter = TextPainter(
      text: TextSpan(
        text: translation,
        style: DefaultTextStyle.of(
          context,
        ).style.merge(const TextStyle(fontStyle: FontStyle.italic)),
      ),
      maxLines: 3,
      textDirection: Directionality.of(context),
      textScaler: scaler,
    )..layout(maxWidth: (maxWidth - 12).clamp(0.0, double.infinity));
    return reservedButton + painter.height + 8;
  }

  Widget _buildDrawInSentence(ReviewCard card, _ExampleSentenceRef ref) {
    final l = AppLocalizations.of(context)!;
    const sentenceGap = 8.0;
    // Split the target token so unseen kanji show reading hints.
    // For draw-in-sentence, FuriganaSentence uses targetCharacter+replacement
    // Don't split the target token for drawInSentence — the draw box
    // replaces only the tested character within the unsplit word, keeping
    // the other characters aligned at the same vertical position. Splitting
    // would make each character a separate Wrap child, misaligning the
    // 32×32 draw box against the smaller text-height kanji.
    return LayoutBuilder(
      builder: (context, constraints) {
        // The Don't-know button and DrawAndPickWidget's own Clear button/
        // candidate-picker text grow with the system font scale too --
        // scale their reserved budgets the same way the translation
        // toggle's is measured, so a larger accessibility font size doesn't
        // reintroduce the same overflow from a different sibling.
        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
        final reserved = sentenceGap +
            _translationToggleReservedHeight(
              ref.sentence.translation,
              constraints.maxWidth,
            ) +
            _drawAndPickCanvasHeight +
            _drawAndPickTextWorstCase * textScale;
        final sentenceMaxHeight = (constraints.maxHeight - reserved).clamp(
          60.0,
          double.infinity,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: sentenceMaxHeight),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FuriganaSentence(
                    kanjiLookup: widget.deps.kanjiInfo.lookup,
                      tokens: ref.sentence.tokens,
                      targetCharacter: card.character,
                      targetReplacement: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade500),
                        ),
                        child: const Icon(Icons.edit, size: 18),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(child: _buildSentenceSourceLabel(ref.sentence)),
                        TtsButton(text: ref.sentence.sentence),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _buildTranslationToggle(ref.sentence),
            const SizedBox(height: sentenceGap),
            Center(
              child: DrawAndPickWidget(
                key: ValueKey('${card.character}-${card.cardType}'),
                recognizer: widget.deps.recognizer,
                onPicked: _onDrawPicked,
                onDontKnow: _onDontKnow,
              ),
            ),
          ],
        );
      },
    );
  }
}
