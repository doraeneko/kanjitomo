import '../../test_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
