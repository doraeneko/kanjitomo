import '../../test_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kanjitomo/features/learning/custom_edit_screen.dart';
import 'package:kanjitomo/features/learning/jlpt_edit_screen.dart';
import 'package:kanjitomo/features/learning/learning_screen.dart';
import 'package:kanjitomo/features/review/review_start_screen.dart';
import 'package:kanjitomo/features/review/statistics_screen.dart';
import 'package:kanjitomo/features/review/study_scope.dart';

import '../kanji_browser/kanji_browser_test_helpers.dart';

void main() {
  testWidgets(
    'JLPT/Custom Review, Edit, and Statistics all put the scope into the '
    'matching mode before navigating',
    (tester) async {
      // Suppress RenderFlex overflow errors that surface when navigating
      // to screens whose layout is tighter than the 800x600 test viewport
      // (e.g. CustomEditScreen's fixed-height drawing canvas).
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exception.toString().contains('overflowed')) return;
        oldHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldHandler);

      final deps = await loadTestDeps(tester);
      // Unlock Pro so the gates don't interfere with navigation testing.
      deps.proStatus.isProUnlocked.value = true;
      // Starts in jlpt mode (the default) with nothing selected.
      await tester.pumpWidget(testApp(home: LearningScreen(deps: deps)));
      await tester.pump();

      expect(find.text('JLPT mode'), findsOneWidget);
      expect(find.text('Custom mode'), findsOneWidget);
      expect(find.text('RTK'), findsNothing);

      // Custom > Edit: switches mode to custom, then opens
      // CustomEditScreen. _ensureMode's StudyScope.update does real async
      // shared_preferences I/O before the push happens, and the push
      // itself animates -- same tester.runAsync() + settle gotcha as
      // everywhere else in this suite that triggers real async work from
      // inside a tap callback.
      await tester.tap(find.byKey(const ValueKey('Custom mode-edit')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
      expect(deps.studyScope.scope.value.mode, StudyScopeMode.custom);
      expect(find.byType(CustomEditScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // JLPT > Edit: switches mode back to jlpt, then opens JlptEditScreen.
      await tester.tap(find.byKey(const ValueKey('JLPT mode-edit')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
      expect(deps.studyScope.scope.value.mode, StudyScopeMode.jlpt);
      expect(find.byType(JlptEditScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // JLPT > Review: also ensures jlpt mode, opens the shared
      // ReviewStartScreen.
      await deps.studyScope.update(
        deps.studyScope.scope.value.copyWith(
          mode: StudyScopeMode.custom,
          customCharacters: {'一'},
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('JLPT mode-review')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
      expect(deps.studyScope.scope.value.mode, StudyScopeMode.jlpt);
      expect(find.byType(ReviewStartScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Custom > Statistics: also ensures the matching mode first, since
      // Statistics is now scoped to whichever StudyScope is current (see
      // statistics_screen.dart) -- scope is still jlpt from the Review
      // step above, so this exercises a real mode flip, not a no-op.
      expect(deps.studyScope.scope.value.mode, StudyScopeMode.jlpt);
      await tester.tap(find.byKey(const ValueKey('Custom mode-statistics')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
      expect(deps.studyScope.scope.value.mode, StudyScopeMode.custom);
      expect(find.byType(StatisticsScreen), findsOneWidget);
    },
  );
}
