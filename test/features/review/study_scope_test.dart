import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kanjitomo/core/first_time_dialog.dart';
import 'package:kanjitomo/features/review/study_scope.dart';

void main() {
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
    testWidgets('round-trips characters through shared_preferences', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        ...ftdSuppressedPrefs,
        'study_scope.migrated_to_unified': true,
      });
      final repo = StudyScopeRepository();
      await repo.load();
      expect(repo.scope.value, const StudyScope()); // default: empty

      await repo.update(
        const StudyScope(characters: {'一', '二', '三'}),
      );

      final reloaded = StudyScopeRepository();
      await reloaded.load();
      expect(reloaded.scope.value.characters, {'一', '二', '三'});
    });

    testWidgets(
      'round-trips compositaCeiling (including back to null)',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          ...ftdSuppressedPrefs,
          'study_scope.migrated_to_unified': true,
        });
        final repo = StudyScopeRepository();
        await repo.load();

        await repo.update(
          const StudyScope(characters: {'一'}, compositaCeiling: 3),
        );
        final withCeiling = StudyScopeRepository();
        await withCeiling.load();
        expect(withCeiling.scope.value.compositaCeiling, 3);

        await repo.update(
          repo.scope.value.copyWith(clearCompositaCeiling: true),
        );
        final cleared = StudyScopeRepository();
        await cleared.load();
        expect(cleared.scope.value.compositaCeiling, isNull);
      },
    );
  });
}
