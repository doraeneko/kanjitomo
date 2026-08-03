import '../../test_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kanjitomo/features/lookup/word_lookup_screen.dart';
import 'package:kanjitomo/features/review/draw_and_pick.dart';

import '../kanji_browser/kanji_browser_test_helpers.dart';

void main() {
  testWidgets(
    'typing a word looks it up in JMdict; Clear resets the word and results',
    (tester) async {
      final deps = await loadTestDeps(tester);
      await tester.pumpWidget(
        testApp(home: WordLookupScreen(deps: deps)),
      );
      await tester.pump();

      // The draw-to-add mechanic needs a real, loaded recognizer to
      // actually recognize a stroke -- like every other DrawAndPickWidget
      // caller in this app, that's verified manually on-device rather than
      // simulated in a widget test (see kanji_browser_custom_set_test.dart).
      // What's tested here is everything around it: the word field, the
      // lookup itself (including live re-lookup as the field changes), and
      // clearing.
      expect(find.byType(DrawAndPickWidget), findsOneWidget);

      await tester.enterText(find.byType(TextField), '日本');
      await tester.pump();

      expect(find.textContaining('にほん'), findsOneWidget);
      expect(find.textContaining('Japan'), findsOneWidget);

      // Editing further re-runs the lookup against the new word, not the
      // old one.
      await tester.enterText(find.byType(TextField), '存在しない単語999');
      await tester.pump();
      expect(find.textContaining('Japan'), findsNothing);
      expect(find.textContaining('No JMdict entry'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, isEmpty);
      expect(find.textContaining('No JMdict entry'), findsNothing);
    },
  );

  testWidgets(
    'tapping the copy icon on a result copies the word to the clipboard',
    (tester) async {
      final deps = await loadTestDeps(tester);
      await tester.pumpWidget(
        testApp(home: WordLookupScreen(deps: deps)),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), '日本');
      await tester.pump();

      String? copiedText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.tap(find.byIcon(Icons.copy));
      await tester.pump();

      expect(copiedText, '日本');
      expect(find.textContaining('Copied "日本"'), findsOneWidget);
    },
  );

  testWidgets(
    'returning to the drawing canvas dismisses the word field\'s keyboard '
    '(a lingering focus there caused odd scrolling)',
    (tester) async {
      final deps = await loadTestDeps(tester);
      await tester.pumpWidget(
        testApp(home: WordLookupScreen(deps: deps)),
      );
      await tester.pump();

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);

      await tester.tapAt(
        tester.getCenter(find.byKey(const Key('drawing_canvas'))),
      );
      await tester.pump();
      expect(tester.testTextInput.isVisible, isFalse);
    },
  );
}
