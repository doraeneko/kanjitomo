import '../../test_helpers.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kanjitomo/app_dependencies.dart';
import 'package:kanjitomo/core/db/app_database.dart';
import 'package:kanjitomo/core/db/tables.dart';
import 'package:kanjitomo/features/review/review_session_screen.dart';
import 'package:kanjitomo/features/review/study_scope.dart';

// Own file, not grouped with other review-session tests: confirmed
// elsewhere in this suite that a second runAsync-wrapped real asset load in
// the same test *process* can hang, so each test needing a full
// AppDependencies load gets its own file.
void main() {
  testWidgets(
    "drawInSentence: Show translation works on the frontside (pre-draw) "
    'card, same as readingCloze -- both card types share '
    '_buildTranslationToggle',
    (tester) async {
      // The default 800x600 test surface is shorter than a real phone --
      // see review_session_learn_more_test.dart's own doc comment on the
      // same gotcha for this screen's draw-based cards.
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final deps = AppDependencies(
        database: AppDatabase.forTesting(NativeDatabase.memory()),
      );
      await tester.runAsync(() => deps.load());

      // rtkMaxIndex: 1 keeps the scope down to just 一 (rtkIndex 1) -- same
      // "avoid competing auto-introduced cards" reasoning as
      // review_session_reading_cloze_test.dart.
      const scope = StudyScope(mode: StudyScopeMode.rtk, rtkMaxIndex: 1);
      await deps.studyScope.update(scope);

      final now = DateTime.now();
      for (final otherType in [
        CardType.drawFromMeaning,
        CardType.readingCloze,
        CardType.kanjiRecognition,
      ]) {
        await deps.database
            .into(deps.database.reviewCards)
            .insert(
              ReviewCardsCompanion.insert(
                character: '一',
                cardType: otherType,
                dueDate: now.add(const Duration(days: 30)),
                repetitions: const Value(2),
              ),
            );
      }
      // The actual card under test: due now, previously reviewed once so it
      // appears as a review (not a freshly introduced new card). 一's
      // highest-ranked composita word with sentence coverage is 一向
      // (confirmed directly against the bundled assets), read いっこう,
      // translated "That's just fine with me."
      await deps.database
          .into(deps.database.reviewCards)
          .insert(
            ReviewCardsCompanion.insert(
              character: '一',
              cardType: CardType.drawInSentence,
              dueDate: now,
              repetitions: const Value(1),
              lastReviewedAt: Value(now.subtract(const Duration(days: 1))),
            ),
          );

      await tester.pumpWidget(
        testApp(home: ReviewSessionScreen(deps: deps)),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      // The pre-seeded card was not introduced by _introduceNewCardsForToday
      // (it was inserted directly with repetitions: 1), so no slideshow and
      // no "— New" marker -- straight to a normal review.
      expect(find.text('Review (1/1)'), findsOneWidget);

      // The frontside (before any stroke is drawn): "Show translation" is
      // available immediately, same as readingCloze.
      expect(
        find.widgetWithText(TextButton, 'Show translation'),
        findsOneWidget,
      );
      expect(find.text("That's just fine with me."), findsNothing);
      await tester.tap(find.widgetWithText(TextButton, 'Show translation'));
      await tester.pump();
      expect(find.text("That's just fine with me."), findsOneWidget);
      expect(
        find.widgetWithText(TextButton, 'Hide translation'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Show translation stays tappable even when the viewport is too short '
    'for the sentence box to get much room (regression test: the toggle '
    'used to live inside that same squeezed, scrollable box, which could '
    "push it out of its own hit-testable area -- see _buildDrawInSentence's "
    'own doc comment)',
    (tester) async {
      // A genuinely compact (but real-device-plausible) viewport --
      // smaller than the 1080x2400 used elsewhere in this suite, so
      // _buildDrawInSentence's LayoutBuilder reservation squeezes the
      // sentence box down close to its 60px floor, without going so tiny
      // (like the 800x600 default test surface) that even the fixed-size
      // canvas + buttons alone couldn't fit on any real phone.
      tester.view.physicalSize = const Size(1080, 2150);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final deps = AppDependencies(
        database: AppDatabase.forTesting(NativeDatabase.memory()),
      );
      await tester.runAsync(() => deps.load());

      const scope = StudyScope(mode: StudyScopeMode.rtk, rtkMaxIndex: 1);
      await deps.studyScope.update(scope);

      final now = DateTime.now();
      for (final otherType in [
        CardType.drawFromMeaning,
        CardType.readingCloze,
        CardType.kanjiRecognition,
      ]) {
        await deps.database
            .into(deps.database.reviewCards)
            .insert(
              ReviewCardsCompanion.insert(
                character: '一',
                cardType: otherType,
                dueDate: now.add(const Duration(days: 30)),
                repetitions: const Value(2),
              ),
            );
      }
      await deps.database
          .into(deps.database.reviewCards)
          .insert(
            ReviewCardsCompanion.insert(
              character: '一',
              cardType: CardType.drawInSentence,
              dueDate: now,
              repetitions: const Value(1),
              lastReviewedAt: Value(now.subtract(const Duration(days: 1))),
            ),
          );

      await tester.pumpWidget(
        testApp(home: ReviewSessionScreen(deps: deps)),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      // The pre-seeded card was not introduced by _introduceNewCardsForToday
      // (it was inserted directly with repetitions: 1), so no slideshow --
      // straight to a normal review.

      // tester.tap's default warnIfMissed:true makes a hit-test mismatch
      // (the actual bug found here) throw instead of silently tapping the
      // wrong widget -- so this assertion alone is the regression check.
      await tester.tap(find.widgetWithText(TextButton, 'Show translation'));
      await tester.pump();
      expect(find.text("That's just fine with me."), findsOneWidget);
    },
  );
}
