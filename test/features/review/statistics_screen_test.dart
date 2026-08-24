import '../../test_helpers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kanjitomo/app_dependencies.dart';
import 'package:kanjitomo/core/first_time_dialog.dart';
import 'package:kanjitomo/core/db/app_database.dart';
import 'package:kanjitomo/core/db/tables.dart';
import 'package:kanjitomo/features/review/review_repository.dart';
import 'package:kanjitomo/features/review/statistics_screen.dart';
import 'package:kanjitomo/features/review/study_scope.dart';

// Own file: a full AppDependencies load, same "second real asset load in
// the same test process can be unreliable" reasoning as elsewhere in this
// suite (see stroke_order_test_helpers.dart).
void main() {
  testWidgets('shows known/missed/not-started counts and resets on confirm', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({...ftdSuppressedPrefs});
    final deps = AppDependencies(
      database: AppDatabase.forTesting(NativeDatabase.memory()),
    );
    await tester.runAsync(() => deps.load());
    // Statistics is scoped to the current StudyScope (see
    // statistics_screen.dart) -- 一 needs to actually be in scope for its
    // readingCloze row to count. No compositaCeiling is set, so the
    // composita/sentence (C+D) row is expected to show 0 testable.
    await deps.studyScope.update(const StudyScope(characters: {'一'}));

    final repo = ReviewRepository(deps.database);
    await repo.gradeCard(character: '一', cardType: CardType.readingCloze, quality: 4);

    await tester.pumpWidget(testApp(home: StatisticsScreen(deps: deps)));
    // Loading stats does real drift queries in initState -- same gotcha as
    // everywhere else in this suite: plain tester.pump() runs in a
    // FakeAsync zone that never actually elapses real wall-clock time.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();

    expect(find.text('Kanji recognition'), findsOneWidget);
    expect(find.text('Draw from meaning'), findsOneWidget);
    expect(find.text('Reading (composita/sentence)'), findsOneWidget);
    expect(find.text('Draw in sentence (composita/sentence)'), findsOneWidget);
    // 一's readingCloze row is "learning" (repetitions=1 after a single
    // q=4 grade, below the knownThreshold of 2 consecutive correct).
    expect(find.textContaining('Learning: 1'), findsAtLeastNWidgets(1));

    // The composita/sentence (C+D) row shows up separately, with nothing
    // testable since no compositaCeiling was ever chosen for this JLPT
    // scope.
    expect(find.text('Composita/sentence testing'), findsOneWidget);
    expect(find.textContaining('0 testable words'), findsOneWidget);

    // The new composita/sentence row pushes "Reset statistics" further
    // down than the default test viewport shows.
    await tester.ensureVisible(
      find.widgetWithText(OutlinedButton, 'Reset statistics'),
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Reset statistics'));
    await tester.pump();
    expect(find.text('Reset'), findsOneWidget); // confirmation dialog open

    await tester.tap(find.widgetWithText(TextButton, 'Reset'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();

    final cards = await deps.database.select(deps.database.reviewCards).get();
    expect(cards, isEmpty);
  });
}
