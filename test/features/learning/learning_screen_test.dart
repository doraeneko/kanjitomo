import '../../test_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kanjitomo/core/db/tables.dart';

import 'package:kanjitomo/features/learning/add_remove_screen.dart';
import 'package:kanjitomo/features/learning/learning_screen.dart';
import 'package:kanjitomo/features/review/review_repository.dart';
import 'package:kanjitomo/features/review/review_session_screen.dart';
import 'package:kanjitomo/features/review/statistics_screen.dart';
import 'package:kanjitomo/features/review/study_scope.dart';

import '../kanji_browser/kanji_browser_test_helpers.dart';

void main() {
  testWidgets(
    'LearningScreen shows pool stats, action buttons, and navigates correctly',
    (tester) async {
      // Suppress RenderFlex overflow errors that surface when navigating
      // to screens whose layout is tighter than the 800x600 test viewport.
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exception.toString().contains('overflowed')) return;
        oldHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldHandler);

      final deps = await loadTestDeps(tester);

      // Add kanji to the pool so Review can open.
      await deps.studyScope.update(const StudyScope(characters: {'一'}));
      final reviewRepo = ReviewRepository(deps.database);
      await reviewRepo.introduceCardsForCharacters({'一'});

      await tester.pumpWidget(testApp(home: LearningScreen(deps: deps)));
      // _loadCounts() fires real DB queries in initState — need runAsync
      // for them to resolve, then pumpAndSettle for the setState rebuild.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pumpAndSettle();

      // No old mode labels.
      expect(find.text('JLPT mode'), findsNothing);
      expect(find.text('Custom mode'), findsNothing);

      // Top action buttons are present.
      expect(find.byKey(const ValueKey('review')), findsOneWidget);
      expect(find.byKey(const ValueKey('add-remove')), findsOneWidget);
      expect(find.byKey(const ValueKey('quiz')), findsOneWidget);

      // Tap Add/Remove > opens AddRemoveScreen.
      await tester.tap(find.byKey(const ValueKey('add-remove')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AddRemoveScreen), findsOneWidget);
      await tester.pageBack();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pumpAndSettle();

      // Scroll to statistics button and tap it.
      final statsButton = find.byKey(const ValueKey('statistics'));
      await tester.ensureVisible(statsButton);
      await tester.pumpAndSettle();
      await tester.tap(statsButton);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(StatisticsScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Review button opens the card-kind sheet and starts a filtered session',
    (tester) async {
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exception.toString().contains('overflowed')) return;
        oldHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldHandler);

      final deps = await loadTestDeps(tester);
      await deps.studyScope.update(const StudyScope(characters: {'一'}));
      await ReviewRepository(deps.database).introduceCardsForCharacters({'一'});

      await tester.pumpWidget(testApp(home: LearningScreen(deps: deps)));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pumpAndSettle();

      // Only one review button now.
      expect(find.byKey(const ValueKey('kanji-only')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('review')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();

      // All four kinds offered, all ticked by default.
      for (final type in CardType.values) {
        final tile = find.byKey(ValueKey('review-type-${type.name}'));
        expect(tile, findsOneWidget);
        expect(tester.widget<CheckboxListTile>(tile).value, isTrue);
      }

      // Untick both composita kinds.
      await tester.tap(find.byKey(const ValueKey('review-type-drawInSentence')));
      await tester.tap(find.byKey(const ValueKey('review-type-readingCloze')));
      // RTK order is the default; switch new cards to random.
      await tester.tap(find.text('Random'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('review-start')));
      // Sheet closes, then the selection is saved before the push.
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(milliseconds: 200));
      }

      final session = tester.widget<ReviewSessionScreen>(
        find.byType(ReviewSessionScreen),
      );
      expect(session.cardTypes,
          {CardType.drawFromMeaning, CardType.kanjiRecognition});
      expect(session.newCardOrder, NewCardOrder.random);

      // Selection is remembered for next time.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('review.card_types')?.toSet(),
          {'drawFromMeaning', 'kanjiRecognition'});
      expect(prefs.getString('review.new_card_order'), 'random');
    },
  );

  testWidgets(
    'Review button, sheet Start button and session header show the same count',
    (tester) async {
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exception.toString().contains('overflowed')) return;
        oldHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldHandler);

      final deps = await loadTestDeps(tester);
      // 3 kanji x 2 kanji cards = 6 new cards, but the remembered selection
      // is kanji recognition only -> 3. (The button used to count all kinds.)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('review.card_types', ['kanjiRecognition']);
      await deps.studyScope.update(const StudyScope(characters: {'一', '二', '三'}));
      await ReviewRepository(deps.database)
          .introduceCardsForCharacters({'一', '二', '三'});

      await tester.pumpWidget(testApp(home: LearningScreen(deps: deps)));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Review (3)'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('review')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Start (3)'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('review-start')));
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.text('Review \u2014 1/3 \u2014 New'), findsOneWidget);
    },
  );
}
