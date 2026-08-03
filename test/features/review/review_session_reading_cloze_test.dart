import '../../test_helpers.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kanjitomo/app_dependencies.dart';
import 'package:kanjitomo/core/db/app_database.dart';
import 'package:kanjitomo/core/db/tables.dart';
import 'package:kanjitomo/features/review/review_repository.dart';
import 'package:kanjitomo/features/review/review_session_screen.dart';
import 'package:kanjitomo/features/review/study_scope.dart';

// Own file, not grouped with other review-session tests: confirmed
// elsewhere in this suite (see stroke_order_test_helpers.dart and
// kanji_browser_test_helpers.dart) that a second runAsync-wrapped real
// asset load in the same test *process* can hang or behave unreliably, so
// each test needing a full AppDependencies load gets its own file.
void main() {
  testWidgets(
    'readingCloze: reveal then grade advances to the next card and persists SM-2 state',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final deps = AppDependencies(
        database: AppDatabase.forTesting(NativeDatabase.memory()),
      );
      await tester.runAsync(() => deps.load());

      // rtkMaxIndex: 1 keeps the scope down to just 一 (rtkIndex 1) -- a
      // broader scope (e.g. "all N5") would make _loadQueue()'s own
      // introduceNewCards calls seed many *other* due cards too, which
      // would compete with the one this test cares about for "which card
      // is shown first" (confirmed directly: this happened on the first
      // version of this test, landing on an auto-introduced drawFromMeaning
      // card for 一 instead of the seeded readingCloze one).
      const scope = StudyScope(mode: StudyScopeMode.rtk, rtkMaxIndex: 1);
      await deps.studyScope.update(scope);

      final now = DateTime.now();
      // Pre-existing (far-future-due, so dueCards won't return them, and
      // introduceNewCards won't re-introduce them either) rows for the
      // *other* card types on the same character -- otherwise
      // _loadQueue()'s own introduceNewCards would seed fresh due-today
      // cards for them and they'd compete with the row under test.
      // repetitions: 2 ("established") also keeps them out of dueCards'
      // separate always-include-fragile-cards allowance -- a never-graded
      // (repetitions 0) row would otherwise be pulled back in regardless of
      // its due date.
      for (final otherType in [
        CardType.drawFromMeaning,
        CardType.drawInSentence,
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
      // (confirmed directly against the bundled assets), read いっこう.
      await deps.database
          .into(deps.database.reviewCards)
          .insert(
            ReviewCardsCompanion.insert(
              character: '一',
              cardType: CardType.readingCloze,
              dueDate: now,
              repetitions: const Value(1),
              lastReviewedAt: Value(now.subtract(const Duration(days: 1))),
            ),
          );

      await tester.pumpWidget(
        testApp(home: ReviewSessionScreen(deps: deps)),
      );
      // _loadQueue() does more real I/O (several drift queries) in
      // initState() -- same gotcha as everywhere else in this suite: plain
      // tester.pump() runs in a FakeAsync zone whose virtual clock never
      // actually elapses real wall-clock time, so real Futures never get a
      // chance to resolve without tester.runAsync().
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      // The pre-seeded card was not introduced by _introduceNewCardsForToday
      // (it was inserted directly with repetitions: 1), so no slideshow and
      // no "— New" marker -- straight to a normal review.
      expect(find.text('Review (1/1)'), findsOneWidget);
      expect(
        find.text('What is the reading of the highlighted word?'),
        findsOneWidget,
      );
      expect(find.text('いっこう'), findsNothing); // reading hidden pre-reveal

      // The manual translation toggle is available independent of the
      // reading reveal/grading flow -- available immediately, purely a
      // comprehension aid.
      expect(find.widgetWithText(TextButton, 'Show translation'), findsOneWidget);
      expect(find.text("That's just fine with me."), findsNothing);
      await tester.tap(find.widgetWithText(TextButton, 'Show translation'));
      await tester.pump();
      expect(find.text("That's just fine with me."), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Hide translation'), findsOneWidget);
      // Hide it again so the reveal step below exercises the *automatic*
      // display, not a leftover from the manual toggle.
      await tester.tap(find.widgetWithText(TextButton, 'Hide translation'));
      await tester.pump();
      expect(find.text("That's just fine with me."), findsNothing);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Reveal'));
      await tester.pump();

      // Reading revealed: once in the furigana slot, once more repeated
      // (red/bold) below the sentence as "the answer".
      expect(find.text('いっこう'), findsNWidgets(2));
      // Translation now appears automatically alongside the answer, even
      // though the manual toggle was left in the "hidden" state.
      expect(find.text("That's just fine with me."), findsOneWidget);
      // The composita's own meaning is now shown too -- using the
      // SENTENCE's own reading (いっこう), not composita.json's own
      // "ひたすら" for this word (a genuine heteronym: 一向 has two JMdict
      // senses with different readings, and the sentence's morphological
      // analyzer landed on the other one) -- showing composita.json's
      // reading here would visibly contradict the answer just revealed.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains('一向') &&
              w.text.toPlainText().contains('いっこう') &&
              !w.text.toPlainText().contains('ひたすら'),
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(ElevatedButton, 'Good'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Good'));
      await tester.pump();

      // No more due cards in scope -- the only due row was the one graded.
      expect(find.text('No cards due right now.'), findsOneWidget);

      final card =
          await (deps.database.select(deps.database.reviewCards)..where(
                (t) =>
                    t.character.equals('一') &
                    t.cardType.equalsValue(CardType.readingCloze),
              ))
              .getSingle();
      expect(card.repetitions, 2); // was 1 (pre-seeded), graded q=4 (Good) → 2
      expect(card.lastReviewedAt, isNotNull);

      // Passing it recorded 一向 specifically as a covered reading -- this
      // is the "C+D" composita/sentence tracking store (Statistics-only,
      // doesn't gate green -- see ReviewRepository.overallProgress).
      final reviewRepo = ReviewRepository(deps.database);
      final tested = await reviewRepo.testedCompositaWordsFor(
        {'一'},
        CompositaDirection.reading,
      );
      expect(tested['一'], contains('一向'));
    },
  );
}
