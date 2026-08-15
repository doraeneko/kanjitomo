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
import 'package:kanjitomo/features/review/review_start_screen.dart';
import 'package:kanjitomo/features/review/study_scope.dart';

// Own file, not grouped with other review tests: confirmed elsewhere in this
// suite that a second runAsync-wrapped real asset load in the same test
// *process* can hang, so each test needing a full AppDependencies load gets
// its own file.
void main() {
  testWidgets(
    'summarizes the current scope and starts a review',
    (tester) async {
      SharedPreferences.setMockInitialValues({...ftdSuppressedPrefs});
      final deps = AppDependencies(
        database: AppDatabase.forTesting(NativeDatabase.memory()),
      );
      await tester.runAsync(() => deps.load());
      // Unlock Pro so gates don't interfere.
      deps.proStatus.isProUnlocked.value = true;
      await deps.studyScope.update(const StudyScope(
        characters: {'一', '二', '三', '四', '五', '六', '七', '八', '九', '十'},
      ));

      // Pre-introduce cards so the start screen has something to review.
      final reviewRepo = ReviewRepository(deps.database);
      await reviewRepo.introduceCardsForCharacters(
        {'一', '二', '三', '四', '五', '六', '七', '八', '九', '十'},
      );

      await tester.pumpWidget(testApp(home: ReviewStartScreen(deps: deps)));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      // Cards are now due (just introduced).
      expect(find.textContaining('No cards due right now.'), findsNothing);

      // Start the review directly -- no "Add new kanji?" dialog anymore.
      final startButton = find.byType(ElevatedButton);
      await tester.ensureVisible(startButton);
      await tester.pump();
      await tester.tap(startButton);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
      expect(find.byType(ReviewSessionScreen), findsOneWidget);
    },
  );
}
