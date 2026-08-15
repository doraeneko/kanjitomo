import '../../test_helpers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kanjitomo/app_dependencies.dart';
import 'package:kanjitomo/core/first_time_dialog.dart';
import 'package:kanjitomo/core/db/app_database.dart';
import 'package:kanjitomo/features/review/review_repository.dart';
import 'package:kanjitomo/features/review/review_session_screen.dart';
import 'package:kanjitomo/features/review/study_scope.dart';

// Own file: confirmed elsewhere in this suite that a second runAsync-wrapped
// real asset load in the same test *process* can hang, so each test needing a
// full AppDependencies load gets its own file.
void main() {
  testWidgets(
    'back button mid-review shows confirmation dialog; dismissing it stays',
    (tester) async {
      SharedPreferences.setMockInitialValues({...ftdSuppressedPrefs});
      final deps = AppDependencies(
        database: AppDatabase.forTesting(NativeDatabase.memory()),
      );
      await tester.runAsync(() => deps.load());
      await deps.studyScope.update(
        const StudyScope(characters: {'一'}),
      );

      // Pre-introduce cards so the session has something to show.
      final reviewRepo = ReviewRepository(deps.database);
      await reviewRepo.introduceCardsForCharacters({'一'});

      // Push ReviewSessionScreen on top of a dummy page so AppBar renders a
      // back button (ReviewStartScreen uses pushReplacement, so the session
      // screen normally has no previous route -- but PopScope also covers the
      // system back gesture, which is what matters on a real device; the
      // AppBar back button is just the easiest way to trigger it in a test).
      await tester.pumpWidget(testApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReviewSessionScreen(deps: deps),
              ),
            ),
            child: const Text('Go'),
          ),
        ),
      ));
      await tester.tap(find.text('Go'));
      // Let the route transition animate and _loadQueue() resolve.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      // Review starts directly (no slideshow -- that's in AddRemoveScreen now).
      // Verify we're on a review card. With only 一 in scope, A + B cards
      // were pre-introduced above.
      expect(find.textContaining('Review \u2014'), findsOneWidget);

      // Tap the AppBar back button to trigger PopScope.
      final backButton = find.byType(BackButton);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Confirmation dialog should be shown.
      expect(find.text('Leave review?'), findsOneWidget);
      expect(
        find.text('Your daily review is not complete yet. Leave anyway?'),
        findsOneWidget,
      );

      // Dismiss by tapping Cancel -- should stay on the review.
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Review \u2014'), findsOneWidget);
    },
  );
}
