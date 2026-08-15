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
    'drawFromMeaning shows the seeded story, and "Don\'t know" reveals full '
    'kanji info as a miss',
    (tester) async {
      SharedPreferences.setMockInitialValues({...ftdSuppressedPrefs});
      final deps = AppDependencies(
        database: AppDatabase.forTesting(NativeDatabase.memory()),
      );
      await tester.runAsync(() => deps.load());
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

      // Review starts directly (no slideshow -- that's in AddRemoveScreen now).
      expect(find.text('Review \u2014 1/1 \u2014 New'), findsOneWidget);
      // Only the bundled keyword (seeded into kanji_notes on first load,
      // see AppDatabase.seedStories) shows up alongside the readings --
      // not the fuller story, which would give too much away pre-draw.
      expect(find.textContaining('Keyword: eins'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, "Don't know"), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, "Don't know"));
      await tester.pump();

      // No "Not quite." text on any miss (including "Don't know") -- the
      // red X icon plus the revealed answer below already say it, and
      // skipping the text saves vertical space.
      expect(find.text('Not quite.'), findsNothing);
      expect(find.text('Answer: 一'), findsOneWidget);
      expect(find.textContaining('You picked:'), findsNothing); // no pick made

      // Details auto-expand on wrong answers -- no "Show details" tap needed.
      await tester.pump(const Duration(milliseconds: 300));

      // Full kanji-editor info shown automatically -- same KanjiDetailContent
      // widget as the kanji browser/lookup detail screen. Readings render via
      // raw RichText/TextSpan, so check the rendered plain text directly.
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
