import '../../test_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kanjitomo/features/kanji_browser/kanji_detail_content.dart';
import 'package:kanjitomo/features/review/furigana_sentence.dart';

import 'kanji_browser_test_helpers.dart';

// Own file (not grouped with kanji_detail_story_autosave_test.dart): each
// test needing a real asset load via loadTestDeps gets its own process --
// see that helper's own doc comment on the "second runAsync load hangs"
// gotcha.
void main() {
  testWidgets(
    'shows example sentences for the displayed composita, as the final '
    'section, with furigana and translation',
    (tester) async {
      final deps = await loadTestDeps(tester);
      await tester.pumpWidget(
        testApp(
          home: Scaffold(body: KanjiDetailContent(character: '一', deps: deps)),
        ),
      );
      await tester.pump();

      // Among 一's top-ranked (by rankComposita) displayed composita, 一緒
      // (いっしょ) has real sentence coverage -- confirmed directly against
      // the bundled assets (unlike review's own sentence-selection logic,
      // which picks 一向 for a different, ceiling-restricted scope, this
      // screen's display ranking is plain rankComposita, so the two don't
      // pick the same word).
      expect(find.text('Example sentences'), findsOneWidget);
      expect(find.text('一緒'), findsWidgets); // once in Composita, once here
      expect(find.byType(FuriganaSentence), findsWidgets);
      expect(find.text('Would you play with me?'), findsOneWidget);
    },
  );
}
