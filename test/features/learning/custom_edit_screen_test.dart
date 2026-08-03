import '../../test_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kanjitomo/features/learning/custom_edit_screen.dart';
import 'package:kanjitomo/features/review/draw_and_pick.dart';
import 'package:kanjitomo/features/review/study_scope.dart';

import '../kanji_browser/kanji_browser_test_helpers.dart';

void main() {
  testWidgets(
    'shows the draw-to-add editor; existing entries can be long-press '
    'removed and the set can be cleared',
    (tester) async {
      // The default 800x600 test surface is shorter than a real phone --
      // the fixed-size (260px) drawing canvas plus this screen's own
      // chrome genuinely doesn't fit in 600px. The canvas is deliberately
      // NOT wrapped in a SingleChildScrollView (see custom_edit_screen.dart
      // 's own doc comment -- a scrollable ancestor's drag recognizer
      // competes with the canvas's raw pointer Listener for vertical
      // strokes), so unlike most other screens in this suite, this one
      // can't just rely on scrolling to paper over a cramped test
      // viewport. A real phone has comfortably more height than this ever
      // needs.
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final deps = await loadTestDeps(tester);
      // Pre-seed a custom set in custom mode: the "draw a kanji, pick from
      // top-3" add mechanic needs a real, loaded recognizer to actually
      // recognize a stroke, which -- like every other DrawAndPickWidget
      // caller in this app -- is verified manually on-device rather than
      // simulated in a widget test. What's tested here is everything
      // around that mechanic: the editor appearing, removing existing
      // entries, and clearing.
      await deps.studyScope.update(
        const StudyScope(
          mode: StudyScopeMode.custom,
          customCharacters: {'一', '二'},
        ),
      );

      await tester.pumpWidget(testApp(home: CustomEditScreen(deps: deps)));
      await tester.pump();

      expect(find.textContaining('Draw a kanji to add it'), findsOneWidget);
      expect(find.byType(DrawAndPickWidget), findsOneWidget);
      expect(
        find.textContaining('Your custom set (tap to edit'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('remove-一')), findsOneWidget);
      expect(find.byKey(const ValueKey('remove-二')), findsOneWidget);

      // Long-press an existing entry to remove it. The remove-list is its
      // own scrollable region, so the entry may start below the test
      // viewport's fold.
      await tester.ensureVisible(find.byKey(const ValueKey('remove-一')));
      await tester.pump();
      await tester.longPress(find.byKey(const ValueKey('remove-一')));
      await tester.pump();
      expect(deps.studyScope.scope.value.customCharacters, {'二'});
      expect(find.byKey(const ValueKey('remove-一')), findsNothing);

      // Clear requires confirmation, and is disabled once the set is
      // already empty.
      await tester.tap(find.widgetWithText(TextButton, 'Clear'));
      await tester.pump();
      expect(find.text('Clear custom set?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Clear').last);
      await tester.pump();
      expect(deps.studyScope.scope.value.customCharacters, isEmpty);
      expect(find.textContaining('Your custom set is empty'), findsOneWidget);
      final clearButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Clear'),
      );
      expect(clearButton.onPressed, isNull);
    },
  );

  testWidgets(
    'tapping an entry opens kanji detail + composita picker; checking a '
    'word persists it via CustomComposita and updates the badge count',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final deps = await loadTestDeps(tester);
      await deps.studyScope.update(
        const StudyScope(
          mode: StudyScopeMode.custom,
          customCharacters: {'一'},
        ),
      );

      await tester.pumpWidget(testApp(home: CustomEditScreen(deps: deps)));
      await tester.pump();
      // customCompositaForCharacters (initState) does real async DB I/O --
      // same tester.runAsync() gotcha as everywhere else in this suite.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();

      // No badge yet -- nothing picked for 一.
      expect(find.text('1'), findsNothing);

      // Tap opens the combined kanji detail + composita picker dialog.
      await tester.tap(find.byKey(const ValueKey('remove-一')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      // pump() rather than pumpAndSettle() -- KanjiDetailContent's
      // StrokeOrderView runs a looping animation that never settles.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('一: Composita for testing'), findsOneWidget);
      final checkbox = find.byType(CheckboxListTile).first;
      final tile = tester.widget<CheckboxListTile>(checkbox);
      expect(tile.value, isFalse); // nothing selected yet

      // The checkbox may be below the fold inside the DraggableScrollableSheet.
      await tester.ensureVisible(checkbox);
      await tester.pump();
      await tester.tap(checkbox);
      await tester.pump();
      expect(
        tester.widget<CheckboxListTile>(checkbox).value,
        isTrue,
      );

      // Close the sheet -- badge count refreshes to reflect the pick.
      // Navigate back rather than tapping outside, since the nearly
      // full-screen DraggableScrollableSheet may not leave a tap target.
      Navigator.of(tester.element(find.text('一: Composita for testing'))).pop();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('1'), findsOneWidget); // badge on the 一 cell
    },
  );
}
