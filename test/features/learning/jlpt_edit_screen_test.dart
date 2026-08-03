import '../../test_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kanjitomo/features/learning/jlpt_edit_screen.dart';
import 'package:kanjitomo/features/review/study_scope.dart';

import '../kanji_browser/kanji_browser_test_helpers.dart';

void main() {
  testWidgets(
    'level chips and the composita ceiling update StudyScope directly '
    '-- no RTK option or chunk controls offered',
    (tester) async {
      final deps = await loadTestDeps(tester);
      deps.proStatus.isProUnlocked.value = true;
      await deps.studyScope.update(const StudyScope(jlptLevels: {5}));

      await tester.pumpWidget(testApp(home: JlptEditScreen(deps: deps)));
      await tester.pump();

      expect(find.text('RTK'), findsNothing);
      expect(find.textContaining('kanji in scope'), findsOneWidget);
      // No chunk controls should be present.
      expect(find.text('Chunk size:'), findsNothing);

      // Selecting a second level updates the scope immediately.
      await tester.tap(find.widgetWithText(FilterChip, 'N4'));
      await tester.pump();
      expect(deps.studyScope.scope.value.jlptLevels, {5, 4});

      // Composita ceiling: off by default, set-able independent of the
      // kanji level(s) selected above.
      expect(deps.studyScope.scope.value.compositaCeiling, isNull);
      await tester.tap(find.widgetWithText(ChoiceChip, 'N2'));
      await tester.pump();
      expect(deps.studyScope.scope.value.compositaCeiling, 2);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Off'));
      await tester.pump();
      expect(deps.studyScope.scope.value.compositaCeiling, isNull);
    },
  );
}
