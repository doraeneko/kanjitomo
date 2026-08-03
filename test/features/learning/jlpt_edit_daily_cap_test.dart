import '../../test_helpers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kanjitomo/app_dependencies.dart';
import 'package:kanjitomo/core/db/app_database.dart';
import 'package:kanjitomo/features/learning/jlpt_edit_screen.dart';
import 'package:kanjitomo/features/review/study_scope.dart';

void main() {
  testWidgets(
    '"New kanji per day" field appears on JLPT edit screen and persists '
    'changes to SharedPreferences',
    (tester) async {
      SharedPreferences.setMockInitialValues({'review.daily_new_cap': 5});
      final deps = AppDependencies(
        database: AppDatabase.forTesting(NativeDatabase.memory()),
      );
      await tester.runAsync(() => deps.load());
      await deps.studyScope.update(const StudyScope(jlptLevels: {5}));

      await tester.pumpWidget(testApp(home: JlptEditScreen(deps: deps)));
      // Let _loadDailyNewCap resolve.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();

      expect(find.text('New kanji per day:'), findsOneWidget);

      // The field should show the stored value.
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, '5');

      // Type a new value.
      await tester.enterText(find.byType(TextField), '15');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );

      // Verify it was persisted.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('review.daily_new_cap'), 15);
    },
  );
}
