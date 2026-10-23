import '../../test_helpers.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kanjitomo/app_dependencies.dart';
import 'package:kanjitomo/core/first_time_dialog.dart';
import 'package:kanjitomo/core/db/app_database.dart';
import 'package:kanjitomo/core/db/tables.dart';
import 'package:kanjitomo/features/review/review_repository.dart';
import 'package:kanjitomo/features/review/review_session_screen.dart';
import 'package:kanjitomo/features/review/study_scope.dart';

// Own file, not grouped with other review-session tests: confirmed
// elsewhere in this suite that a second runAsync-wrapped real asset load in
// the same test *process* can hang, so each test needing a full
// AppDependencies load gets its own file.
void main() {
  testWidgets(
    'filtered session end screen ignores due cards of unselected kinds',
    (tester) async {
      SharedPreferences.setMockInitialValues({...ftdSuppressedPrefs});
      final deps = AppDependencies(
        database: AppDatabase.forTesting(NativeDatabase.memory()),
      );
      await tester.runAsync(() => deps.load(loadAll: true));
      await deps.studyScope.update(const StudyScope(characters: {'一'}));

      final reviewRepo = ReviewRepository(deps.database);
      await reviewRepo.introduceCardsForCharacters(
        {'一'},
        compositaWordsByChar: {'一': ['一番']},
      );
      await reviewRepo.addCustomComposita('一', '一番');

      // Only kanjiRecognition and the composita cards are due; the session
      // below is limited to kanjiRecognition.
      final farFuture = DateTime.now().add(const Duration(days: 30));
      await (deps.database.update(deps.database.reviewCards)
            ..where((t) =>
                t.character.equals('一') &
                t.cardType.equalsValue(CardType.drawFromMeaning)))
          .write(ReviewCardsCompanion(dueDate: Value(farFuture)));

      await tester.pumpWidget(
        testApp(
          home: ReviewSessionScreen(
            deps: deps,
            cardTypes: const {CardType.kanjiRecognition},
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Reveal'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Good'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      expect(find.text('No cards due right now.'), findsOneWidget);
      expect(find.textContaining('Continue with'), findsNothing);
    },
  );
}
