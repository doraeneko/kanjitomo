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
    'drawFromMeaning shows the seeded story, and "Don\'t know" reveals full '
    'kanji info as a miss',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final deps = AppDependencies(
        database: AppDatabase.forTesting(NativeDatabase.memory()),
      );
      await tester.runAsync(() => deps.load());
      // rtkMaxIndex: 1 keeps the scope down to just 一 (rtkIndex 1), so the
      // freshly-introduced drawFromMeaning card is unambiguous.
      await deps.studyScope.update(
        const StudyScope(mode: StudyScopeMode.rtk, rtkMaxIndex: 1),
      );

      // 一 also has sentence coverage, so _loadQueue()'s own
      // introduceNewCards would otherwise seed readingCloze/drawInSentence/
      // kanjiRecognition cards for it too, and they'd compete with the
      // drawFromMeaning card this test cares about for "which card is shown
      // first". Far-future due dates keep them out of introduceNewCards'
      // and dueCards' way -- repetitions: 2 ("established") also keeps them
      // out of dueCards' separate always-include-fragile-cards allowance,
      // since otherwise a never-graded (repetitions 0, still "fragile") row
      // would be pulled back in regardless of its due date. Same technique
      // as review_session_reading_cloze_test.dart.
      final farFuture = DateTime.now().add(const Duration(days: 30));
      for (final otherType in [
        CardType.readingCloze,
        CardType.drawInSentence,
        CardType.kanjiRecognition,
      ]) {
        await deps.database
            .into(deps.database.reviewCards)
            .insert(
              ReviewCardsCompanion.insert(
                character: '一',
                cardType: otherType,
                dueDate: farFuture,
                repetitions: const Value(2),
              ),
            );
      }

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

      // 一 was freshly introduced by _introduceNewCardsForToday (the
      // drawFromMeaning card), so the new-kanji slideshow appears first.
      expect(find.text('New kanji (1/1)'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Start review'));
      await tester.pump();

      expect(find.text('Review (1/1) \u2014 New'), findsOneWidget);
      // Only the bundled keyword (seeded into kanji_notes on first load,
      // see AppDatabase.seedStories) shows up alongside the readings --
      // not the fuller story, which would give too much away pre-draw.
      expect(find.textContaining('Keyword: eins'), findsOneWidget);
      expect(find.widgetWithText(TextButton, "Don't know"), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, "Don't know"));
      await tester.pump();

      // No "Not quite." text on any miss (including "Don't know") -- the
      // red X icon plus the revealed answer below already say it, and
      // skipping the text saves vertical space.
      expect(find.text('Not quite.'), findsNothing);
      expect(find.text('Answer: 一'), findsOneWidget);
      expect(find.textContaining('You picked:'), findsNothing); // no pick made

      // Full kanji-editor info shown on a miss -- same KanjiDetailContent
      // widget as the kanji browser/lookup detail screen, not just the
      // bare character. Readings render via raw RichText/TextSpan (see
      // KanjiDetailContent's _InfoLine), not a plain Text widget, so check
      // the rendered plain text directly rather than find.textContaining.
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('イチ'),
        ),
        findsOneWidget,
      );
      expect(find.text('Keyword', skipOffstage: false), findsOneWidget);
      expect(find.text('Story', skipOffstage: false), findsOneWidget);
      // The editable keyword + story fields.
      expect(find.byType(TextField), findsNWidgets(2));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pump();

      final card =
          await (deps.database.select(deps.database.reviewCards)..where(
                (t) =>
                    t.character.equals('一') &
                    t.cardType.equalsValue(CardType.drawFromMeaning),
              ))
              .getSingle();
      expect(card.repetitions, 0); // quality=0 is a fail
      expect(card.lapses, 0); // wasn't "established" yet, so no lapse
    },
  );
}
