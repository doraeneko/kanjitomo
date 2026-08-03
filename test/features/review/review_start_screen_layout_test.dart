import '../../test_helpers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kanjitomo/app_dependencies.dart';
import 'package:kanjitomo/core/db/app_database.dart';
import 'package:kanjitomo/features/review/review_start_screen.dart';
import 'package:kanjitomo/features/review/study_scope.dart';

// Own file, not grouped with review_start_screen_test.dart/
// review_start_screen_capped_count_test.dart: confirmed elsewhere in this
// suite that a second runAsync-wrapped real asset load in the same test
// *process* can hang, so each test needing a full AppDependencies load gets
// its own file.
void main() {
  testWidgets(
    "'Start Review' is visible without scrolling",
    (tester) async {
      SharedPreferences.setMockInitialValues({});
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

      // The start/learn button should always be visible without scrolling, now
      // that the (potentially very long) kanji-in-scope grid has been removed.
      // With 0 due (fresh DB), the label is "Learn N new kanji" instead of
      // "Start Review".
      expect(
        find.byType(ElevatedButton),
        findsOneWidget,
      );
    },
  );
}
