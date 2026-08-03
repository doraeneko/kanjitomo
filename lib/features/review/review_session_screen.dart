import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, LengthLimitingTextInputFormatter;
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
import 'review_focus.dart';
import 'review_repository.dart';
import 'sentence_selection.dart';
import 'sm2.dart';
import 'study_scope.dart';

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

/// Presents due (and newly-introduced) review cards one at a time across
/// all three card types, grading each via SM-2. Card-type-specific UI is
/// built inline per card rather than as separate screens/routes, since
/// they share the same session flow (grade -> advance) and queue.
class ReviewSessionScreen extends StatefulWidget {
  final AppDependencies deps;
  // Which learning axes (A+B / C+D / both) this session introduces and
  // quizzes -- chosen in ReviewStartScreen, defaulting to both so every
  // existing direct construction of this screen keeps today's behavior.
  final ReviewFocus focus;

  const ReviewSessionScreen({
    super.key,
    required this.deps,
    this.focus = ReviewFocus.both,
  });

  @override
  State<ReviewSessionScreen> createState() => _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends State<ReviewSessionScreen> {
  static const _dailyNewCapKey = 'review.daily_new_cap';
  static const _defaultDailyNewCap = 10;

  late final ReviewRepository _reviewRepo;
  int _dailyNewCap = _defaultDailyNewCap;
  late final TextEditingController _learnMoreCapController;
  bool _loading = true;
  bool _sessionStarted = false;
  List<ReviewCard> _queue = [];
  int _index = 0;
  // Deduplicated new characters (lastReviewedAt == null) from the queue,
  // shown in a slideshow before the actual review begins.
  List<String> _newCharacters = [];
  // Non-null while the new-kanji slideshow is active; null means normal
  // review mode. Incremented by "Next", set to null after the last slide.
  int? _slideshowIndex;
  bool _revealed = false;
  bool _translationRevealed = false;
  _ExampleSentenceRef? _currentSentence;
  _DrawFeedback? _feedback;
  // How many more not-yet-introduced characters are available in scope
  // beyond today's cap -- 0 once truly nothing is left to learn. Powers
  // the "Learn more today" button shown once the queue runs dry.
  int _moreToLearn = 0;
  // Cards re-queued after a fail -- tracked to avoid infinite loops (each
  // card is re-queued at most once per session, like Anki's "learning" step).
  final Set<String> _requeued = {}; // "${character}:${cardType}" keys
  // The current card's personal story keyword (not the fuller story --
  // that would give away too much before the user has drawn anything),
  // fetched asynchronously since kanji_notes is DB-backed, unlike the
  // preloaded JSON repositories. Null while loading or genuinely unset.
  String? _currentStoryKeyword;
  // character -> composita words already passed at least once, batch-loaded
  // for the whole queue up front (see _loadQueue) so _pickSentenceFor (a
  // synchronous helper called from setState) can prefer not-yet-tested
  // words without needing its own DB round-trip.
  Map<String, Set<String>> _testedWords = {};
  // character -> explicitly-selected custom composita (see
  // custom_edit_screen.dart), batch-loaded up front same as [_testedWords]
  // -- only ever populated (and consulted) in custom mode; JLPT mode uses
  // StudyScope.compositaCeiling instead (see sentence_selection.dart).
  Map<String, Set<String>> _customComposita = {};
  // character -> user-added composita (JMdict words added manually via
  // composita picker search or word lookup's "Add to review"), batch-loaded
  // up front so _eligibleCompositaFor can merge them with the bundled list
  // without a DB round-trip.
  Map<String, List<Composita>> _userComposita = {};

  @override
  void initState() {
    super.initState();
    _reviewRepo = ReviewRepository(widget.deps.database);
    _learnMoreCapController = TextEditingController();
    _loadDailyNewCap();
  }

  @override
  void dispose() {
    _learnMoreCapController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyNewCap() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_dailyNewCapKey);
    if (stored != null && mounted) {
      _dailyNewCap = stored;
    }
    _learnMoreCapController.text = '$_dailyNewCap';
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    final scope = widget.deps.studyScope.scope.value;
    // Loaded up front, before _introduceNewCardsForToday (which calls
    // _sentenceEligibleCharacters, needing this for custom mode) --
    // mirrors _testedWords' own "batch-load once, no DB round-trip from a
    // synchronous helper" reasoning.
    _customComposita = scope.mode == StudyScopeMode.custom
        ? await _reviewRepo.customCompositaForCharacters(scope.customCharacters)
        : {};
    _userComposita = await _reviewRepo.allUserCompositaByChar();
    final introducedNow = await _introduceNewCardsForToday();

    final cardTypes = cardTypesForFocus(widget.focus);

    // Load reviews (previously seen cards that are due or fragile) and
    // freshly introduced new cards separately, then merge -- never-
    // reviewed leftovers from earlier sessions stay hidden until the
    // daily cap has room (Anki-like behaviour).
    final reviews = await _reviewRepo.dueCards(
      scope,
      cardTypes: cardTypes,
      excludeNeverReviewed: true,
    );
    final newCards = introducedNow.isNotEmpty
        ? await _reviewRepo.cardsForCharacters(
            introducedNow,
            cardTypes: cardTypes,
          )
        : <ReviewCard>[];
    final due = interleaveByCharacter([...reviews, ...newCards]);

    final testedWords = await _reviewRepo.testedCompositaWordsFor(
      due.map((c) => c.character).toSet(),
      CompositaDirection.reading,
    );
    if (!mounted) return;
    // Deduplicate new characters for the slideshow.
    final seen = <String>{};
    final newChars = <String>[];
    for (final card in newCards) {
      if (seen.add(card.character)) {
        newChars.add(card.character);
      }
    }
    setState(() {
      _queue = due;
      _index = 0;
      _loading = false;
      _testedWords = testedWords;
      _newCharacters = newChars;
      _slideshowIndex = !_sessionStarted && newChars.isNotEmpty ? 0 : null;
      _sessionStarted = true;
      _prepareCurrentCard();
    });
    _loadStoryForCurrentCard();
    _refreshMoreToLearn();
  }

  /// Introduces up to [_dailyNewCap] not-yet-seen characters, creating
  /// ALL card types for each character in one go -- A (drawFromMeaning) +
  /// B (kanjiRecognition) unconditionally, plus C+D (readingCloze,
  /// drawInSentence) for characters with composita coverage. The session
  /// then presents them in order (A first, then B, then C/D via the
  /// interleaved queue) so the user learns all axes of each new kanji in
  /// one sitting.
  ///
  /// Characters that were introduced in PREVIOUS sessions but haven't
  /// passed their earlier card types yet still get their remaining types
  /// introduced here too (same "no gate" rule), since the user chose to
  /// learn them and shouldn't have to wait across sessions.
  ///
  /// Shared by the initial load and by [_learnMore], since calling it
  /// again naturally introduces up to another capful (already-introduced
  /// characters are excluded by [ReviewRepository.introduceNewCards]' own
  /// query).
  ///
  /// Returns the set of characters freshly introduced by this call (used
  /// to populate the new-kanji slideshow without including older
  /// never-reviewed leftovers).
  Future<Set<String>> _introduceNewCardsForToday() async {
    final scope = widget.deps.studyScope.scope.value;
    final introduced = <String>{};

    // A (drawFromMeaning): the entry-point card type -- determines which
    // characters are "new today". The cap applies here.
    if (widget.focus != ReviewFocus.composita) {
      introduced.addAll(await _reviewRepo.introduceNewCards(
        scope,
        CardType.drawFromMeaning,
        limit: _dailyNewCap,
      ));
    }

    // B (kanjiRecognition): introduced for ALL characters that have an A
    // card (whether passed or not), so freshly introduced characters get
    // their B card in the same session. Also picks up characters from
    // earlier sessions whose B card hasn't been created yet.
    if (widget.focus != ReviewFocus.composita) {
      introduced.addAll(await _reviewRepo.introduceNewCards(
        scope,
        CardType.kanjiRecognition,
        limit: _dailyNewCap,
      ));
    }

    // C+D (readingCloze, drawInSentence): introduced for ALL characters
    // with composita coverage, not gated behind passing B. Same "learn
    // everything about each kanji in one session" principle.
    if (widget.focus != ReviewFocus.core) {
      final sentenceEligible = _sentenceEligibleCharacters(scope);
      introduced.addAll(await _reviewRepo.introduceNewCards(
        scope,
        CardType.readingCloze,
        limit: _dailyNewCap,
        restrictToCharacters: sentenceEligible,
      ));
      introduced.addAll(await _reviewRepo.introduceNewCards(
        scope,
        CardType.drawInSentence,
        limit: _dailyNewCap,
        restrictToCharacters: sentenceEligible,
      ));
    }

    return introduced;
  }

  /// Read-only tally of how many more NEW CHARACTERS are available to learn
  /// if the user asks for more today. Counts introducible A
  /// (drawFromMeaning) cards -- one per character -- so the number matches
  /// the user's mental model ("learn 2 more kanji", not "learn 6 more
  /// cards"). Shown so "Learn more today" can either offer an honest count
  /// or, once this is 0, tell the user there's genuinely nothing left in
  /// scope instead of a dead button.
  Future<void> _refreshMoreToLearn() async {
    final scope = widget.deps.studyScope.scope.value;
    // A cards are the entry point: one per character, so this count equals
    // the number of new kanji available.
    final count = await _reviewRepo.countIntroducible(
      scope,
      CardType.drawFromMeaning,
    );
    if (!mounted) return;
    setState(() => _moreToLearn = count);
  }

  Future<void> _learnMore() async {
    final parsed = int.tryParse(_learnMoreCapController.text);
    if (parsed != null && parsed >= 1) {
      _dailyNewCap = parsed;
    }
    setState(() => _loading = true);
    await _loadQueue();
  }

  /// [char]'s composita actually eligible for C+D testing under [scope]
  /// (see sentence_selection.dart's eligibleComposita) -- _customComposita
  /// and _userComposita are batch-loaded up front in _loadQueue so this
  /// stays a synchronous, no-DB-round-trip helper.
  List<Composita> _eligibleCompositaFor(String char, StudyScope scope) {
    final bundled = widget.deps.composita.lookup(char);
    final merged = _mergeComposita(bundled, _userComposita[char]);
    return eligibleComposita(
      merged,
      scope,
      _customComposita[char] ?? const {},
    );
  }

  /// Merges bundled composita with user-added ones, deduplicating by word.
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

  /// Characters with at least one eligible composita word (see
  /// _eligibleCompositaFor) -- the composita/sentence card types (C+D) can
  /// only be introduced for these (see
  /// ReviewRepository.introduceNewCards' restrictToCharacters). A real
  /// mined sentence is no longer required: _pickSentenceFor falls back to
  /// a synthetic single-word pseudo-sentence (see
  /// sentence_selection.dart's syntheticSentenceFor) when none exists, so
  /// composita-only testing (C, without D) still works. Empty outright
  /// when composita/sentence testing isn't enabled for this scope at all
  /// (see compositaEnabled) -- e.g. JLPT mode with no ceiling chosen yet.
  Set<String> _sentenceEligibleCharacters(StudyScope scope) {
    if (!compositaEnabled(scope)) return {};
    final chars = <String>{};
    for (final char in widget.deps.kanjiInfo.characters) {
      final jlptLevel = widget.deps.jlptLevels.levelOf(char);
      final rtkIndex = widget.deps.rtkIndex.indexOf(char);
      final levelRank = widget.deps.kanjiLevelRank.rankOf(char);
      if (!scope.matches(
        character: char,
        jlptLevel: jlptLevel,
        rtkIndex: rtkIndex,
        levelRank: levelRank,
      )) {
        continue;
      }
      if (_eligibleCompositaFor(char, scope).isNotEmpty) chars.add(char);
    }
    return chars;
  }

  /// Re-appends [card] to the end of the queue if it hasn't been re-queued
  /// already in this session. Prevents infinite loops while still giving
  /// the user a second chance at each missed card (Anki-style).
  void _requeueIfFirst(ReviewCard card) {
    final key = '${card.character}:${card.cardType}';
    if (_requeued.add(key)) _queue.add(card);
  }

  ReviewCard? get _currentCard =>
      _index < _queue.length ? _queue[_index] : null;

  void _prepareCurrentCard() {
    _revealed = false;
    _translationRevealed = false;
    _feedback = null;
    _currentStoryKeyword = null; // stale until _loadStoryForCurrentCard() resolves
    final card = _currentCard;
    _currentSentence =
        (card != null &&
            (card.cardType == CardType.readingCloze ||
                card.cardType == CardType.drawInSentence))
        ? _pickSentenceFor(card.character)
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
    if (!mounted || _currentCard?.character != character) return;
    setState(() => _currentStoryKeyword = keyword);
  }

  _ExampleSentenceRef? _pickSentenceFor(String character) {
    final scope = widget.deps.studyScope.scope.value;
    if (!compositaEnabled(scope)) return null;
    final eligible = _eligibleCompositaFor(character, scope);
    final picked = pickUntested(eligible, _testedWords[character] ?? const {});
    if (picked == null) return null;
    final realSentences = widget.deps.sentences.lookup(picked.word);
    // D when a real mined sentence exists, else C via a synthetic
    // single-word pseudo-sentence (see sentence_selection.dart) -- same
    // FuriganaSentence-based card either way.
    final sentence = realSentences.isNotEmpty
        ? realSentences.first
        : syntheticSentenceFor(picked);
    return _ExampleSentenceRef(composita: picked, sentence: sentence);
  }

  Future<void> _grade(int quality) async {
    final card = _currentCard;
    if (card == null) return;
    final sentenceRef = _currentSentence; // captured before it's reset below
    await _reviewRepo.gradeCard(
      character: card.character,
      cardType: card.cardType,
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
    // Anki-style: re-queue failed cards so the user sees them once more.
    if (quality < 3) _requeueIfFirst(card);
    setState(() {
      _index++;
      _prepareCurrentCard();
    });
    _loadStoryForCurrentCard();
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
    // Grade (persist SM-2 state) immediately, but don't advance yet -- show
    // feedback first so a miss always reveals the correct answer instead of
    // silently moving on.
    await _reviewRepo.gradeCard(
      character: card.character,
      cardType: card.cardType,
      quality: quality,
    );
    if (!mounted) return;
    setState(() {
      _feedback = _DrawFeedback(
        correct: userPick == card.character,
        target: card.character,
        userPick: userPick,
        sentence: _currentSentence?.sentence,
        composita: _currentSentence?.composita,
      );
    });
  }

  /// For when the user has no idea, rather than making them draw a guess
  /// just to fill the widget -- grades as a full miss (same as the target
  /// not even appearing in the top-3), same as [_onDrawPicked]'s miss path.
  Future<void> _onDontKnow() async {
    final card = _currentCard;
    if (card == null) return;
    await _reviewRepo.gradeCard(
      character: card.character,
      cardType: card.cardType,
      quality: 0,
    );
    if (!mounted) return;
    setState(() {
      _feedback = _DrawFeedback(
        correct: false,
        target: card.character,
        userPick: null,
        sentence: _currentSentence?.sentence,
        composita: _currentSentence?.composita,
      );
    });
  }

  void _continueAfterFeedback() {
    // Anki-style: re-queue missed draw cards so the user sees them once more.
    final card = _currentCard;
    if (card != null && _feedback != null && !_feedback!.correct) {
      _requeueIfFirst(card);
    }
    setState(() {
      _index++;
      _prepareCurrentCard();
    });
    _loadStoryForCurrentCard();
  }

  void _advanceSlideshow() {
    setState(() {
      final next = (_slideshowIndex ?? 0) + 1;
      if (next < _newCharacters.length) {
        _slideshowIndex = next;
      } else {
        _slideshowIndex = null; // slideshow done, start normal review
      }
    });
  }

  Widget _buildSlideshow() {
    final l = AppLocalizations.of(context)!;
    final idx = _slideshowIndex!;
    final char = _newCharacters[idx];
    final isLast = idx == _newCharacters.length - 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.reviewSlideshowTitle(idx + 1, _newCharacters.length)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: KanjiDetailContent(character: char, deps: widget.deps),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _advanceSlideshow,
                  child: Text(isLast ? l.reviewSlideshowStartReview : l.reviewSlideshowNext),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_slideshowIndex != null) {
      return _buildSlideshow();
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
                    ? l.reviewHeaderNew(_index + 1, _queue.length)
                    : l.reviewHeader(_index + 1, _queue.length),
          ),
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

  /// Shown once the queue runs dry: due cards are done, and today's new-card
  /// cap (if in scope) has been reached. Offers to lift the cap on demand
  /// rather than making the user wait for a fresh calendar day, but only
  /// when there's honestly something left to learn in scope.
  Widget _buildQueueExhausted() {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.reviewNoCardsDue),
          if (_moreToLearn > 0) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _learnMoreCapController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[1-9][0-9]*')),
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _learnMore,
                  child: Text(l.reviewLearnMoreButton),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l.reviewMoreAvailable(_moreToLearn),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.reviewReturnButton),
          ),
        ],
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
        size: 56,
      ),
      const SizedBox(height: 16),
      if (feedback.correct) ...[
        Text(l.reviewCorrect, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
      ],
      Text(l.reviewAnswer(feedback.target), style: const TextStyle(fontSize: 40)),
      if (feedback.userPick != null) ...[
        const SizedBox(height: 8),
        Text(l.reviewYouPicked(feedback.userPick!)),
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
          const SizedBox(height: 16),
          // Re-show the sentence, fully revealed -- the bare "Answer: X"
          // line above loses the context (and, for drawInSentence, the
          // actual sentence) the card was testing.
          FuriganaSentence(
            tokens: sentence.tokens,
            emphasizeTargetReading: true,
            highlightTargetBox: true,
          ),
          if (sentence.translation != null) ...[
            const SizedBox(height: 8),
            Text(
              sentence.translation!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
              ),
            ),
          ],
          // The specific composita word this sentence was built around --
          // its meaning isn't otherwise shown anywhere in this card.
          if (composita != null) ...[
            const SizedBox(height: 8),
            Center(
              child: _compositaInfoText(
                composita,
                sentence.tokens.firstWhere((t) => t.isTarget).reading,
              ),
            ),
          ],
        ],
        const SizedBox(height: 16),
        const Divider(),
        Expanded(
          child: KanjiDetailContent(character: feedback.target, deps: widget.deps),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _continueAfterFeedback,
          child: Text(l.reviewContinue),
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
  Widget _compositaInfoText(Composita composita, String reading) {
    const base = TextStyle(fontSize: 14, color: Colors.black87);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(
            text: composita.word,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: ' ($reading): ${composita.meaning}'),
          if (composita.effectiveJlptLevel != null)
            TextSpan(
              text: composita.isLevelInferred
                  ? ' [N${composita.effectiveJlptLevel}?]'
                  : ' [N${composita.effectiveJlptLevel}]',
              style: TextStyle(color: Colors.grey.shade600),
            ),
        ],
      ),
      textAlign: TextAlign.center,
      // A JMdict gloss can run long (multiple senses, semicolon-separated) --
      // capped rather than left to grow unbounded, since this sits in a
      // plain (non-scrollable) Column in _buildFeedback that can only
      // absorb so much before overflowing.
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
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
          ),
        ),
        Center(
          child: TextButton(
            onPressed: _onDontKnow,
            child: Text(l.reviewDontKnow),
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
    return SingleChildScrollView(
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
            const SizedBox(height: 24),
          ],
          if (!_revealed)
            ElevatedButton(
              onPressed: () => setState(() => _revealed = true),
              child: Text(l.reviewReveal),
            )
          else
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton(
                  onPressed: () => _grade(2),
                  child: Text(l.reviewAgain),
                ),
                ElevatedButton(
                  onPressed: () => _grade(4),
                  child: Text(l.reviewGood),
                ),
              ],
            ),
        ],
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.reviewReadingClozePrompt),
          const SizedBox(height: 24),
          FuriganaSentence(
            tokens: ref.sentence.tokens,
            hideTargetReading: !_revealed,
            emphasizeTargetReading: _revealed,
            highlightTargetBox: true,
          ),
          if (_revealed) ...[
            const SizedBox(height: 8),
            Text(
              targetReading,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          _buildTranslationToggle(ref.sentence),
          // Once the answer is revealed, show the translation automatically
          // too -- unless the manual toggle already showed it, to avoid
          // displaying the same text twice.
          if (_revealed &&
              !_translationRevealed &&
              ref.sentence.translation != null) ...[
            const SizedBox(height: 8),
            Text(
              ref.sentence.translation!,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
              ),
            ),
          ],
          // The composita word being tested -- its meaning isn't otherwise
          // shown anywhere on this card, only its reading (above).
          if (_revealed) ...[
            const SizedBox(height: 8),
            _compositaInfoText(ref.composita, targetReading),
          ],
          const SizedBox(height: 24),
          if (!_revealed)
            ElevatedButton(
              onPressed: () => setState(() => _revealed = true),
              child: Text(l.reviewReveal),
            )
          else
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton(
                  onPressed: () => _grade(2),
                  child: Text(l.reviewAgain),
                ),
                ElevatedButton(
                  onPressed: () => _grade(4),
                  child: Text(l.reviewGood),
                ),
              ],
            ),
        ],
      ),
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
  static const double _drawAndPickTextWorstCase = 150;
  static const double _dontKnowButtonHeight = 48;

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
            _drawAndPickTextWorstCase * textScale +
            _dontKnowButtonHeight * textScale;
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
                child: FuriganaSentence(
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
              ),
            ),
            _buildTranslationToggle(ref.sentence),
            const SizedBox(height: sentenceGap),
            Center(
              child: DrawAndPickWidget(
                key: ValueKey('${card.character}-${card.cardType}'),
                recognizer: widget.deps.recognizer,
                onPicked: _onDrawPicked,
              ),
            ),
            Center(
              child: TextButton(
                onPressed: _onDontKnow,
                child: Text(l.reviewDontKnow),
              ),
            ),
          ],
        );
      },
    );
  }
}
