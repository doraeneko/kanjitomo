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
import 'package:kanjitomo/core/kanji_recognizer.dart';
import 'package:kanjitomo/features/review/draw_and_pick.dart';
import 'package:kanjitomo/features/review/review_repository.dart';
import 'package:kanjitomo/features/review/review_session_screen.dart';
import 'package:kanjitomo/features/review/study_scope.dart';

// Own file, not grouped with other review-session tests: confirmed
// elsewhere in this suite that a second runAsync-wrapped real asset load in
// the same test *process* can hang, so each test needing a full
// AppDependencies load gets its own file.
void main() {
  testWidgets(
    'correct drawing offers Continue and Easy; Easy re-grades with the bonus',
    (tester) async {
      SharedPreferences.setMockInitialValues({...ftdSuppressedPrefs});
      final deps = AppDependencies(
        database: AppDatabase.forTesting(NativeDatabase.memory()),
      );
      await tester.runAsync(() => deps.load(loadAll: true));
      // Scope limited to just 一, so the pre-introduced drawFromMeaning
      // card is unambiguous.
      await deps.studyScope.update(
        const StudyScope(characters: {'一'}),
      );

      // Pre-introduce the drawFromMeaning card (due now). Park the other
      // card types far in the future so they don't compete for "which card
      // is shown first".
      final reviewRepo = ReviewRepository(deps.database);
      await reviewRepo.introduceCardsForCharacters(
        {'一'},
        compositaWordsByChar: {'一': ['一向']},
      );

      // Push kanjiRecognition and composita cards far into the future so
      // only drawFromMeaning is due.
      final farFuture = DateTime.now().add(const Duration(days: 30));
      await (deps.database.update(deps.database.reviewCards)
            ..where(
              (t) =>
                  t.character.equals('一') &
                  t.cardType.equalsValue(CardType.drawFromMeaning).not(),
            ))
          .write(ReviewCardsCompanion(
        dueDate: Value(farFuture),
        repetitions: const Value(2),
      ));

      await tester.pumpWidget(
        testApp(home: ReviewSessionScreen(deps: deps)),
      );
      // _loadQueue() (cards + the async story fetch) does real I/O -- same
      // gotcha as everywhere else in this suite: plain tester.pump() runs
      // in a FakeAsync zone whose virtual clock never elapses real
      // wall-clock time, so real Futures never get a chance to resolve
      // without tester.runAsync().
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      // Correct pick, as if the recognizer ranked the target first.
      final draw = tester.widget<DrawAndPickWidget>(
        find.byType(DrawAndPickWidget),
      );
      draw.onPicked([const Prediction('一', 0.9, false)], '一');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('draw-continue')), findsOneWidget);
      expect(find.byKey(const ValueKey('draw-easy')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('draw-easy')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      final card =
          await (deps.database.select(deps.database.reviewCards)..where(
                (t) =>
                    t.character.equals('一') &
                    t.cardType.equalsValue(CardType.drawFromMeaning),
              ))
              .getSingle();
      expect(card.repetitions, 1);
      expect(card.intervalDays, 4); // easy first step, not 1 day

      // One log entry for the answer, not one per grade.
      final logs = await (deps.database.select(deps.database.reviewLog)
            ..where(
              (t) =>
                  t.character.equals('一') &
                  t.cardType.equalsValue(CardType.drawFromMeaning),
            ))
          .get();
      expect(logs, hasLength(1));
    },
  );
}
