import '../../test_helpers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kanjitomo/app_dependencies.dart';
import 'package:kanjitomo/core/db/app_database.dart';
import 'package:kanjitomo/features/review/review_start_screen.dart';
import 'package:kanjitomo/features/review/study_scope.dart';

// Own file: confirmed elsewhere in this suite that a second runAsync-wrapped
// real asset load in the same test *process* can hang, so each test needing a
// full AppDependencies load gets its own file.
void main() {
  testWidgets(
    'when nothing is due, shows "Learn N new kanji" with a preview of which '
    'kanji will be introduced',
    (tester) async {
      SharedPreferences.setMockInitialValues({'review.daily_new_cap': 3});
      final deps = AppDependencies(
        database: AppDatabase.forTesting(NativeDatabase.memory()),
      );
      await tester.runAsync(() => deps.load());
      await deps.studyScope.update(const StudyScope(jlptLevels: {5}));

      await tester.pumpWidget(testApp(home: ReviewStartScreen(deps: deps)));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      // Fresh DB: 0 due, so button should say "Learn 3 new kanji".
      expect(find.text('0 due now'), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'Learn 3 new kanji'),
        findsOneWidget,
      );

      // The preview should show exactly 3 kanji characters (the next 3 in
      // RTK order that would be introduced as drawFromMeaning cards).
      // We can't predict which exact kanji they are without knowing the RTK
      // ordering in the test DB, but we can verify the preview Wrap exists
      // with the right count of 22pt Text widgets (the kanji preview style).
      final kanjiTexts = tester.widgetList<Text>(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.style?.fontSize == 22 &&
              (w.data?.length ?? 0) == 1,
        ),
      );
      expect(kanjiTexts.length, 3);
    },
  );
}
