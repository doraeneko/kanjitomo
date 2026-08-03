import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kanjitomo/features/review/study_scope.dart';

void main() {
  group('StudyScope (custom mode)', () {
    test('matches ignores jlptLevel/rtkIndex and checks set membership', () {
      const scope = StudyScope(
        mode: StudyScopeMode.custom,
        customCharacters: {'一', '二'},
      );
      expect(
        scope.matches(character: '一', jlptLevel: null, rtkIndex: null),
        isTrue,
      );
      // Even if it would match a (unset) level/RTK filter, custom mode only
      // cares about set membership.
      expect(
        scope.matches(character: '三', jlptLevel: 5, rtkIndex: 1),
        isFalse,
      );
    });

    test('isEmpty reflects the custom set, not jlptLevels', () {
      const empty = StudyScope(mode: StudyScopeMode.custom);
      const nonEmpty = StudyScope(
        mode: StudyScopeMode.custom,
        customCharacters: {'一'},
      );
      expect(empty.isEmpty, isTrue);
      expect(nonEmpty.isEmpty, isFalse);
    });

    test('copyWith and equality account for mode and customCharacters', () {
      const base = StudyScope();
      final custom = base.copyWith(
        mode: StudyScopeMode.custom,
        customCharacters: {'一', '二'},
      );
      expect(custom.mode, StudyScopeMode.custom);
      expect(custom.customCharacters, {'一', '二'});
      expect(
        custom,
        const StudyScope(
          mode: StudyScopeMode.custom,
          customCharacters: {'一', '二'},
        ),
      );
      expect(custom, isNot(base));
    });
  });

  group('StudyScope (rtk mode)', () {
    test('matches checks only the RTK cutoff, ignoring jlptLevel entirely', () {
      const scope = StudyScope(mode: StudyScopeMode.rtk, rtkMaxIndex: 5);
      expect(
        scope.matches(character: '一', jlptLevel: null, rtkIndex: 3),
        isTrue,
      );
      // Even a matching jlptLevel doesn't help -- rtk mode isn't a union.
      expect(
        scope.matches(character: '二', jlptLevel: 5, rtkIndex: 3000),
        isFalse,
      );
      expect(
        scope.matches(character: '三', jlptLevel: null, rtkIndex: null),
        isFalse,
      );
    });

    test('isEmpty is always false -- the cutoff always has a value', () {
      const scope = StudyScope(mode: StudyScopeMode.rtk);
      expect(scope.isEmpty, isFalse);
    });
  });

  group('StudyScope (JLPT mode)', () {
    test('matches checks JLPT level membership', () {
      const scope = StudyScope(jlptLevels: {5});
      expect(
        scope.matches(character: 'a', jlptLevel: 5, rtkIndex: null),
        isTrue,
      );
      expect(
        scope.matches(character: 'b', jlptLevel: 4, rtkIndex: null),
        isFalse,
      );
      // levelRank is accepted but ignored (no chunking).
      expect(
        scope.matches(character: 'a', jlptLevel: 5, rtkIndex: null, levelRank: null),
        isTrue,
      );
    });
  });

  group('StudyScope.compositaCeiling', () {
    test('null by default -- composita/sentence testing is opt-in', () {
      expect(const StudyScope().compositaCeiling, isNull);
    });

    test('copyWith requires clearCompositaCeiling to reset it to null', () {
      const withCeiling = StudyScope(jlptLevels: {5}, compositaCeiling: 3);
      expect(withCeiling.copyWith().compositaCeiling, 3);
      expect(
        withCeiling.copyWith(clearCompositaCeiling: true).compositaCeiling,
        isNull,
      );
    });

    test('participates in equality and hashCode', () {
      const a = StudyScope(jlptLevels: {5}, compositaCeiling: 3);
      const b = StudyScope(jlptLevels: {5}, compositaCeiling: 3);
      const c = StudyScope(jlptLevels: {5}, compositaCeiling: 2);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('StudyScopeRepository persistence', () {
    testWidgets('round-trips mode and customCharacters through shared_preferences', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final repo = StudyScopeRepository();
      await repo.load();
      expect(repo.scope.value, const StudyScope()); // default: jlpt mode

      await repo.update(
        const StudyScope(
          mode: StudyScopeMode.custom,
          customCharacters: {'一', '二', '三'},
        ),
      );

      final reloaded = StudyScopeRepository();
      await reloaded.load();
      expect(reloaded.scope.value.mode, StudyScopeMode.custom);
      expect(reloaded.scope.value.customCharacters, {'一', '二', '三'});
    });

    testWidgets(
      'round-trips compositaCeiling (including back to null)',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final repo = StudyScopeRepository();
        await repo.load();

        await repo.update(
          const StudyScope(jlptLevels: {5}, compositaCeiling: 3),
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
