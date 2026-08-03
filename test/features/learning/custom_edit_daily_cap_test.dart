import '../../test_helpers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kanjitomo/app_dependencies.dart';
import 'package:kanjitomo/core/db/app_database.dart';
import 'package:kanjitomo/features/learning/custom_edit_screen.dart';
import 'package:kanjitomo/features/review/study_scope.dart';

void main() {
  testWidgets(
    '"New kanji per day" field appears on custom edit screen, rejects 0, '
    'and persists valid values to SharedPreferences',
    (tester) async {
      // The drawing canvas needs a taller viewport (see
      // custom_edit_screen_test.dart's own comment).
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({'review.daily_new_cap': 7});
      final deps = AppDependencies(
        database: AppDatabase.forTesting(NativeDatabase.memory()),
      );
      await tester.runAsync(() => deps.load());
      await deps.studyScope.update(
        const StudyScope(
          mode: StudyScopeMode.custom,
          customCharacters: {'一', '二'},
        ),
      );

      await tester.pumpWidget(testApp(home: CustomEditScreen(deps: deps)));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();

      expect(find.text('New kanji per day:'), findsOneWidget);

      // Find the daily cap TextField -- it's the one whose controller shows
      // the seeded value "7". There may be other TextFields on this screen
      // (e.g. inside DrawAndPickWidget) but they won't have text "7".
      final allTextFields = find.byType(TextField);
      late Finder capFinder;
      for (var i = 0; i < tester.widgetList(allTextFields).length; i++) {
        final f = allTextFields.at(i);
        final tf = tester.widget<TextField>(f);
        if (tf.controller?.text == '7') {
          capFinder = f;
          break;
        }
      }

      // Typing "0" should be rejected by the input formatter (regex
      // [1-9][0-9]* disallows leading zero).
      await tester.enterText(capFinder, '0');
      await tester.pump();
      final afterZero = tester.widget<TextField>(capFinder);
      // The formatter strips the invalid "0", leaving the field empty.
      expect(afterZero.controller!.text, isEmpty);

      // A valid value persists.
      await tester.enterText(capFinder, '12');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('review.daily_new_cap'), 12);
    },
  );
}
