import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanjitomo/core/db/app_database.dart';
import 'package:kanjitomo/features/review/review_repository.dart';

void main() {
  late AppDatabase db;
  late ReviewRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ReviewRepository(db);
  });

  tearDown(() => db.close());

  test('customCompositaFor is empty for a character with nothing picked yet', () async {
    expect(await repo.customCompositaFor('一'), isEmpty);
  });

  test('addCustomComposita then customCompositaFor round-trip; idempotent', () async {
    await repo.addCustomComposita('一', '一つ');
    await repo.addCustomComposita('一', '一部');
    // Adding the same pair again is a no-op, not a duplicate/crash.
    await repo.addCustomComposita('一', '一つ');

    expect(await repo.customCompositaFor('一'), {'一つ', '一部'});
  });

  test('removeCustomComposita removes just that one pair', () async {
    await repo.addCustomComposita('一', '一つ');
    await repo.addCustomComposita('一', '一部');

    await repo.removeCustomComposita('一', '一つ');

    expect(await repo.customCompositaFor('一'), {'一部'});
  });

  test(
    'customCompositaForCharacters batches several characters, each kept '
    'distinct',
    () async {
      await repo.addCustomComposita('一', '一つ');
      await repo.addCustomComposita('二', '二つ');
      // 三 has nothing selected -- absent from the result map entirely,
      // same "absent means none" convention as testedCompositaWordsFor.

      final result = await repo.customCompositaForCharacters({'一', '二', '三'});
      expect(result['一'], {'一つ'});
      expect(result['二'], {'二つ'});
      expect(result.containsKey('三'), isFalse);
    },
  );

  test('customCompositaForCharacters is empty for an empty character set', () async {
    expect(await repo.customCompositaForCharacters({}), isEmpty);
  });
}
