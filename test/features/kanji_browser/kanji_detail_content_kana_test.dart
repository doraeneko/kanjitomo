import '../../test_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kanjitomo/features/kanji_browser/kanji_detail_content.dart';

import 'kanji_browser_test_helpers.dart';

// Own file (not grouped with kanji_detail_story_autosave_test.dart): each
// test needing a real asset load via loadTestDeps gets its own process --
// see that helper's own doc comment on the "second runAsync load hangs"
// gotcha.
void main() {
  testWidgets(
    'for a kana character, shows only the character and stroke order -- no '
    'keyword/story/"no dictionary entry" clutter, since kana already are '
    'their own reading and have no on/kun/meaning, mnemonic, or composita',
    (tester) async {
      final deps = await loadTestDeps(tester);
      await tester.pumpWidget(
        testApp(
          home: Scaffold(body: KanjiDetailContent(character: 'あ', deps: deps)),
        ),
      );
      await tester.pump();

      expect(find.text('あ'), findsOneWidget);
      expect(find.text('Stroke order'), findsOneWidget);

      expect(find.textContaining('No dictionary entry'), findsNothing);
      expect(find.text('Keyword'), findsNothing);
      expect(find.text('Story'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Composita'), findsNothing);
      expect(find.text('Example sentences'), findsNothing);
    },
  );
}
