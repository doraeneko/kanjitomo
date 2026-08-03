import '../../test_helpers.dart';
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
// elsewhere in this suite that a second runAsync-wrapped real asset load in
// the same test *process* can hang, so each test needing a full
// AppDependencies load gets its own file.
void main() {
  testWidgets(
    'custom mode only introduces readingCloze/drawInSentence for a '
    'character once a CustomComposita word has been explicitly picked for '
    'it -- unlike JLPT mode, there is no ceiling-based "unrestricted" '
    'fallback',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final deps = AppDependencies(
        database: AppDatabase.forTesting(NativeDatabase.memory()),
      );
      await tester.runAsync(() => deps.load());
      await deps.studyScope.update(
        const StudyScope(
          mode: StudyScopeMode.custom,
          customCharacters: {'一'},
        ),
      );

      // Pre-pass A (drawFromMeaning) and B (kanjiRecognition) for 一 so
      // the A→B→C+D introduction gating (see _introduceNewCardsForToday)
      // is already satisfied -- this test's focus is the customComposita
      // restriction on C+D, not the card-type ordering gate.
      final reviewRepo = ReviewRepository(deps.database);
      await reviewRepo.introduceNewCards(
        const StudyScope(
          mode: StudyScopeMode.custom,
          customCharacters: {'一'},
        ),
        CardType.drawFromMeaning,
        limit: 1,
      );
      await reviewRepo.gradeCard(
        character: '一',
        cardType: CardType.drawFromMeaning,
        quality: 4,
      );
      await reviewRepo.introduceNewCards(
        const StudyScope(
          mode: StudyScopeMode.custom,
          customCharacters: {'一'},
        ),
        CardType.kanjiRecognition,
        limit: 1,
      );
      await reviewRepo.gradeCard(
        character: '一',
        cardType: CardType.kanjiRecognition,
        quality: 4,
      );

      await tester.pumpWidget(
        testApp(home: ReviewSessionScreen(deps: deps)),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      // Nothing picked yet -- A and B exist (pre-passed above), but the
      // composita-needed types (readingCloze, drawInSentence) are not
      // introduced because no CustomComposita word has been picked.
      var cards = await deps.database.select(deps.database.reviewCards).get();
      expect(cards.map((c) => c.cardType).toSet(), {
        CardType.drawFromMeaning,
        CardType.kanjiRecognition,
      });

      // Now explicitly pick 一向 for 一 (a real composita+sentence pair,
      // used elsewhere in this suite -- see
      // review_session_reading_cloze_test.dart), and start a fresh
      // session.
      await reviewRepo.addCustomComposita('一', '一向');

      // A distinct key forces a fresh State (and initState -> _loadQueue)
      // instead of Flutter reusing the previous element/state in place --
      // same widget type at the same tree position would otherwise just
      // call didUpdateWidget, never re-running _loadQueue's up-front
      // _customComposita load.
      await tester.pumpWidget(
        testApp(
          home: ReviewSessionScreen(key: const ValueKey('second'), deps: deps),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      cards = await deps.database.select(deps.database.reviewCards).get();
      expect(cards.map((c) => c.cardType).toSet(), {
        CardType.drawFromMeaning,
        CardType.kanjiRecognition,
        CardType.readingCloze,
        CardType.drawInSentence,
      });
    },
  );
}
