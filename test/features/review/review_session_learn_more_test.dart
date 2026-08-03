import '../../test_helpers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kanjitomo/app_dependencies.dart';
import 'package:kanjitomo/core/db/app_database.dart';
import 'package:kanjitomo/features/review/review_session_screen.dart';
import 'package:kanjitomo/features/review/study_scope.dart';

// Own file, not grouped with other review-session tests: confirmed
// elsewhere in this suite that a second runAsync-wrapped real asset load in
// the same test *process* can hang, so each test needing a full
// AppDependencies load gets its own file.
void main() {
  testWidgets(
    'once the daily new-card cap is reached, "Learn more" introduces the '
    'rest of the in-scope characters',
    (tester) async {
      // The default 800x600 test surface is shorter than a real phone --
      // drawFromMeaning's info block + the fixed-size (260px) drawing
      // canvas is a plain, non-scrollable Column (deliberately: an Expanded
      // /SingleChildScrollView above the canvas would reactively resize as
      // DrawAndPickWidget's own height changes during recognition,
      // visibly shifting the canvas mid-stroke -- see
      // review_session_screen.dart's own doc comment), so unlike most
      // other screens in this suite it can't rely on scrolling to paper
      // over a cramped test viewport. A real phone has comfortably more
      // height than this ever needs.
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final deps = AppDependencies(
        database: AppDatabase.forTesting(NativeDatabase.memory()),
      );
      await tester.runAsync(() => deps.load());

      // Custom mode's composita/sentence eligibility (C+D) is gated by
      // CustomComposita -- an explicit per-kanji pick (see
      // custom_edit_screen.dart), not a JLPT-style ceiling -- and none of
      // these 12 characters have anything picked, so only A+B types are
      // introduced (C+D need composita coverage).
      const customSet = {
        '丙', '串', '丹', '亀', '亭', '仁', '仙', '伎', '伐', '但', '佐', '佳',
      };
      await deps.studyScope.update(
        const StudyScope(
          mode: StudyScopeMode.custom,
          customCharacters: customSet,
        ),
      );

      await tester.pumpWidget(
        testApp(home: ReviewSessionScreen(deps: deps)),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      // dailyNewCap (10) of the 12 in-scope characters are introduced up
      // front. Both A (drawFromMeaning) and B (kanjiRecognition) cards are
      // created for each character in the same session (no gating behind
      // passing earlier card types). No C+D because custom mode requires
      // explicit composita picks and none are set.
      const newCharCount = 10; // dailyNewCap default
      const firstLoadCount = 10 * 2; // A + B per character

      // New-kanji slideshow: all 10 characters are new, tap through them.
      for (var i = 0; i < newCharCount - 1; i++) {
        expect(find.text('New kanji (${i + 1}/$newCharCount)'), findsOneWidget);
        await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
        await tester.pump();
      }
      expect(find.text('New kanji ($newCharCount/$newCharCount)'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Start review'));
      await tester.pump();

      // A+B cards interleaved: first card is new.
      expect(find.text('Review (1/$firstLoadCount) \u2014 New'), findsOneWidget);

      // Grade through all of them. Failed cards are re-queued (Anki-style),
      // so use "Good" for kanjiRecognition. drawFromMeaning "Don't know" is
      // always a fail and will re-queue, but on the second time through,
      // the user would need to draw correctly -- we can't simulate that in
      // tests, so we just loop until the queue is exhausted (with a safety
      // cap to prevent infinite loops in case of bugs).
      for (var i = 0; i < 200; i++) {
        if (find.text('No cards due right now.').evaluate().isNotEmpty) break;
        if (find.widgetWithText(TextButton, "Don't know").evaluate().isNotEmpty) {
          await tester.tap(find.widgetWithText(TextButton, "Don't know"));
          await tester.pump();
          await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
          await tester.pump();
        } else {
          await tester.tap(find.widgetWithText(ElevatedButton, 'Reveal'));
          await tester.pump();
          await tester.tap(find.widgetWithText(ElevatedButton, 'Good'));
          await tester.pump();
        }
      }

      expect(find.text('No cards due right now.'), findsOneWidget);
      // 2 of the 12 characters weren't introduced yet (12 - 10 = 2).
      expect(find.text('2 more available'), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'Learn more'),
        findsOneWidget,
      );

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Learn more'),
      );
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      // "Learn more" reloads the full due queue, not just the newly
      // introduced increment -- so the previously-missed cards (still
      // "fragile": repetitions <= 1, see ReviewRepository.dueCards) come
      // back too, alongside the freshly introduced ones.
      // Total: 10*2 (old A+B, all fragile) + 2*2 (new A+B) = 24.
      // No new-kanji slideshow on "Learn more" -- the session has already
      // started, so the slideshow is skipped. Goes straight to review.
      expect(find.textContaining('Review (1/'), findsOneWidget);

      for (var i = 0; i < 200; i++) {
        if (find.text('No cards due right now.').evaluate().isNotEmpty) break;
        if (find.widgetWithText(TextButton, "Don't know").evaluate().isNotEmpty) {
          await tester.tap(find.widgetWithText(TextButton, "Don't know"));
          await tester.pump();
          await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
          await tester.pump();
        } else {
          await tester.tap(find.widgetWithText(ElevatedButton, 'Reveal'));
          await tester.pump();
          await tester.tap(find.widgetWithText(ElevatedButton, 'Good'));
          await tester.pump();
        }
      }

      // All 12 characters now have A+B introduced, nothing left.
      expect(find.text('No cards due right now.'), findsOneWidget);
      // Return button is always shown; no "Learn more" since nothing remains.
      expect(find.widgetWithText(ElevatedButton, 'Learn more'), findsNothing);
    },
  );
}
