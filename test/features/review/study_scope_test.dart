import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kanjitomo/core/db/tables.dart';

import 'package:kanjitomo/core/db/app_database.dart';
import 'package:kanjitomo/features/review/study_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('StudyScope', () {
    test('matches checks set membership', () {
      const scope = StudyScope(characters: {'一', '二'});
      expect(scope.matches(character: '一'), isTrue);
      expect(scope.matches(character: '三'), isFalse);
    });

    test('isEmpty reflects the characters set', () {
      const empty = StudyScope();
      const nonEmpty = StudyScope(characters: {'一'});
      expect(empty.isEmpty, isTrue);
      expect(nonEmpty.isEmpty, isFalse);
    });

    test('copyWith and equality', () {
      const base = StudyScope();
      final withChars = base.copyWith(characters: {'一', '二'});
      expect(withChars.characters, {'一', '二'});
      expect(
        withChars,
        const StudyScope(characters: {'一', '二'}),
      );
      expect(withChars, isNot(base));
    });
  });

  group('StudyScope.compositaCeiling', () {
    test('null by default -- composita/sentence testing is opt-in', () {
      expect(const StudyScope().compositaCeiling, isNull);
    });

    test('copyWith requires clearCompositaCeiling to reset it to null', () {
      const withCeiling = StudyScope(
        characters: {'一'},
        compositaCeiling: 3,
      );
      expect(withCeiling.copyWith().compositaCeiling, 3);
      expect(
        withCeiling.copyWith(clearCompositaCeiling: true).compositaCeiling,
        isNull,
      );
    });

    test('participates in equality and hashCode', () {
      const a = StudyScope(characters: {'一'}, compositaCeiling: 3);
      const b = StudyScope(characters: {'一'}, compositaCeiling: 3);
      const c = StudyScope(characters: {'一'}, compositaCeiling: 2);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('StudyScopeRepository persistence', () {
    late AppDatabase db;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() => db.close());

    test('round-trips characters through SQLite', () async {
      final repo = StudyScopeRepository(db);
      await repo.load();
      expect(repo.scope.value, const StudyScope()); // default: empty

      await repo.update(
        const StudyScope(characters: {'一', '二', '三'}),
      );

      // Reload from the same DB to verify persistence.
      final reloaded = StudyScopeRepository(db);
      await reloaded.load();
      expect(reloaded.scope.value.characters, {'一', '二', '三'});
    });

    test('round-trips compositaCeiling (including back to null)', () async {
      final repo = StudyScopeRepository(db);
      await repo.load();

      await repo.update(
        const StudyScope(characters: {'一'}, compositaCeiling: 3),
      );
      final withCeiling = StudyScopeRepository(db);
      await withCeiling.load();
      expect(withCeiling.scope.value.compositaCeiling, 3);

      await repo.update(
        repo.scope.value.copyWith(clearCompositaCeiling: true),
      );
      final cleared = StudyScopeRepository(db);
      await cleared.load();
      expect(cleared.scope.value.compositaCeiling, isNull);
    });

    test('round-trips maxCompositaPerKanji', () async {
      final repo = StudyScopeRepository(db);
      await repo.load();

      await repo.update(
        const StudyScope(characters: {'一'}, maxCompositaPerKanji: 6),
      );
      final reloaded = StudyScopeRepository(db);
      await reloaded.load();
      expect(reloaded.scope.value.maxCompositaPerKanji, 6);
    });

    test('addCharacters and removeCharacters', () async {
      final repo = StudyScopeRepository(db);
      await repo.load();

      await repo.addCharacters({'一', '二'});
      expect(repo.scope.value.characters, {'一', '二'});

      await repo.addCharacters({'三'});
      expect(repo.scope.value.characters, {'一', '二', '三'});

      await repo.removeCharacters({'二'});
      expect(repo.scope.value.characters, {'一', '三'});
    });

    test('orphan repair: characters with review progress but not in pool are restored', () async {
      // Simulate orphaned review data: insert ReviewCards rows directly
      // into the DB for characters not in the scope.
      await db.into(db.reviewCards).insert(ReviewCardsCompanion.insert(
        character: '食',
        cardType: CardType.drawFromMeaning,
        dueDate: DateTime.now(),
      ));
      await db.into(db.reviewCards).insert(ReviewCardsCompanion.insert(
        character: '飲',
        cardType: CardType.drawFromMeaning,
        dueDate: DateTime.now(),
      ));

      // First load with empty SharedPreferences → pool should include
      // the orphaned characters.
      final repo = StudyScopeRepository(db);
      await repo.load();
      expect(repo.scope.value.characters, contains('食'));
      expect(repo.scope.value.characters, contains('飲'));
    });
  });
}
