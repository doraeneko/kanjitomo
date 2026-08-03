import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kanjitomo/core/db/app_database.dart';
import 'package:kanjitomo/core/db/tables.dart';
import 'package:kanjitomo/features/review/review_repository.dart';

void main() {
  late AppDatabase db;
  late ReviewRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ReviewRepository(db);
  });

  tearDown(() => db.close());

  test('recordCompositaTested + testedCompositaWordsFor round-trip', () async {
    await repo.recordCompositaTested('一', '一つ', CompositaDirection.reading);
    final tested = await repo.testedCompositaWordsFor(
      {'一', '二'},
      CompositaDirection.reading,
    );
    expect(tested['一'], {'一つ'});
    expect(tested.containsKey('二'), isFalse);
  });

  test(
    'reading and writing direction are tracked independently -- passing '
    'one does not mark the other as tested',
    () async {
      await repo.recordCompositaTested('一', '一つ', CompositaDirection.reading);
      final readingTested = await repo.testedCompositaWordsFor(
        {'一'},
        CompositaDirection.reading,
      );
      final writingTested = await repo.testedCompositaWordsFor(
        {'一'},
        CompositaDirection.writing,
      );
      expect(readingTested['一'], {'一つ'});
      expect(writingTested.containsKey('一'), isFalse);
    },
  );

  test(
    'recordCompositaTested is idempotent (upsert, not a duplicate row) per '
    '(character, word, direction)',
    () async {
      await repo.recordCompositaTested('一', '一つ', CompositaDirection.reading);
      await repo.recordCompositaTested('一', '一つ', CompositaDirection.reading);
      final rows = await db.select(db.compositaProgress).get();
      expect(rows, hasLength(1));
    },
  );

  test(
    'the same (character, word) can be tracked separately in both '
    'directions -- two distinct rows, not a collision',
    () async {
      await repo.recordCompositaTested('一', '一つ', CompositaDirection.reading);
      await repo.recordCompositaTested('一', '一つ', CompositaDirection.writing);
      final rows = await db.select(db.compositaProgress).get();
      expect(rows, hasLength(2));
    },
  );

  test(
    'overallProgress: reading is kanjiRecognition alone, writing is '
    'drawFromMeaning alone -- readingCloze/drawInSentence (composita/'
    'sentence testing) never contribute to green, however much they\'ve '
    'been passed',
    () async {
      await repo.gradeCard(
        character: '一',
        cardType: CardType.readingCloze,
        quality: 5,
      );
      await repo.gradeCard(
        character: '一',
        cardType: CardType.drawInSentence,
        quality: 5,
      );

      final progress = await repo.overallProgress();

      // Neither direction is "known" from readingCloze/drawInSentence alone.
      expect(progress['一']?.reading ?? CardProgress.none, isNot(CardProgress.known));
      expect(progress['一']?.writing ?? CardProgress.none, isNot(CardProgress.known));
    },
  );

  test(
    'overallProgress: kanjiRecognition passed makes reading known; '
    'drawFromMeaning passed makes writing known',
    () async {
      await repo.gradeCard(
        character: '一',
        cardType: CardType.kanjiRecognition,
        quality: 4,
      );
      await repo.gradeCard(
        character: '一',
        cardType: CardType.drawFromMeaning,
        quality: 4,
      );

      final progress = await repo.overallProgress();
      expect(progress['一']!.reading, CardProgress.known);
      expect(progress['一']!.writing, CardProgress.known);
    },
  );

  test('overallProgress: never reviewed reads as absent, not missed', () async {
    final progress = await repo.overallProgress();
    expect(progress.containsKey('一'), isFalse);
  });
}
