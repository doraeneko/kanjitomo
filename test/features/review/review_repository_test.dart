import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanjitomo/core/db/app_database.dart';
import 'package:kanjitomo/core/db/tables.dart';
import 'package:kanjitomo/features/review/review_repository.dart';
import 'package:kanjitomo/features/review/study_scope.dart';

void main() {
  late AppDatabase db;
  late ReviewRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ReviewRepository(db);
    await db.syncKanjiStatic(
      jlptLevels: {'一': 5, '二': 5, '三': 4, '四': 3},
      rtkIndex: {'一': 1, '二': 2, '三': 3000, '四': 4000},
      // 一 and 二 are both N5 but rank 0 and 1 within that level respectively
      // (e.g. 一 is more frequent) -- lets chunking tests split them apart.
      levelRank: {'一': 0, '二': 1, '三': 0, '四': 0},
    );
  });

  tearDown(() => db.close());

  test('empty StudyScope returns no due cards, not everything', () async {
    await repo.introduceNewCards(
      const StudyScope(jlptLevels: {5}),
      CardType.drawFromMeaning,
      limit: 10,
    );
    final due = await repo.dueCards(const StudyScope());
    expect(due, isEmpty);
  });

  test('introduceNewCards only creates cards for in-scope, not-yet-seen characters', () async {
    final introduced = await repo.introduceNewCards(
      const StudyScope(jlptLevels: {5}),
      CardType.drawFromMeaning,
      limit: 10,
    );
    expect(introduced.toSet(), {'一', '二'});

    // Calling again should introduce none of the same (character, cardType)
    // pairs a second time.
    final again = await repo.introduceNewCards(
      const StudyScope(jlptLevels: {5}),
      CardType.drawFromMeaning,
      limit: 10,
    );
    expect(again, isEmpty);
  });

  test('introduceNewCards respects the limit (daily intake cap)', () async {
    final introduced = await repo.introduceNewCards(
      const StudyScope(jlptLevels: {5, 4, 3}),
      CardType.drawFromMeaning,
      limit: 1,
    );
    expect(introduced.length, 1);
  });

  test(
    'countIntroducible counts candidates without introducing them, unlike '
    'its sibling introduceNewCards',
    () async {
      // All 4 setUp characters (一,二,三,四) are N3-N5 per setUp, so this
      // scope matches all of them.
      const scope = StudyScope(jlptLevels: {5, 4, 3});
      final before = await repo.countIntroducible(
        scope,
        CardType.drawFromMeaning,
      );
      expect(before, 4);

      // Purely read-only: no rows actually got inserted.
      final cardsAfterCount = await db.select(db.reviewCards).get();
      expect(cardsAfterCount, isEmpty);

      // Introduce just one, then the count should drop to reflect it.
      await repo.introduceNewCards(scope, CardType.drawFromMeaning, limit: 1);
      final after = await repo.countIntroducible(
        scope,
        CardType.drawFromMeaning,
      );
      expect(after, 3);

      // restrictToCharacters narrows it exactly like introduceNewCards.
      final restricted = await repo.countIntroducible(
        scope,
        CardType.readingCloze,
        restrictToCharacters: {'二'},
      );
      expect(restricted, 1);
    },
  );

  test('introduceNewCards restrictToCharacters further narrows candidates', () async {
    final introduced = await repo.introduceNewCards(
      const StudyScope(jlptLevels: {5}),
      CardType.readingCloze,
      limit: 10,
      restrictToCharacters: {'一'},
    );
    expect(introduced, ['一']);

    final none = await repo.introduceNewCards(
      const StudyScope(jlptLevels: {5}),
      CardType.drawFromMeaning,
      limit: 10,
      restrictToCharacters: {},
    );
    expect(none, isEmpty);
  });

  test('rtk-mode scope selects purely by RTK index cutoff', () async {
    final introduced = await repo.introduceNewCards(
      const StudyScope(mode: StudyScopeMode.rtk, rtkMaxIndex: 5),
      CardType.drawFromMeaning,
      limit: 10,
    );
    // rtkIndex <= 5: 一(1), 二(2) -- not 三(3000) or 四(4000).
    expect(introduced.toSet(), {'一', '二'});
  });

  test(
    'dueCards returns cards whose dueDate has arrived, plus still-fragile '
    'cards (repetitions <= 1) regardless of due date',
    () async {
      await repo.introduceNewCards(
        const StudyScope(jlptLevels: {5}),
        CardType.drawFromMeaning,
        limit: 10,
      );
      // Freshly introduced cards are due immediately (dueDate = now).
      final due = await repo.dueCards(const StudyScope(jlptLevels: {5}));
      expect(due.map((c) => c.character).toSet(), {'一', '二'});

      // First success (repetitions 0->1) pushes the due date to tomorrow,
      // but the card stays in the pool anyway -- a card reviewed
      // successfully only once shouldn't vanish from review for weeks.
      await repo.gradeCard(
        character: '一',
        cardType: CardType.drawFromMeaning,
        quality: 5,
      );
      final dueAfterFirstSuccess = await repo.dueCards(
        const StudyScope(jlptLevels: {5}),
      );
      expect(
        dueAfterFirstSuccess.map((c) => c.character),
        contains('一'),
      );

      // Second success (repetitions 1->2): now "established" -- the due
      // date is pushed further out and it finally drops out of the pool.
      await repo.gradeCard(
        character: '一',
        cardType: CardType.drawFromMeaning,
        quality: 5,
      );
      final dueAfterSecondSuccess = await repo.dueCards(
        const StudyScope(jlptLevels: {5}),
      );
      expect(
        dueAfterSecondSuccess.map((c) => c.character),
        isNot(contains('一')),
      );
      expect(dueAfterSecondSuccess.map((c) => c.character), contains('二'));
    },
  );

  test(
    'dueCards interleaves the returned batch by character (see '
    'interleaveByCharacter) rather than leaving same-character cards '
    'clustered by their shared introduction dueDate',
    () async {
      // Both card types get the same dueDate (now) for each character,
      // since introduceNewCards always inserts as "due immediately" --
      // exactly the clustering interleaveByCharacter exists to undo.
      await repo.introduceNewCards(
        const StudyScope(jlptLevels: {5}),
        CardType.drawFromMeaning,
        limit: 10,
      );
      await repo.introduceNewCards(
        const StudyScope(jlptLevels: {5}),
        CardType.kanjiRecognition,
        limit: 10,
      );

      final due = await repo.dueCards(const StudyScope(jlptLevels: {5}));
      expect(due, hasLength(4)); // 一 and 二, x2 card types each

      for (var i = 1; i < due.length; i++) {
        expect(
          due[i].character,
          isNot(due[i - 1].character),
          reason: 'same-character cards should not be adjacent when '
              'another character still has cards left in the batch',
        );
      }
    },
  );

  test('gradeCard persists SM-2 state and appends a review_log entry', () async {
    await repo.introduceNewCards(
      const StudyScope(jlptLevels: {5}),
      CardType.drawFromMeaning,
      limit: 10,
    );
    await repo.gradeCard(
      character: '一',
      cardType: CardType.drawFromMeaning,
      quality: 4,
    );

    final card = await (db.select(
      db.reviewCards,
    )..where((t) => t.character.equals('一'))).getSingle();
    expect(card.repetitions, 1);
    expect(card.intervalDays, 1);
    expect(card.lastReviewedAt, isNotNull);

    final log = await db.select(db.reviewLog).get();
    expect(log, hasLength(1));
    expect(log.first.character, '一');
    expect(log.first.quality, 4);
  });

  test('gradeCard on an established card increments lapses on failure', () async {
    await repo.introduceNewCards(
      const StudyScope(jlptLevels: {5}),
      CardType.drawFromMeaning,
      limit: 10,
    );
    await repo.gradeCard(character: '一', cardType: CardType.drawFromMeaning, quality: 4);
    await repo.gradeCard(character: '一', cardType: CardType.drawFromMeaning, quality: 4);
    await repo.gradeCard(character: '一', cardType: CardType.drawFromMeaning, quality: 1);

    final card = await (db.select(
      db.reviewCards,
    )..where((t) => t.character.equals('一'))).getSingle();
    expect(card.lapses, 1);
    expect(card.repetitions, 0);
  });

  test('custom-mode scope introduces cards only for the chosen set', () async {
    final introduced = await repo.introduceNewCards(
      const StudyScope(
        mode: StudyScopeMode.custom,
        customCharacters: {'一', '三'},
      ),
      CardType.drawFromMeaning,
      limit: 10,
    );
    // Not 二 or 四, even though they're in-scope by JLPT/RTK -- custom mode
    // is an alternative to level-based selection, not unioned with it.
    expect(introduced.toSet(), {'一', '三'});
  });

  test('custom-mode scope with an empty set returns no due cards', () async {
    await repo.introduceNewCards(
      const StudyScope(jlptLevels: {5}),
      CardType.drawFromMeaning,
      limit: 10,
    );
    final due = await repo.dueCards(const StudyScope(mode: StudyScopeMode.custom));
    expect(due, isEmpty);
  });

  test('countDueCards counts only due, in-scope cards without side effects', () async {
    await repo.introduceNewCards(
      const StudyScope(jlptLevels: {5}),
      CardType.drawFromMeaning,
      limit: 10,
    );
    // Both 一 and 二 are freshly introduced (due today) and in scope.
    expect(
      await repo.countDueCards(const StudyScope(jlptLevels: {5})),
      2,
    );
    // A disjoint scope sees none of them.
    expect(
      await repo.countDueCards(const StudyScope(jlptLevels: {1})),
      0,
    );
    // An empty scope is always 0, same convention as dueCards/introduceNewCards.
    expect(await repo.countDueCards(const StudyScope()), 0);

    // Read-only: calling it doesn't introduce or change any cards.
    final cardsAfter = await db.select(db.reviewCards).get();
    expect(cardsAfter, hasLength(2));
  });

  test(
    'dueCards/countDueCards cardTypes restricts to a subset -- powers '
    "ReviewFocus's core/composita/both gating",
    () async {
      const scope = StudyScope(jlptLevels: {5});
      await repo.introduceNewCards(scope, CardType.drawFromMeaning, limit: 10);
      await repo.introduceNewCards(scope, CardType.kanjiRecognition, limit: 10);

      // Unfiltered: both card types' rows (2 characters x 2 types) count.
      expect(await repo.countDueCards(scope), 4);
      expect(await repo.dueCards(scope), hasLength(4));

      // Restricted to just one type: half of them.
      expect(
        await repo.countDueCards(
          scope,
          cardTypes: {CardType.drawFromMeaning},
        ),
        2,
      );
      final restricted = await repo.dueCards(
        scope,
        cardTypes: {CardType.drawFromMeaning},
      );
      expect(restricted, hasLength(2));
      expect(restricted.every((c) => c.cardType == CardType.drawFromMeaning), isTrue);

      // A cardTypes set matching neither introduced type sees nothing.
      expect(
        await repo.countDueCards(scope, cardTypes: {CardType.readingCloze}),
        0,
      );
    },
  );

  test(
    'charactersWithPassedCard returns only characters with repetitions > 0 '
    'for the given card type, within scope',
    () async {
      const scope = StudyScope(jlptLevels: {5});
      // No cards at all yet -- empty result.
      expect(
        await repo.charactersWithPassedCard(scope, CardType.drawFromMeaning),
        isEmpty,
      );

      // Introduce A cards for 一 and 二, but don't grade them yet.
      await repo.introduceNewCards(scope, CardType.drawFromMeaning, limit: 10);
      expect(
        await repo.charactersWithPassedCard(scope, CardType.drawFromMeaning),
        isEmpty,
        reason: 'freshly introduced cards have repetitions == 0',
      );

      // Grade 一 as a pass (quality >= 3 -> repetitions bumps to 1).
      await repo.gradeCard(
        character: '一',
        cardType: CardType.drawFromMeaning,
        quality: 4,
      );
      expect(
        await repo.charactersWithPassedCard(scope, CardType.drawFromMeaning),
        {'一'},
      );

      // Grade 二 as a fail (quality < 3 -> repetitions stays 0).
      await repo.gradeCard(
        character: '二',
        cardType: CardType.drawFromMeaning,
        quality: 1,
      );
      expect(
        await repo.charactersWithPassedCard(scope, CardType.drawFromMeaning),
        {'一'},
        reason: 'a failed grade does not count as passed',
      );

      // A different card type for 一 is unaffected.
      expect(
        await repo.charactersWithPassedCard(scope, CardType.kanjiRecognition),
        isEmpty,
      );

      // Out-of-scope characters are excluded.
      expect(
        await repo.charactersWithPassedCard(
          const StudyScope(jlptLevels: {1}),
          CardType.drawFromMeaning,
        ),
        isEmpty,
      );

      // Empty scope is always empty.
      expect(
        await repo.charactersWithPassedCard(
          const StudyScope(),
          CardType.drawFromMeaning,
        ),
        isEmpty,
      );
    },
  );

  test('kanji_notes upsert and watch round-trip', () async {
    expect(await repo.watchNote('一').first, '');
    await repo.upsertNote('一', 'Test mnemonic');
    expect(await repo.watchNote('一').first, 'Test mnemonic');
    await repo.upsertNote('一', 'Updated mnemonic');
    expect(await repo.watchNote('一').first, 'Updated mnemonic');
  });

  test('getNote is a plain one-shot read matching watchNote', () async {
    expect(await repo.getNote('一'), '');
    await repo.upsertNote('一', 'Test mnemonic');
    expect(await repo.getNote('一'), 'Test mnemonic');
  });

  test('getStoryKeyword/upsertStoryKeyword round-trip independently of the story body', () async {
    expect(await repo.getStoryKeyword('一'), '');
    await repo.upsertStoryKeyword('一', 'one');
    expect(await repo.getStoryKeyword('一'), 'one');
    // Setting the keyword must not disturb the (still unset) story body.
    expect(await repo.getNote('一'), '');

    await repo.upsertNote('一', 'A longer mnemonic.');
    // And vice versa -- setting the story must not disturb the keyword.
    expect(await repo.getStoryKeyword('一'), 'one');
    expect(await repo.getNote('一'), 'A longer mnemonic.');
  });

  test('seedStories fills in unset keyword/story but never overwrites an existing row', () async {
    // 二 was already personally edited (or previously seeded) -- must survive.
    await repo.upsertNote('二', 'My own story');
    await repo.upsertStoryKeyword('二', 'my own keyword');

    await db.seedStories({
      '一': (keyword: 'one', story: 'Bundled story for 一'),
      '二': (keyword: 'two', story: 'Bundled story for 二'),
    });

    // Freshly seeded.
    expect(await repo.getStoryKeyword('一'), 'one');
    expect(await repo.getNote('一'), 'Bundled story for 一');
    // Untouched by seeding.
    expect(await repo.getStoryKeyword('二'), 'my own keyword');
    expect(await repo.getNote('二'), 'My own story');

    // Seeding again (e.g. a later app launch) must still not clobber it.
    await db.seedStories({
      '一': (keyword: 'different', story: 'Different bundled text'),
      '二': (keyword: 'different', story: 'Different bundled text'),
    });
    expect(await repo.getStoryKeyword('一'), 'one');
    expect(await repo.getNote('一'), 'Bundled story for 一');
    expect(await repo.getStoryKeyword('二'), 'my own keyword');
    expect(await repo.getNote('二'), 'My own story');
  });

  test(
    'repairLegacyStorySplit splits old combined "keyword: story" rows but '
    'leaves already-split ones alone',
    () async {
      // Simulates a row written before storyKeyword existed (schema v3):
      // the whole "keyword: story" text sitting in `story`, storyKeyword
      // at its default empty value.
      await db
          .into(db.kanjiNotes)
          .insert(
            KanjiNotesCompanion.insert(
              character: '一',
              story: const Value('eins: A short story.'),
            ),
          );
      // Already has a keyword (whether from an earlier repair run, or the
      // user's own edit) -- must NOT be touched, even though its story
      // also happens to contain a colon.
      await db
          .into(db.kanjiNotes)
          .insert(
            KanjiNotesCompanion.insert(
              character: '二',
              storyKeyword: const Value('two'),
              story: const Value('Note: already split, leave alone.'),
            ),
          );

      await db.repairLegacyStorySplit();

      final one = await (db.select(
        db.kanjiNotes,
      )..where((t) => t.character.equals('一'))).getSingle();
      expect(one.storyKeyword, 'eins');
      expect(one.story, 'A short story.');

      final two = await (db.select(
        db.kanjiNotes,
      )..where((t) => t.character.equals('二'))).getSingle();
      expect(two.storyKeyword, 'two'); // untouched
      expect(two.story, 'Note: already split, leave alone.'); // untouched

      // Calling again must be a no-op (idempotent) -- confirms the repair
      // is safe to run on every migration/startup without re-splitting.
      await db.repairLegacyStorySplit();
      final oneAgain = await (db.select(
        db.kanjiNotes,
      )..where((t) => t.character.equals('一'))).getSingle();
      expect(oneAgain.storyKeyword, 'eins');
      expect(oneAgain.story, 'A short story.');
    },
  );
}
