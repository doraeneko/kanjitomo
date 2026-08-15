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
// elsewhere in this suite (see stroke_order_test_helpers.dart and
// kanji_browser_test_helpers.dart) that a second runAsync-wrapped real
// asset load in the same test *process* can hang or behave unreliably, so
// each test needing a full AppDependencies load gets its own file.
void main() {
  testWidgets(
    'readingCloze: reveal then grade advances to the next card and persists SM-2 state',
    (tester) async {
      SharedPreferences.setMockInitialValues({...ftdSuppressedPrefs});
      final deps = AppDependencies(
        database: AppDatabase.forTesting(NativeDatabase.memory()),
      );
      await tester.runAsync(() => deps.load());

      // Scope limited to just 一 -- a broader scope would make _loadQueue()'s
      // own introduceNewCards calls seed many *other* due cards too, which
      // would compete with the one this test cares about for "which card
      // is shown first".
      const scope = StudyScope(characters: {'一'});
      await deps.studyScope.update(scope);

      final now = DateTime.now();
      // Pre-existing (far-future-due, so dueCards won't return them, and
      // introduceNewCards won't re-introduce them either) rows for the
      // *other* card types on the same character -- otherwise
      // _loadQueue()'s own introduceNewCards would seed fresh due-today
      // cards for them and they'd compete with the row under test.
      for (final otherType in [
        CardType.drawFromMeaning,
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
      // drawInSentence needs a compositaWord now that each composita word
      // is its own card.
      await deps.database
          .into(deps.database.reviewCards)
          .insert(
            ReviewCardsCompanion.insert(
              character: '一',
              cardType: CardType.drawInSentence,
              compositaWord: const Value('一応'),
              dueDate: now.add(const Duration(days: 30)),
              repetitions: const Value(2),
            ),
          );
      // The actual card under test: due now, previously reviewed so it
      // appears as a review (not a freshly introduced new card). 一応 is
      // a high-ranked composita word for 一 with sentence coverage
      // (confirmed directly against the bundled assets), read いちおう.
      // compositaWord identifies which specific word this card tests.
      // repetitions: 0 keeps the sentence rotation at index 0 (the first
      // mined sentence for 一応, whose translation is "Yeah, there was
      // some sort of reply from them."), while lastReviewedAt prevents the
      // "— New" marker.
      await deps.database
          .into(deps.database.reviewCards)
          .insert(
            ReviewCardsCompanion.insert(
              character: '一',
              cardType: CardType.readingCloze,
              compositaWord: const Value('一応'),
              dueDate: now,
              repetitions: const Value(0),
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
      expect(find.text('Review \u2014 1/1'), findsOneWidget);
      expect(
        find.text('What is the reading of the highlighted word?'),
        findsOneWidget,
      );
      expect(find.text('いちおう'), findsNothing); // reading hidden pre-reveal

      // The manual translation toggle is available independent of the
      // reading reveal/grading flow -- available immediately, purely a
      // comprehension aid.
      expect(find.widgetWithText(TextButton, 'Show translation'), findsOneWidget);
      expect(
        find.text('Yeah, there was some sort of reply from them.'),
        findsNothing,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Show translation'));
      await tester.pump();
      expect(
        find.text('Yeah, there was some sort of reply from them.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, 'Hide translation'), findsOneWidget);
      // Hide it again so the reveal step below exercises the *automatic*
      // display, not a leftover from the manual toggle.
      await tester.tap(find.widgetWithText(TextButton, 'Hide translation'));
      await tester.pump();
      expect(
        find.text('Yeah, there was some sort of reply from them.'),
        findsNothing,
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Reveal'));
      await tester.pump();

      // Reading revealed. 応 is not in the pool so its reading (おう) is
      // shown as furigana even before reveal; after reveal both readings
      // appear in various forms (furigana, composita info text).
      expect(find.text('いち'), findsWidgets);
      // おう may appear as furigana or in composita info text.
      expect(find.textContaining('おう'), findsWidgets);
      // Translation is hidden by default — must tap "Show translation".
      expect(
        find.text('Yeah, there was some sort of reply from them.'),
        findsNothing,
      );
      // The composita word's kanji are now individual tappable widgets;
      // the reading+meaning sits in a separate Text.
      expect(find.text('一'), findsWidgets);
      expect(find.text('応'), findsWidgets);
      // The composita info text starts with " (" (reading + meaning).
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              (w.data?.startsWith(' (いち・おう)') ?? false),
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(ElevatedButton, 'Good'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Good'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();

      // The card may be re-queued for more untested composita on 一, so we
      // don't assert "No cards due" -- just verify grading persisted.

      final card =
          await (deps.database.select(deps.database.reviewCards)..where(
                (t) =>
                    t.character.equals('一') &
                    t.cardType.equalsValue(CardType.readingCloze) &
                    t.compositaWord.equals('一応'),
              ))
              .getSingle();
      expect(card.repetitions, 1); // was 0 (pre-seeded), graded q=4 (Good) → 1
      expect(card.lastReviewedAt, isNotNull);

      // Passing it recorded 一応 specifically as a covered reading -- this
      // is the "C+D" composita/sentence tracking store (Statistics-only,
      // doesn't gate green -- see ReviewRepository.overallProgress).
      final reviewRepo = ReviewRepository(deps.database);
      final tested = await reviewRepo.testedCompositaWordsFor(
        {'一'},
        CompositaDirection.reading,
      );
      expect(tested['一'], contains('一応'));
    },
  );
}
