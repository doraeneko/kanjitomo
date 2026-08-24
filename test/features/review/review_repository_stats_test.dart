import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanjitomo/core/db/app_database.dart';
import 'package:kanjitomo/core/db/tables.dart';
import 'package:kanjitomo/features/review/review_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kanjitomo/core/first_time_dialog.dart';

void main() {
  late AppDatabase db;
  late ReviewRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({...ftdSuppressedPrefs});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ReviewRepository(db);
  });

  tearDown(() => db.close());

  test('statsFor counts known, missed, and not-started correctly', () async {
    // Known (learnt): repetitions >= 2 (2 consecutive correct answers).
    for (var i = 0; i < 2; i++) {
      await repo.gradeCard(character: '一', cardType: CardType.drawFromMeaning, quality: 5);
    }
    // Learning: reviewed but repetitions < 2.
    await repo.gradeCard(character: '二', cardType: CardType.drawFromMeaning, quality: 4);
    // Not started: no row at all for this cardType -- doesn't touch drawFromMeaning.
    await repo.gradeCard(character: '三', cardType: CardType.readingCloze, quality: 4);

    const universe = {
      '一', '二', '三', '四', '五', '六', '七', '八', '九', '十',
    };
    final stats = await repo.statsFor(CardType.drawFromMeaning, universe);
    expect(stats.known, 1); // 一 (interval ~39)
    expect(stats.missed, 1); // 二 (interval 1)
    expect(stats.notStarted, 8); // 10 - 2 introduced rows
  });

  test('statsFor is empty for an empty character universe', () async {
    await repo.gradeCard(character: '一', cardType: CardType.drawFromMeaning, quality: 4);

    final stats = await repo.statsFor(CardType.drawFromMeaning, {});
    expect(stats.known, 0);
    expect(stats.missed, 0);
    expect(stats.notStarted, 0);
  });

  test('statsFor only counts rows for characters within the given universe', () async {
    // 一 is reviewed, but outside the universe passed in -- shouldn't count.
    await repo.gradeCard(character: '一', cardType: CardType.drawFromMeaning, quality: 4);
    await repo.gradeCard(character: '二', cardType: CardType.drawFromMeaning, quality: 4);

    final stats = await repo.statsFor(CardType.drawFromMeaning, {'二'});
    expect(stats.missed, 1); // 二 only (repetitions=1, below threshold of 4)
    expect(stats.known, 0);
    expect(stats.notStarted, 0);
  });

  test(
    'overallProgress tracks reading (kanjiRecognition) and writing '
    '(drawFromMeaning) as independent directions',
    () async {
      // 一: kanjiRecognition known (2 correct = threshold), drawFromMeaning
      // missed (pass then fail resets repetitions to 0).
      for (var i = 0; i < 2; i++) {
        await repo.gradeCard(character: '一', cardType: CardType.kanjiRecognition, quality: 5);
      }
      await repo.gradeCard(character: '一', cardType: CardType.drawFromMeaning, quality: 4);
      await repo.gradeCard(character: '一', cardType: CardType.drawFromMeaning, quality: 1);
      // 二: only ever attempted in the writing direction, and missed there.
      await repo.gradeCard(character: '二', cardType: CardType.drawFromMeaning, quality: 4);
      await repo.gradeCard(character: '二', cardType: CardType.drawFromMeaning, quality: 1);
      // 三: never reviewed -- absent from the map entirely.

      final progress = await repo.overallProgress();
      expect(progress['一']!.reading, CardProgress.known);
      expect(progress['一']!.writing, CardProgress.missed);
      expect(progress['二']!.reading, CardProgress.none);
      expect(progress['二']!.writing, CardProgress.missed);
      expect(progress.containsKey('三'), isFalse);
    },
  );

  test(
    'overallProgress: readingCloze/drawInSentence (composita/sentence '
    'testing) never populate either direction, however much they\'ve been '
    'passed -- they no longer gate green, see CompositaProgress instead',
    () async {
      await repo.gradeCard(character: '四', cardType: CardType.readingCloze, quality: 5);
      await repo.gradeCard(character: '四', cardType: CardType.drawInSentence, quality: 5);

      final progress = await repo.overallProgress();
      expect(progress.containsKey('四'), isFalse);
    },
  );

  test(
    'compositaProgressFor counts testable words and tested-per-direction, '
    'against the caller-supplied testable set -- never gates green',
    () async {
      await repo.recordCompositaTested('一', '一向', CompositaDirection.reading);
      await repo.recordCompositaTested('一', '一部', CompositaDirection.writing);
      // 二's word was never tested.

      final coverage = await repo.compositaProgressFor({
        '一': {'一向', '一部'},
        '二': {'二重'},
      });
      expect(coverage.testable, 3); // 2 + 1
      expect(coverage.testedReading, 1); // 一向 only
      expect(coverage.testedWriting, 1); // 一部 only
    },
  );

  test('compositaProgressFor is empty for an empty testable map', () async {
    final coverage = await repo.compositaProgressFor({});
    expect(coverage.testable, 0);
    expect(coverage.testedReading, 0);
    expect(coverage.testedWriting, 0);
  });

  test('resetAllProgress clears review_cards and review_log but not kanji_notes', () async {
    await repo.gradeCard(character: '一', cardType: CardType.drawFromMeaning, quality: 4);
    await repo.upsertNote('一', 'My story');

    await repo.resetAllProgress();

    final cards = await db.select(db.reviewCards).get();
    final log = await db.select(db.reviewLog).get();
    expect(cards, isEmpty);
    expect(log, isEmpty);

    final story = await repo.watchNote('一').first;
    expect(story, 'My story'); // untouched by the reset
  });
}
