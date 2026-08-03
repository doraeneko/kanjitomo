import '../../test_helpers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kanjitomo/app_dependencies.dart';
import 'package:kanjitomo/core/db/app_database.dart';
import 'package:kanjitomo/features/review/review_focus.dart';
import 'package:kanjitomo/features/review/review_session_screen.dart';
import 'package:kanjitomo/features/review/review_start_screen.dart';
import 'package:kanjitomo/features/review/study_scope.dart';

// Own file, not grouped with other review tests: confirmed elsewhere in this
// suite that a second runAsync-wrapped real asset load in the same test
// *process* can hang, so each test needing a full AppDependencies load gets
// its own file.
void main() {
  testWidgets(
    'summarizes the current scope (however it was set elsewhere), offers a '
    'core/composita/both focus selector, and starts a review',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final deps = AppDependencies(
        database: AppDatabase.forTesting(NativeDatabase.memory()),
      );
      await tester.runAsync(() => deps.load());
      // Unlock Pro so focus-selector gates don't interfere.
      deps.proStatus.isProUnlocked.value = true;
      // No compositaCeiling set -- this scope hasn't opted into composita yet.
      // Scope editing itself (level chips, RTK, custom-set membership) no
      // longer happens on this screen at all -- see
      // jlpt_edit_screen_test.dart/custom_edit_screen_test.dart for that.
      await deps.studyScope.update(const StudyScope(jlptLevels: {5}));

      await tester.pumpWidget(testApp(home: ReviewStartScreen(deps: deps)));
      // countDueCards does real async DB I/O in initState() -- same gotcha
      // as everywhere else in this suite: plain tester.pump() runs in a
      // FakeAsync zone whose virtual clock never elapses real wall-clock
      // time, so real Futures never get a chance to resolve without
      // tester.runAsync().
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      expect(find.textContaining('N5'), findsWidgets);
      expect(find.textContaining('0 due now'), findsOneWidget); // fresh DB
      expect(find.byType(FilterChip), findsNothing);
      expect(find.text('RTK'), findsNothing);

      // Selecting "Composita" surfaces a hint since this scope has no
      // compositaCeiling yet -- an honest "nothing to quiz" rather than a
      // silent empty session.
      await tester.tap(find.text('Composita'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
      expect(
        find.textContaining('No composita/sentence testing is enabled'),
        findsOneWidget,
      );

      // Switch back to "Both" and start the review -- the chosen focus is
      // threaded through to ReviewSessionScreen.
      await tester.tap(find.text('Both'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
      // With 0 due in a fresh DB, the button shows "Learn N new kanji" instead.
      final startButton = find.byType(ElevatedButton);
      await tester.ensureVisible(startButton);
      await tester.pump();
      await tester.tap(startButton);
      // Two bounded pumps past the standard MaterialPageRoute transition
      // duration (300ms exactly landed right on the boundary elsewhere in
      // this suite and wasn't quite enough), then let ReviewSessionScreen's
      // own real async _loadQueue() resolve.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
      final session = tester.widget<ReviewSessionScreen>(
        find.byType(ReviewSessionScreen),
      );
      expect(session.focus, ReviewFocus.both);
    },
  );
}
