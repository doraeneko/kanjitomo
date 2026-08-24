import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/db/app_database.dart';
import '../../core/db/tables.dart';
import '../../data/composita_repository.dart';
import '../../data/sentences_repository.dart';
import 'sm2.dart';
import 'study_scope.dart';

/// Per-cardType breakdown for the statistics screen. "Known"/"missed" only
/// count cards that have actually been reviewed at least once -- a fresh
/// card's repetitions is also 0, but that's "not started", not a miss.
class CardTypeStats {
  final int known;
  final int missed;
  final int notStarted;

  const CardTypeStats({
    required this.known,
    required this.missed,
    required this.notStarted,
  });
}

/// C+D (composita/sentence) coverage for a set of characters: how many of
/// their testable composita words (the caller's own "eligible under this
/// scope" set -- see sentence_selection.dart's eligibleComposita) have
/// been tested (CompositaProgress) at least once, per direction. Purely
/// informational -- never gates [ReviewRepository.overallProgress]'s green
/// computation.
class CompositaCoverage {
  final int testable;
  final int testedReading;
  final int testedWriting;

  const CompositaCoverage({
    required this.testable,
    required this.testedReading,
    required this.testedWriting,
  });
}

/// Per-card-type progress detail for a single character, shown in the
/// statistics screen's tap-to-inspect dialog. Reports the SM-2 repetitions
/// count (consecutive correct answers) against the known threshold for each
/// core direction (A: drawFromMeaning, B: kanjiRecognition).
class KanjiProgressDetail {
  /// B: kanjiRecognition — consecutive correct answers so far.
  final int recognitionReps;

  /// A: drawFromMeaning — consecutive correct answers so far.
  final int drawingReps;

  /// Whether the character has been reviewed at all for recognition.
  final bool recognitionStarted;

  /// Whether the character has been reviewed at all for drawing.
  final bool drawingStarted;

  /// The threshold to be considered "known" (same as overallProgress).
  static const int knownThreshold = 2;

  /// How many composita words are testable for this character (0 if none).
  final int compositaTestable;

  /// How many of those composita words have been tested at least once
  /// in the reading direction.
  final int compositaReadingTested;

  /// How many of those composita words have been tested at least once
  /// in the writing direction.
  final int compositaWritingTested;

  const KanjiProgressDetail({
    required this.recognitionReps,
    required this.drawingReps,
    required this.recognitionStarted,
    required this.drawingStarted,
    this.compositaTestable = 0,
    this.compositaReadingTested = 0,
    this.compositaWritingTested = 0,
  });

  bool get recognitionKnown => recognitionReps >= knownThreshold;
  bool get drawingKnown => drawingReps >= knownThreshold;
}

/// Status of one direction's cards for a character, collapsing that
/// direction's card type(s) into one value (known if *any* is known, missed
/// if none are known but at least one has been attempted, none if never
/// attempted) -- the statistics screen is where the precise per-cardType
/// counts live.
enum CardProgress { none, missed, known }

/// Coarse per-character progress signal for the kanji browser's grid
/// indicator, split into the two directions a learner practices
/// independently: reading (readingCloze -- recognize the kanji, produce the
/// reading) and writing (drawInSentence + drawFromMeaning -- produce the
/// kanji itself, whether from context or from meaning). Kept separate
/// rather than collapsed into one status, since a character can be solid in
/// one direction and never attempted in the other.
class KanjiProgress {
  final CardProgress reading;
  final CardProgress writing;

  const KanjiProgress({required this.reading, required this.writing});
}

/// Reorders [cards] so cards for the same character aren't adjacent when
/// avoidable, round-robining across characters in their first-seen order
/// instead of leaving them clustered together -- which they otherwise
/// would be, since a character's several card types are typically
/// introduced with the same dueDate (see
/// ReviewRepository.introduceNewCards) and so naturally sort next to each
/// other. Only forced adjacent when one character has strictly more cards
/// left than every other character combined has remaining -- an
/// unavoidable consequence of the data, not a bug in the interleaving.
/// Pulled out as a standalone function (rather than inline in dueCards)
/// since it's pure list reordering with no DB dependency, easy to unit
/// test in isolation.
List<ReviewCard> interleaveByCharacter(List<ReviewCard> cards) {
  final byCharacter = <String, List<ReviewCard>>{};
  for (final card in cards) {
    byCharacter.putIfAbsent(card.character, () => []).add(card);
  }
  final queues = byCharacter.values.toList();
  final result = <ReviewCard>[];
  while (queues.isNotEmpty) {
    for (final queue in List.of(queues)) {
      if (queue.isEmpty) {
        queues.remove(queue);
        continue;
      }
      result.add(queue.removeAt(0));
    }
  }
  return result;
}

/// Snapshot of a card's SM-2 state before grading, used to undo a grade.
/// [dbRow] is null when the card didn't exist yet (brand-new introduction).
class CardStateSnapshot {
  final double? easeFactor;
  final int? intervalDays;
  final int? repetitions;
  final DateTime? dueDate;
  final DateTime? lastReviewedAt;
  final int? lapses;

  /// True when the card had no prior DB row (first-ever grade).
  bool get isNew => dueDate == null;

  const CardStateSnapshot({
    this.easeFactor,
    this.intervalDays,
    this.repetitions,
    this.dueDate,
    this.lastReviewedAt,
    this.lapses,
  });
}

/// Drift-backed queries composing [StudyScope] filtering with the SM-2
/// algorithm in sm2.dart. This is the only place that reads/writes
/// review_cards and review_log -- sm2.dart itself never touches the DB.
class ReviewRepository {
  final AppDatabase db;

  ReviewRepository(this.db);

  /// A card is reviewable once its SM-2 due date has arrived (standard
  /// SM-2 behavior). After a first successful review the interval is 1 day,
  /// so the card reappears tomorrow -- not immediately in the same session.
  Expression<bool> _dueExpr(DateTime today) =>
      db.reviewCards.dueDate.isSmallerOrEqualValue(today);

  /// Restricts to [cardTypes] when given -- used for filtering (core/
  /// composita/both) to gate not just which new cards get introduced but
  /// also which already-introduced due cards actually appear in a
  /// focused session.
  Expression<bool>? _cardTypesExpr(Set<CardType>? cardTypes) {
    if (cardTypes == null) return null;
    return cardTypes
        .map((t) => db.reviewCards.cardType.equalsValue(t))
        .reduce((a, b) => a | b);
  }

  /// Existing due cards (see [_dueExpr]) within [scope]. Which cards make
  /// it into the batch is decided oldest-due-date-first (so a backlog
  /// surfaces its most-overdue cards, not an arbitrary subset) -- but the
  /// returned ORDER is then interleaved by
  /// character (see [interleaveByCharacter]) rather than left in that raw
  /// due-date order, so a character's several card types (typically
  /// introduced together, same dueDate) don't show up back-to-back. An
  /// empty scope (nothing selected) deliberately returns nothing rather
  /// than "everything" -- see StudyScope's own doc comment.
  /// When [excludeNeverReviewed] is true, cards with `lastReviewedAt IS
  /// NULL` are excluded -- used to load only genuine reviews, then merge
  /// freshly introduced new cards separately (Anki-like daily-cap logic).
  Future<List<ReviewCard>> dueCards(
    StudyScope scope, {
    DateTime? asOf,
    Set<CardType>? cardTypes,
    bool excludeNeverReviewed = false,
  }) async {
    if (scope.isEmpty) return [];
    final today = asOf ?? DateTime.now();

    final query =
        db.select(db.reviewCards).join([
          innerJoin(
            db.kanjiStatic,
            db.kanjiStatic.character.equalsExp(db.reviewCards.character),
          ),
        ])
        ..where(_dueExpr(today))
        ..where(_scopeExpr(scope))
        ..orderBy([OrderingTerm.asc(db.reviewCards.dueDate)]);
    final cardTypesExpr = _cardTypesExpr(cardTypes);
    if (cardTypesExpr != null) query.where(cardTypesExpr);
    if (excludeNeverReviewed) {
      query.where(db.reviewCards.lastReviewedAt.isNotNull());
    }

    final rows = await query.get();
    final cards = rows.map((row) => row.readTable(db.reviewCards)).toList();
    return interleaveByCharacter(cards);
  }

  /// All cards that have been introduced but never reviewed -- these need
  /// to be merged into the review queue alongside genuine reviews so the
  /// user always sees cards they've been shown in the slideshow.
  Future<List<ReviewCard>> cardsNeverReviewed(
    StudyScope scope, {
    Set<CardType>? cardTypes,
  }) async {
    if (scope.isEmpty) return [];
    final today = DateTime.now();
    final query =
        db.select(db.reviewCards).join([
          innerJoin(
            db.kanjiStatic,
            db.kanjiStatic.character.equalsExp(db.reviewCards.character),
          ),
        ])
        ..where(db.reviewCards.lastReviewedAt.isNull())
        ..where(_dueExpr(today))
        ..where(_scopeExpr(scope));
    final cardTypesExpr = _cardTypesExpr(cardTypes);
    if (cardTypesExpr != null) query.where(cardTypesExpr);
    final rows = await query.get();
    return rows.map((row) => row.readTable(db.reviewCards)).toList();
  }

  /// Loads the cards for characters freshly introduced by
  /// [introduceNewCards] -- these have `lastReviewedAt IS NULL` and need
  /// to be merged into the review queue alongside genuine reviews.
  Future<List<ReviewCard>> cardsForCharacters(
    Set<String> characters, {
    Set<CardType>? cardTypes,
    DateTime? asOf,
  }) async {
    if (characters.isEmpty) return [];
    final today = asOf ?? DateTime.now();
    final query = db.select(db.reviewCards)
      ..where((r) => r.character.isIn(characters))
      ..where((r) => r.dueDate.isSmallerOrEqualValue(today));
    if (cardTypes != null) {
      query.where(
        (r) => cardTypes
            .map((t) => r.cardType.equalsValue(t))
            .reduce((a, b) => a | b),
      );
    }
    return query.get();
  }

  /// Count of due cards within [scope], read-only
  /// (unlike [dueCards]' sibling [introduceNewCards], this never inserts
  /// anything) -- for a pre-review "how many elements to review" preview
  /// that can be recomputed freely as the user tweaks scope without side
  /// effects.
  Future<int> countDueCards(
    StudyScope scope, {
    DateTime? asOf,
    Set<CardType>? cardTypes,
  }) async {
    if (scope.isEmpty) return 0;
    final today = asOf ?? DateTime.now();
    final count = countAll();

    final query =
        db.selectOnly(db.reviewCards)
          ..addColumns([count])
          ..join([
            innerJoin(
              db.kanjiStatic,
              db.kanjiStatic.character.equalsExp(db.reviewCards.character),
            ),
          ])
          ..where(_dueExpr(today))
          ..where(_scopeExpr(scope));
    final cardTypesExpr = _cardTypesExpr(cardTypes);
    if (cardTypesExpr != null) query.where(cardTypesExpr);

    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Returns the distinct characters that have at least one due card
  /// within [scope] -- for previewing which kanji are up for review
  /// without loading full card objects.
  Future<List<String>> dueCharacters(
    StudyScope scope, {
    DateTime? asOf,
    Set<CardType>? cardTypes,
  }) async {
    if (scope.isEmpty) return [];
    final today = asOf ?? DateTime.now();
    final charCol = db.reviewCards.character;

    final query =
        db.selectOnly(db.reviewCards, distinct: true)
          ..addColumns([charCol])
          ..join([
            innerJoin(
              db.kanjiStatic,
              db.kanjiStatic.character.equalsExp(db.reviewCards.character),
            ),
          ])
          ..where(_dueExpr(today))
          ..where(_scopeExpr(scope));
    final cardTypesExpr = _cardTypesExpr(cardTypes);
    if (cardTypesExpr != null) query.where(cardTypesExpr);

    final rows = await query.get();
    return rows.map((row) => row.read(charCol)!).toList();
  }

  /// Counts distinct characters in [scope] that have at least one
  /// review_cards row (i.e. have been introduced / seen at least once).
  /// The complement against the total scope size gives the "unseen" count.
  Future<int> countSeenCharacters(StudyScope scope) async {
    if (scope.isEmpty) return 0;
    final charCol = db.reviewCards.character;
    final distinctCount = charCol.count(distinct: true);

    final query =
        db.selectOnly(db.reviewCards)
          ..addColumns([distinctCount])
          ..join([
            innerJoin(
              db.kanjiStatic,
              db.kanjiStatic.character.equalsExp(db.reviewCards.character),
            ),
          ])
          ..where(_scopeExpr(scope));

    final row = await query.getSingle();
    return row.read(distinctCount) ?? 0;
  }

  /// Creates up to [limit] fresh review_cards rows (due today) for
  /// in-scope characters that don't have a [cardType] card yet -- the
  /// daily new-card intake, kept separate from [dueCards] so a fresh
  /// install doesn't dump the entire in-scope universe into day one.
  ///
  /// [restrictToCharacters], when given, further limits candidates to that
  /// set -- used for readingCloze/drawInSentence, which additionally need
  /// sentence coverage (not every character has one); the caller computes
  /// that set by cross-referencing composita + sentences, since this
  /// repository has no knowledge of either.
  Future<List<String>> introduceNewCards(
    StudyScope scope,
    CardType cardType, {
    int limit = 10,
    Set<String>? restrictToCharacters,
  }) async {
    if (scope.isEmpty) return [];
    if (restrictToCharacters != null && restrictToCharacters.isEmpty) return [];

    final query =
        db.select(db.kanjiStatic).join([
          leftOuterJoin(
            db.reviewCards,
            db.reviewCards.character.equalsExp(db.kanjiStatic.character) &
                db.reviewCards.cardType.equalsValue(cardType),
          ),
        ])
        ..where(db.reviewCards.character.isNull())
        ..where(_scopeExpr(scope));
    if (restrictToCharacters != null) {
      query.where(db.kanjiStatic.character.isIn(restrictToCharacters));
    }
    // Introduce kanji in RTK (Remembering the Kanji) order -- it starts
    // with numbers, then builds progressively on shared radicals, which
    // is a better learning sequence than raw newspaper frequency.
    // Characters without an RTK index come last.
    query
      ..orderBy([
        OrderingTerm.asc(db.kanjiStatic.rtkIndex, nulls: NullsOrder.last),
      ])
      ..limit(limit);

    final rows = await query.get();
    final characters = rows
        .map((row) => row.readTable(db.kanjiStatic).character)
        .toList();
    if (characters.isEmpty) return characters;

    final now = DateTime.now();
    await db.batch((b) {
      b.insertAll(
        db.reviewCards,
        characters.map(
          (char) => ReviewCardsCompanion.insert(
            character: char,
            cardType: cardType,
            dueDate: now,
          ),
        ),
      );
    });
    return characters;
  }

  /// Creates one card per (character, word) pair for composita card types
  /// (readingCloze/drawInSentence). Unlike [introduceNewCards] which creates
  /// one card per character, this creates one per composita word so each
  /// word gets independent SM-2 scheduling. [wordsByCharacter] maps each
  /// character to its eligible composita words (the caller resolves this
  /// via sentence_selection.dart's eligibleComposita). Only characters in
  /// [restrictToCharacters] (when given) are considered, and at most
  /// [characterLimit] characters are processed.
  Future<Set<String>> introduceNewCompositaCards(
    StudyScope scope,
    CardType cardType, {
    required Map<String, List<String>> wordsByCharacter,
    int characterLimit = 10,
    Set<String>? restrictToCharacters,
  }) async {
    if (scope.isEmpty) return {};
    if (wordsByCharacter.isEmpty) return {};

    // Find characters that are in scope and don't yet have ANY card of this
    // type (fresh introduction only -- characters that already have at least
    // one composita card for this type are skipped entirely, since their
    // individual words were already introduced).
    final query =
        db.select(db.kanjiStatic).join([
          leftOuterJoin(
            db.reviewCards,
            db.reviewCards.character.equalsExp(db.kanjiStatic.character) &
                db.reviewCards.cardType.equalsValue(cardType),
          ),
        ])
        ..where(db.reviewCards.character.isNull())
        ..where(_scopeExpr(scope));
    if (restrictToCharacters != null) {
      query.where(db.kanjiStatic.character.isIn(restrictToCharacters));
    }
    query.where(db.kanjiStatic.character.isIn(wordsByCharacter.keys));
    query
      ..orderBy([
        OrderingTerm.asc(db.kanjiStatic.rtkIndex, nulls: NullsOrder.last),
      ])
      ..limit(characterLimit);

    final rows = await query.get();
    final characters = rows
        .map((row) => row.readTable(db.kanjiStatic).character)
        .toList();
    if (characters.isEmpty) return {};

    final now = DateTime.now();
    final introduced = <String>{};
    await db.batch((b) {
      for (final char in characters) {
        final words = wordsByCharacter[char];
        if (words == null || words.isEmpty) continue;
        introduced.add(char);
        b.insertAll(
          db.reviewCards,
          words.map(
            (word) => ReviewCardsCompanion.insert(
              character: char,
              cardType: cardType,
              compositaWord: Value(word),
              dueDate: now,
            ),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
    return introduced;
  }

  /// The next [limit] characters that WOULD be introduced for [scope] and
  /// [cardType] -- read-only preview (no inserts), same candidate-selection
  /// and RTK ordering as [introduceNewCards]. Used by ReviewStartScreen to
  /// show which kanji the user is about to learn.
  Future<List<String>> previewIntroducible(
    StudyScope scope,
    CardType cardType, {
    int limit = 10,
    Set<String>? restrictToCharacters,
  }) async {
    if (scope.isEmpty) return [];
    if (restrictToCharacters != null && restrictToCharacters.isEmpty) return [];

    final query =
        db.select(db.kanjiStatic).join([
          leftOuterJoin(
            db.reviewCards,
            db.reviewCards.character.equalsExp(db.kanjiStatic.character) &
                db.reviewCards.cardType.equalsValue(cardType),
          ),
        ])
        ..where(db.reviewCards.character.isNull())
        ..where(_scopeExpr(scope));
    if (restrictToCharacters != null) {
      query.where(db.kanjiStatic.character.isIn(restrictToCharacters));
    }
    query
      ..orderBy([
        OrderingTerm.asc(db.kanjiStatic.rtkIndex, nulls: NullsOrder.last),
      ])
      ..limit(limit);

    final rows = await query.get();
    return rows
        .map((row) => row.readTable(db.kanjiStatic).character)
        .toList();
  }

  /// How many more [cardType] cards COULD be introduced for [scope] beyond
  /// whatever's already been introduced -- read-only (unlike
  /// [introduceNewCards], never inserts anything), mirroring its own
  /// candidate-selection query without the [limit]. Lets the review
  /// session offer an explicit "learn more today" once the daily cap is
  /// reached, with an honest count instead of a blind button.
  Future<int> countIntroducible(
    StudyScope scope,
    CardType cardType, {
    Set<String>? restrictToCharacters,
  }) async {
    if (scope.isEmpty) return 0;
    if (restrictToCharacters != null && restrictToCharacters.isEmpty) return 0;

    final count = countAll();
    final query =
        db.selectOnly(db.kanjiStatic)
          ..addColumns([count])
          ..join([
            leftOuterJoin(
              db.reviewCards,
              db.reviewCards.character.equalsExp(db.kanjiStatic.character) &
                  db.reviewCards.cardType.equalsValue(cardType),
            ),
          ])
          ..where(db.reviewCards.character.isNull())
          ..where(_scopeExpr(scope));
    if (restrictToCharacters != null) {
      query.where(db.kanjiStatic.character.isIn(restrictToCharacters));
    }

    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Grades a card: computes the next SM-2 state, updates review_cards, and
  /// appends a review_log entry. Works for both existing and (defensively)
  /// not-yet-introduced cards. [compositaWord] identifies the specific
  /// composita word for C/D card types (empty for core A/B cards).
  Future<void> gradeCard({
    required String character,
    required CardType cardType,
    required int quality,
    String compositaWord = '',
    DateTime? now,
  }) async {
    final today = now ?? DateTime.now();
    final existing =
        await (db.select(db.reviewCards)..where(
              (t) =>
                  t.character.equals(character) &
                  t.cardType.equalsValue(cardType) &
                  t.compositaWord.equals(compositaWord),
            ))
            .getSingleOrNull();

    final currentState = existing == null
        ? null
        : Sm2State(
            easeFactor: existing.easeFactor,
            intervalDays: existing.intervalDays,
            repetitions: existing.repetitions,
          );
    final next = computeNextReview(currentState, quality);
    final dueDate = today.add(Duration(days: next.intervalDays));
    final wasEstablished = (existing?.repetitions ?? 0) > 0;
    final lapses = (quality < 3 && wasEstablished)
        ? (existing!.lapses + 1)
        : (existing?.lapses ?? 0);

    await db
        .into(db.reviewCards)
        .insertOnConflictUpdate(
          ReviewCardsCompanion.insert(
            character: character,
            cardType: cardType,
            compositaWord: Value(compositaWord),
            easeFactor: Value(next.easeFactor),
            intervalDays: Value(next.intervalDays),
            repetitions: Value(next.repetitions),
            dueDate: dueDate,
            lastReviewedAt: Value(today),
            lapses: Value(lapses),
          ),
        );

    await db
        .into(db.reviewLog)
        .insert(
          ReviewLogCompanion.insert(
            character: character,
            cardType: cardType,
            compositaWord: Value(compositaWord),
            reviewedAt: today,
            quality: quality,
            resultingIntervalDays: next.intervalDays,
          ),
        );
  }

  /// Reads the current SM-2 state for a card, returning null if the card
  /// has never been introduced. Used to snapshot state before grading so
  /// an undo can restore it.
  Future<CardStateSnapshot> getCardState({
    required String character,
    required CardType cardType,
    String compositaWord = '',
  }) async {
    final existing =
        await (db.select(db.reviewCards)..where(
              (t) =>
                  t.character.equals(character) &
                  t.cardType.equalsValue(cardType) &
                  t.compositaWord.equals(compositaWord),
            ))
            .getSingleOrNull();
    if (existing == null) return const CardStateSnapshot();
    return CardStateSnapshot(
      easeFactor: existing.easeFactor,
      intervalDays: existing.intervalDays,
      repetitions: existing.repetitions,
      dueDate: existing.dueDate,
      lastReviewedAt: existing.lastReviewedAt,
      lapses: existing.lapses,
    );
  }

  /// Reverses a single [gradeCard] call: restores the card's SM-2 state
  /// from [snapshot] and deletes the most recent review_log entry for
  /// that card.
  Future<void> undoGrade({
    required String character,
    required CardType cardType,
    String compositaWord = '',
    required CardStateSnapshot snapshot,
  }) async {
    if (snapshot.isNew) {
      // Card didn't exist before grading -- delete the row entirely.
      await (db.delete(db.reviewCards)..where(
            (t) =>
                t.character.equals(character) &
                t.cardType.equalsValue(cardType) &
                t.compositaWord.equals(compositaWord),
          ))
          .go();
    } else {
      // Restore the previous state.
      await db
          .into(db.reviewCards)
          .insertOnConflictUpdate(
            ReviewCardsCompanion.insert(
              character: character,
              cardType: cardType,
              compositaWord: Value(compositaWord),
              easeFactor: Value(snapshot.easeFactor!),
              intervalDays: Value(snapshot.intervalDays!),
              repetitions: Value(snapshot.repetitions!),
              dueDate: snapshot.dueDate!,
              lastReviewedAt: Value(snapshot.lastReviewedAt),
              lapses: Value(snapshot.lapses!),
            ),
          );
    }

    // Delete the most recent review_log entry for this card.
    final latestLog =
        await (db.select(db.reviewLog)..where(
              (t) =>
                  t.character.equals(character) &
                  t.cardType.equalsValue(cardType) &
                  t.compositaWord.equals(compositaWord),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.id)])
            ..limit(1))
            .getSingleOrNull();
    if (latestLog != null) {
      await (db.delete(db.reviewLog)..where(
            (t) => t.id.equals(latestLog.id),
          ))
          .go();
    }
  }

  /// Returns the subset of [characters] that have at least one review_cards
  /// row with lastReviewedAt set (i.e. have actually been reviewed, not just
  /// introduced). Used to filter quiz questions to only cover kanji the user
  /// has practiced.
  Future<Set<String>> seenCharacters(Set<String> characters) async {
    if (characters.isEmpty) return {};
    final rows = await (db.select(db.reviewCards)..where(
          (t) => t.character.isIn(characters) & t.lastReviewedAt.isNotNull(),
        ))
        .get();
    return rows.map((r) => r.character).toSet();
  }

  /// Counts how many cards were reviewed today (lastReviewedAt >= start of
  /// today). Used to track daily review limits across sessions.
  Future<int> countReviewedToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final rows = await (db.select(db.reviewCards)..where(
          (t) => t.lastReviewedAt.isBiggerOrEqualValue(startOfDay),
        ))
        .get();
    return rows.length;
  }

  /// [characters] is the kanji universe to report against -- typically the
  /// current StudyScope's own in-scope set (see the Learning section's
  /// per-mode Statistics), so the screen reads as progress for whatever's
  /// actually being studied rather than the whole ~2,140-kanji deck.
  Future<CardTypeStats> statsFor(
    CardType cardType,
    Set<String> characters,
  ) async {
    if (characters.isEmpty) {
      return const CardTypeStats(known: 0, missed: 0, notStarted: 0);
    }
    final rows = await (db.select(db.reviewCards)..where(
          (t) =>
              t.cardType.equalsValue(cardType) & t.character.isIn(characters),
        ))
        .get();
    // Group by character. "Known" = at least one card has been answered
    // correctly knownThreshold times in a row (repetitions >= 2). A fail
    // (quality < 3) resets repetitions to 0 via SM-2, so the user must
    // pass the card 2 consecutive times to earn "known". "Learning" =
    // reviewed but not yet at the threshold. "Not started" = never reviewed.
    const knownThreshold = 2;
    final byChar = <String, List<ReviewCard>>{};
    for (final r in rows) {
      byChar.putIfAbsent(r.character, () => []).add(r);
    }
    var known = 0;
    var missed = 0;
    for (final entry in byChar.entries) {
      final reviewed = entry.value.any((r) => r.lastReviewedAt != null);
      if (!reviewed) continue; // introduced but never reviewed
      final learnt = entry.value.any((r) => r.repetitions >= knownThreshold);
      if (learnt) {
        known++;
      } else {
        missed++;
      }
    }
    return CardTypeStats(
      known: known,
      missed: missed,
      notStarted: characters.length - byChar.length,
    );
  }

  /// Deletes a single review card by its composite primary key.
  Future<void> deleteCard(ReviewCard card) async {
    await (db.delete(db.reviewCards)
          ..where((t) =>
              t.character.equals(card.character) &
              t.cardType.equalsValue(card.cardType) &
              t.compositaWord.equals(card.compositaWord)))
        .go();
  }

  /// Wipes all review progress (every card's SM-2 state and the review
  /// log) -- deliberately leaves kanji_notes (personal stories) and
  /// kanji_static (reference data) untouched.
  Future<void> resetAllProgress() async {
    await db.delete(db.reviewCards).go();
    await db.delete(db.reviewLog).go();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('review.slideshow_shown');
  }

  /// character -> coarse progress, for the kanji browser grid's indicator.
  /// Characters absent from the result have no review history in either
  /// direction at all.
  ///
  /// "Green" is deliberately simple: reading = [CardType.kanjiRecognition]
  /// (kanji shown, recall reading + meaning), writing =
  /// [CardType.drawFromMeaning] (meaning shown, draw the kanji) -- each its
  /// own single-cardType known/missed/none check, no composita or sentence
  /// cross-referencing. [CardType.readingCloze]/[CardType.drawInSentence]
  /// (composita/sentence testing, "C+D") are tracked separately via
  /// [CompositaProgress] and never gate this.
  Future<Map<String, KanjiProgress>> overallProgress() async {
    const knownThreshold = 2;
    final rows = await db.select(db.reviewCards).get();
    final reading = <String, CardProgress>{};
    final writing = <String, CardProgress>{};
    for (final row in rows) {
      final Map<String, CardProgress>? bucket = switch (row.cardType) {
        CardType.kanjiRecognition => reading,
        CardType.drawFromMeaning => writing,
        CardType.readingCloze || CardType.drawInSentence => null,
      };
      if (bucket == null) continue;
      if (row.repetitions >= knownThreshold) {
        bucket[row.character] = CardProgress.known;
      } else if (row.lastReviewedAt != null &&
          bucket[row.character] != CardProgress.known) {
        bucket[row.character] = CardProgress.missed;
      }
    }

    return {
      for (final char in {...reading.keys, ...writing.keys})
        char: KanjiProgress(
          reading: reading[char] ?? CardProgress.none,
          writing: writing[char] ?? CardProgress.none,
        ),
    };
  }

  /// Per-character detail for the statistics dialog: how many consecutive
  /// correct answers the character has for each core direction (A/B), and
  /// whether it's been started at all. Used by the tap-to-inspect dialog.
  Future<KanjiProgressDetail> detailedProgressFor(
    String character, {
    Set<String> eligibleWords = const {},
  }) async {
    final rows = await (db.select(db.reviewCards)..where(
          (t) => t.character.equals(character),
        ))
        .get();

    int recognitionReps = 0;
    bool recognitionStarted = false;
    int drawingReps = 0;
    bool drawingStarted = false;

    for (final row in rows) {
      if (row.cardType == CardType.kanjiRecognition) {
        recognitionReps = row.repetitions;
        recognitionStarted = row.lastReviewedAt != null;
      } else if (row.cardType == CardType.drawFromMeaning) {
        drawingReps = row.repetitions;
        drawingStarted = row.lastReviewedAt != null;
      }
    }

    int compositaTestable = eligibleWords.length;
    int compositaReadingTested = 0;
    int compositaWritingTested = 0;

    if (eligibleWords.isNotEmpty) {
      final chars = {character};
      final testedReading = await testedCompositaWordsFor(
        chars,
        CompositaDirection.reading,
      );
      final testedWriting = await testedCompositaWordsFor(
        chars,
        CompositaDirection.writing,
      );
      final readingDone = testedReading[character] ?? const {};
      final writingDone = testedWriting[character] ?? const {};
      compositaReadingTested =
          eligibleWords.where(readingDone.contains).length;
      compositaWritingTested =
          eligibleWords.where(writingDone.contains).length;
    }

    return KanjiProgressDetail(
      recognitionReps: recognitionReps,
      drawingReps: drawingReps,
      recognitionStarted: recognitionStarted,
      drawingStarted: drawingStarted,
      compositaTestable: compositaTestable,
      compositaReadingTested: compositaReadingTested,
      compositaWritingTested: compositaWritingTested,
    );
  }

  /// Records that [word]'s [direction] (as tested for [character]) has been
  /// passed -- upsert, since only the first pass matters for "has this
  /// direction ever been covered". This is the "C+D" tracking store (see
  /// [CompositaProgress]'s own doc comment) -- purely informational for
  /// Statistics, never gates [overallProgress]'s green computation.
  Future<void> recordCompositaTested(
    String character,
    String word,
    CompositaDirection direction, {
    DateTime? now,
  }) async {
    await db
        .into(db.compositaProgress)
        .insertOnConflictUpdate(
          CompositaProgressCompanion.insert(
            character: character,
            word: word,
            direction: direction,
            firstPassedAt: now ?? DateTime.now(),
          ),
        );
  }

  /// character -> set of composita words already passed at least once in
  /// [direction] -- batched (rather than one query per character) for the
  /// review session's up-front load of its whole queue.
  Future<Map<String, Set<String>>> testedCompositaWordsFor(
    Set<String> characters,
    CompositaDirection direction,
  ) async {
    if (characters.isEmpty) return {};
    final rows = await (db.select(db.compositaProgress)..where(
          (t) => t.character.isIn(characters) & t.direction.equalsValue(direction),
        ))
        .get();
    final result = <String, Set<String>>{};
    for (final row in rows) {
      result.putIfAbsent(row.character, () => {}).add(row.word);
    }
    return result;
  }

  /// Among [wordsByCharacter] (character -> its testable composita words
  /// under whatever scope the caller resolved -- see
  /// sentence_selection.dart's eligibleComposita), how many have been
  /// tested at least once, per direction. Statistics-only; see
  /// [CompositaCoverage]'s own doc comment.
  Future<CompositaCoverage> compositaProgressFor(
    Map<String, Set<String>> wordsByCharacter,
  ) async {
    final characters = wordsByCharacter.keys.toSet();
    final testedReading = await testedCompositaWordsFor(
      characters,
      CompositaDirection.reading,
    );
    final testedWriting = await testedCompositaWordsFor(
      characters,
      CompositaDirection.writing,
    );
    var testable = 0;
    var readingCount = 0;
    var writingCount = 0;
    for (final entry in wordsByCharacter.entries) {
      testable += entry.value.length;
      final readingDone = testedReading[entry.key] ?? const {};
      final writingDone = testedWriting[entry.key] ?? const {};
      readingCount += entry.value.where(readingDone.contains).length;
      writingCount += entry.value.where(writingDone.contains).length;
    }
    return CompositaCoverage(
      testable: testable,
      testedReading: readingCount,
      testedWriting: writingCount,
    );
  }

  /// Attaches [word] as one of [character]'s explicitly-selected composita
  /// in the custom study set (see StudyScopeMode.custom) -- idempotent, a
  /// second call for the same pair is a no-op.
  Future<void> addCustomComposita(String character, String word) async {
    await db
        .into(db.customComposita)
        .insertOnConflictUpdate(
          CustomCompositaCompanion.insert(character: character, word: word),
        );
  }

  Future<void> removeCustomComposita(String character, String word) async {
    await (db.delete(db.customComposita)..where(
          (t) => t.character.equals(character) & t.word.equals(word),
        ))
        .go();
  }

  /// The words explicitly selected for [character] in the custom set --
  /// empty until the user picks any (see custom_edit_screen.dart), which
  /// also means no composita/sentence (C+D) testing happens for that
  /// character yet: unlike JLPT mode's ceiling, there's no "unrestricted"
  /// fallback here -- custom mode's whole point is a hand-picked list.
  Future<Set<String>> customCompositaFor(String character) async {
    final rows = await (db.select(
      db.customComposita,
    )..where((t) => t.character.equals(character))).get();
    return rows.map((r) => r.word).toSet();
  }

  /// Batched form of [customCompositaFor] for several characters at once --
  /// same "one query instead of N" reasoning as [testedCompositaWordsFor].
  Future<Map<String, Set<String>>> customCompositaForCharacters(
    Set<String> characters,
  ) async {
    if (characters.isEmpty) return {};
    final rows = await (db.select(
      db.customComposita,
    )..where((t) => t.character.isIn(characters))).get();
    final result = <String, Set<String>>{};
    for (final row in rows) {
      result.putIfAbsent(row.character, () => {}).add(row.word);
    }
    return result;
  }

  Stream<String> watchNote(String character) {
    final query = db.select(db.kanjiNotes)
      ..where((t) => t.character.equals(character));
    return query.watchSingleOrNull().map((row) => row?.story ?? '');
  }

  /// A plain one-shot read, not a Stream -- for call sites that just need
  /// the current value once (e.g. re-fetching per review card) rather than
  /// a live subscription. Deliberately not `watchNote(...).first`: that
  /// still opens and cancels a drift query stream, whose cleanup schedules
  /// a timer that can outlive a widget test's tear-down and trip
  /// flutter_test's "pending timer" check.
  Future<String> getNote(String character) async {
    final row = await (db.select(
      db.kanjiNotes,
    )..where((t) => t.character.equals(character))).getSingleOrNull();
    return row?.story ?? '';
  }

  Future<void> upsertNote(String character, String story) async {
    await db
        .into(db.kanjiNotes)
        .insertOnConflictUpdate(
          KanjiNotesCompanion.insert(
            character: character,
            story: Value(story),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// The short recall-cue keyword, kept separate from the fuller [getNote]
  /// story -- shown as a pre-draw hint (e.g. in a drawFromMeaning review
  /// card) where the full story would give too much away.
  Future<String> getStoryKeyword(String character) async {
    final row = await (db.select(
      db.kanjiNotes,
    )..where((t) => t.character.equals(character))).getSingleOrNull();
    return row?.storyKeyword ?? '';
  }

  /// All story keywords in one query, keyed by character -- for a screen
  /// that lists every kanji at once (see kanji_browser_screen.dart) rather
  /// than one card at a time, where a per-character [getStoryKeyword] await
  /// would mean ~2,140 individual queries. Characters with no note row (or
  /// an empty keyword) are simply absent from the map.
  Future<Map<String, String>> allStoryKeywords() async {
    final rows = await db.select(db.kanjiNotes).get();
    final result = <String, String>{};
    for (final row in rows) {
      if (row.storyKeyword.isNotEmpty) result[row.character] = row.storyKeyword;
    }
    return result;
  }

  /// Returns the earliest card dueDate per character (approximates "date added
  /// to pool", since cards are created with dueDate=now at add time).
  Future<Map<String, DateTime>> addedDates() async {
    final rows = await db.select(db.reviewCards).get();
    final result = <String, DateTime>{};
    for (final row in rows) {
      final existing = result[row.character];
      if (existing == null || row.dueDate.isBefore(existing)) {
        result[row.character] = row.dueDate;
      }
    }
    return result;
  }

  /// Returns the latest modification date per character, considering
  /// KanjiNotes.updatedAt (story/keyword edits).
  Future<Map<String, DateTime>> modifiedDates() async {
    final rows = await db.select(db.kanjiNotes).get();
    final result = <String, DateTime>{};
    for (final row in rows) {
      if (row.updatedAt != null) {
        result[row.character] = row.updatedAt!;
      }
    }
    return result;
  }

  Future<void> upsertStoryKeyword(String character, String keyword) async {
    await db
        .into(db.kanjiNotes)
        .insertOnConflictUpdate(
          KanjiNotesCompanion.insert(
            character: character,
            storyKeyword: Value(keyword),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Returns the set of in-scope characters that have a [cardType] card with
  /// repetitions > 0 (i.e. passed at least once). Used to gate introduction
  /// order: a character's A card must be passed before B is introduced, and
  /// B before C+D.
  Future<Set<String>> charactersWithPassedCard(
    StudyScope scope,
    CardType cardType,
  ) async {
    if (scope.isEmpty) return {};
    final query =
        db.select(db.reviewCards).join([
          innerJoin(
            db.kanjiStatic,
            db.kanjiStatic.character.equalsExp(db.reviewCards.character),
          ),
        ])
        ..where(db.reviewCards.cardType.equalsValue(cardType))
        ..where(db.reviewCards.repetitions.isBiggerThanValue(0))
        ..where(_scopeExpr(scope));
    final rows = await query.get();
    return rows.map((row) => row.readTable(db.reviewCards).character).toSet();
  }

  // ── User composita (JMdict words added manually by the user) ──────────

  /// Adds a JMdict word as a user composita for [character], and also
  /// auto-enables it in CustomComposita so it's immediately testable.
  Future<void> addUserComposita(
    String character,
    String word,
    String reading,
    String meaning,
  ) async {
    await db
        .into(db.userComposita)
        .insertOnConflictUpdate(
          UserCompositaCompanion.insert(
            character: character,
            word: word,
            reading: reading,
            meaning: meaning,
          ),
        );
    await addCustomComposita(character, word);
  }

  /// Removes a user-added composita word for [character], and also removes
  /// it from CustomComposita (no longer testable).
  Future<void> removeUserComposita(String character, String word) async {
    await (db.delete(db.userComposita)..where(
          (t) => t.character.equals(character) & t.word.equals(word),
        ))
        .go();
    await removeCustomComposita(character, word);
  }

  /// All user-added composita for a single [character], converted to
  /// [Composita] objects with null JLPT levels and high-priority frequency.
  Future<List<Composita>> userCompositaFor(String character) async {
    final rows = await (db.select(
      db.userComposita,
    )..where((t) => t.character.equals(character))).get();
    return rows.map(_userRowToComposita).toList();
  }

  /// Batched form: all user composita grouped by character -- for merging
  /// with the bundled list at session start (same "one query, not N"
  /// reasoning as [customCompositaForCharacters]).
  Future<Map<String, List<Composita>>> allUserCompositaByChar() async {
    final rows = await db.select(db.userComposita).get();
    final result = <String, List<Composita>>{};
    for (final row in rows) {
      result
          .putIfAbsent(row.character, () => [])
          .add(_userRowToComposita(row));
    }
    return result;
  }

  /// Whether [word] was user-added for [character] (for UI state -- show
  /// "Added" vs "Add" in the composita picker / word lookup).
  Future<bool> isUserComposita(String character, String word) async {
    final row = await (db.select(db.userComposita)..where(
          (t) => t.character.equals(character) & t.word.equals(word),
        ))
        .getSingleOrNull();
    return row != null;
  }

  static Composita _userRowToComposita(UserCompositaData row) {
    return Composita(
      word: row.word,
      reading: row.reading,
      meaning: row.meaning,
      jlptLevel: null,
      inferredJlptLevel: null,
      frequencyRank: 1,
    );
  }

  /// Counts of review cards grouped by time bucket relative to [asOf].
  /// Returns a map with keys: "overdue", "today", "tomorrow", "thisWeek",
  /// "later", "notStarted". Only includes cards matching the scope and
  /// card types.
  Future<Map<String, int>> dueDateDistribution(
    StudyScope scope, {
    DateTime? asOf,
    Set<CardType>? cardTypes,
  }) async {
    if (scope.isEmpty) {
      return {
        'overdue': 0,
        'today': 0,
        'tomorrow': 0,
        'thisWeek': 0,
        'later': 0,
        'notStarted': 0,
      };
    }
    final now = asOf ?? DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfToday.add(const Duration(days: 1));
    final startOfDayAfterTomorrow = startOfToday.add(const Duration(days: 2));
    final startOfBeyondWeek = startOfToday.add(const Duration(days: 8));

    // Fetch all review cards in scope.
    final query =
        db.select(db.reviewCards).join([
          innerJoin(
            db.kanjiStatic,
            db.kanjiStatic.character.equalsExp(db.reviewCards.character),
          ),
        ])
        ..where(_scopeExpr(scope));
    final cardTypesExpr = _cardTypesExpr(cardTypes);
    if (cardTypesExpr != null) query.where(cardTypesExpr);

    final rows = await query.get();
    final cards = rows.map((row) => row.readTable(db.reviewCards)).toList();

    var overdue = 0;
    var today = 0;
    var tomorrow = 0;
    var thisWeek = 0;
    var later = 0;

    for (final card in cards) {
      if (card.dueDate.isBefore(startOfToday)) {
        overdue++;
      } else if (card.dueDate.isBefore(startOfTomorrow)) {
        today++;
      } else if (card.dueDate.isBefore(startOfDayAfterTomorrow)) {
        tomorrow++;
      } else if (card.dueDate.isBefore(startOfBeyondWeek)) {
        thisWeek++;
      } else {
        later++;
      }
    }

    // "Not started": characters in scope with no review card at all for
    // the requested card types.
    final seenCharacters = cards.map((c) => c.character).toSet();
    final totalInScope = await _countScopeCharacters(scope);
    final notStarted = totalInScope - seenCharacters.length;

    return {
      'overdue': overdue,
      'today': today,
      'tomorrow': tomorrow,
      'thisWeek': thisWeek,
      'later': later,
      'notStarted': notStarted < 0 ? 0 : notStarted,
    };
  }

  /// Total number of characters matching [scope] in kanji_static.
  Future<int> _countScopeCharacters(StudyScope scope) async {
    final count = countAll();
    final query =
        db.selectOnly(db.kanjiStatic)
          ..addColumns([count])
          ..where(_scopeExpr(scope));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Unified pool: simple set membership against the scope's characters.
  Expression<bool> _scopeExpr(StudyScope scope) {
    return scope.characters.isEmpty
        ? const Constant(false)
        : db.kanjiStatic.character.isIn(scope.characters);
  }

  /// Create C+D cards for a single composita word (if not already present).
  Future<void> introduceCompositaCardsForWord(
    String character,
    String word, {
    DateTime? asOf,
  }) async {
    final now = asOf ?? DateTime.now();
    await db.batch((b) {
      for (final ct in [CardType.readingCloze, CardType.drawInSentence]) {
        b.insert(
          db.reviewCards,
          ReviewCardsCompanion.insert(
            character: character,
            cardType: ct,
            compositaWord: Value(word),
            dueDate: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  /// Delete C+D cards for a single composita word.
  Future<void> deleteCompositaCardsForWord(
    String character,
    String word,
  ) async {
    await (db.delete(db.reviewCards)..where(
          (t) =>
              t.character.equals(character) &
              t.compositaWord.equals(word) &
              (t.cardType.equalsValue(CardType.readingCloze) |
                  t.cardType.equalsValue(CardType.drawInSentence)),
        ))
        .go();
  }

  /// Count of never-reviewed cards within [scope] (introduced but
  /// lastReviewedAt IS NULL). Efficient count query for refreshing the
  /// remaining-beyond-cap display without loading full card objects.
  Future<int> countNeverReviewed(StudyScope scope) async {
    if (scope.isEmpty) return 0;
    final count = countAll();
    final query =
        db.selectOnly(db.reviewCards)
          ..addColumns([count])
          ..join([
            innerJoin(
              db.kanjiStatic,
              db.kanjiStatic.character.equalsExp(db.reviewCards.character),
            ),
          ])
          ..where(db.reviewCards.lastReviewedAt.isNull())
          ..where(db.reviewCards.dueDate.isSmallerOrEqualValue(DateTime.now()))
          ..where(_scopeExpr(scope));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Deletes all review progress for [chars]: ReviewCards, CompositaProgress,
  /// CustomComposita. Leaves kanji_notes (personal stories/keywords) intact.
  Future<void> deleteProgressForCharacters(Set<String> chars) async {
    if (chars.isEmpty) return;
    await (db.delete(db.reviewCards)
          ..where((t) => t.character.isIn(chars)))
        .go();
    await (db.delete(db.reviewLog)
          ..where((t) => t.character.isIn(chars)))
        .go();
    await (db.delete(db.compositaProgress)
          ..where((t) => t.character.isIn(chars)))
        .go();
    await (db.delete(db.customComposita)
          ..where((t) => t.character.isIn(chars)))
        .go();
  }

  // ── User sentences (user-authored example sentences for composita) ────

  /// Adds a user-authored example sentence for [word].
  Future<int> addUserSentence(
    String word,
    String sentence,
    String? translation,
  ) async {
    return db
        .into(db.userSentences)
        .insert(
          UserSentencesCompanion.insert(
            word: word,
            sentence: sentence,
            translation: Value(translation),
          ),
        );
  }

  /// Deletes a single user sentence by its autoIncrement id.
  Future<void> removeUserSentence(int id) async {
    await (db.delete(db.userSentences)..where((t) => t.id.equals(id)))
        .go();
  }

  /// All user sentences for [word], converted to [ExampleSentence] objects
  /// with source 'user'. The [reading] is attached to the target token so
  /// FuriganaSentence can render furigana on the composita word.
  Future<List<({int id, ExampleSentence sentence})>> userSentencesFor(
    String word,
    String reading,
  ) async {
    final rows = await (db.select(db.userSentences)
          ..where((t) => t.word.equals(word)))
        .get();
    return rows
        .map((r) => (
              id: r.id,
              sentence: _tokenizeUserSentence(
                r.sentence,
                word,
                reading,
                translation: r.translation,
              ),
            ))
        .toList();
  }

  /// Batch-loads all user sentences grouped by word -- for the review
  /// session's up-front load so _sentenceForWord can merge them with
  /// bundled sentences without per-card DB round-trips.
  Future<Map<String, List<ExampleSentence>>> allUserSentencesByWord() async {
    final rows = await db.select(db.userSentences).get();
    final result = <String, List<ExampleSentence>>{};
    for (final row in rows) {
      // Reading is unknown here — will be filled in by _sentenceForWord
      // which knows the composita's reading. Store with empty reading for
      // now; the caller replaces the target token's reading.
      result
          .putIfAbsent(row.word, () => [])
          .add(_tokenizeUserSentence(
            row.sentence,
            row.word,
            '', // placeholder — caller fills in the real reading
            translation: row.translation,
          ));
    }
    return result;
  }

  /// Simple string-based tokenization: find [targetWord] in [sentence],
  /// split into before/target/after tokens. No morphological analyzer
  /// needed — sufficient for user-added content.
  static ExampleSentence _tokenizeUserSentence(
    String sentence,
    String targetWord,
    String reading, {
    String? translation,
  }) {
    final idx = sentence.indexOf(targetWord);
    final tokens = <SentenceToken>[];
    if (idx < 0) {
      // Word not found (shouldn't happen with validation, but defensive).
      tokens.add(SentenceToken(
        surface: sentence,
        reading: '',
        isTarget: false,
      ));
      tokens.add(SentenceToken(
        surface: targetWord,
        reading: reading,
        isTarget: true,
      ));
    } else {
      if (idx > 0) {
        tokens.add(SentenceToken(
          surface: sentence.substring(0, idx),
          reading: '',
          isTarget: false,
        ));
      }
      tokens.add(SentenceToken(
        surface: targetWord,
        reading: reading,
        isTarget: true,
      ));
      final afterIdx = idx + targetWord.length;
      if (afterIdx < sentence.length) {
        tokens.add(SentenceToken(
          surface: sentence.substring(afterIdx),
          reading: '',
          isTarget: false,
        ));
      }
    }
    return ExampleSentence(
      sentence: sentence,
      tokens: tokens,
      jlptLevel: 5,
      source: 'user',
      translation: translation,
    );
  }

  /// Creates A+B+C+D cards immediately for [chars] with dueDate=now.
  /// [compositaWordsByChar] maps each character to its eligible composita
  /// words (already resolved by the caller via auto-selection). Characters
  /// that already have cards are skipped (insertOrIgnore).
  Future<void> introduceCardsForCharacters(
    Set<String> chars, {
    Map<String, List<String>> compositaWordsByChar = const {},
    DateTime? asOf,
  }) async {
    if (chars.isEmpty) return;
    final now = asOf ?? DateTime.now();
    await db.batch((b) {
      for (final char in chars) {
        // A: kanjiRecognition
        b.insert(
          db.reviewCards,
          ReviewCardsCompanion.insert(
            character: char,
            cardType: CardType.kanjiRecognition,
            dueDate: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
        // B: drawFromMeaning
        b.insert(
          db.reviewCards,
          ReviewCardsCompanion.insert(
            character: char,
            cardType: CardType.drawFromMeaning,
            dueDate: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
        // C+D: one card per composita word
        final words = compositaWordsByChar[char] ?? const [];
        for (final word in words) {
          b.insert(
            db.reviewCards,
            ReviewCardsCompanion.insert(
              character: char,
              cardType: CardType.readingCloze,
              compositaWord: Value(word),
              dueDate: now,
            ),
            mode: InsertMode.insertOrIgnore,
          );
          b.insert(
            db.reviewCards,
            ReviewCardsCompanion.insert(
              character: char,
              cardType: CardType.drawInSentence,
              compositaWord: Value(word),
              dueDate: now,
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
      }
    });
  }
}
