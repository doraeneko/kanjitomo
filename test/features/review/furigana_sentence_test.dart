import '../../test_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanjitomo/data/sentences_repository.dart';
import 'package:kanjitomo/features/review/furigana_sentence.dart';

void main() {
  const tokens = [
    SentenceToken(surface: '一番', reading: 'いちばん', isTarget: true),
    SentenceToken(surface: '乗り', reading: 'のり', isTarget: false),
    SentenceToken(surface: 'だ', reading: 'だ', isTarget: false),
    SentenceToken(surface: '。', reading: '', isTarget: false),
  ];

  testWidgets('shows base text and readings for every token by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(home: Scaffold(body: FuriganaSentence(tokens: tokens))),
    );

    expect(find.text('一番'), findsOneWidget);
    expect(find.text('いちばん'), findsOneWidget);
    expect(find.text('乗り'), findsOneWidget); // base text: the whole word
    // Ruby: only "の", not "のり" -- 乗り's trailing り is already visible
    // okurigana, so standard furigana convention doesn't repeat it in the
    // ruby (乗[の]り, not 乗[のり]り).
    expect(find.text('の'), findsOneWidget);
    expect(find.text('のり'), findsNothing);
    // reading == surface (no real furigana needed) or empty -- not shown as text.
    expect(find.text('だ'), findsOneWidget); // base text still shown
    expect(find.text('。'), findsOneWidget);
  });

  testWidgets('hideTargetReading blanks only the target furigana', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        home: Scaffold(
          body: FuriganaSentence(tokens: tokens, hideTargetReading: true),
        ),
      ),
    );

    expect(find.text('一番'), findsOneWidget); // base text still shown
    expect(find.text('いちばん'), findsNothing); // reading hidden
    // Non-target reading unaffected by hideTargetReading -- still shown,
    // trailing り stripped from the ruby same as always (see the
    // "shows base text and readings" test above).
    expect(find.text('の'), findsOneWidget);
  });

  testWidgets('targetReplacement swaps the target base text for a widget', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        home: Scaffold(
          body: FuriganaSentence(
            tokens: tokens,
            targetReplacement: const Icon(Icons.edit),
          ),
        ),
      ),
    );

    expect(find.text('一番'), findsNothing); // base text replaced
    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.text('乗り'), findsOneWidget); // non-target token unaffected
  });

  testWidgets(
    'targetCharacter replaces only the matching character within a multi-kanji compound',
    (tester) async {
      await tester.pumpWidget(
        testApp(
          home: Scaffold(
            body: FuriganaSentence(
              tokens: tokens,
              targetCharacter: '番', // 一番: only 番 is under test, not 一
              targetReplacement: const Icon(Icons.edit),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.edit), findsOneWidget);
      // The other kanji in the same compound word must stay visible --
      // this is the exact gap the "other kanji for compositas" feedback
      // flagged: blanking the whole token hides kanji not under test.
      expect(find.text('一'), findsOneWidget);
      expect(find.text('番'), findsNothing);
      expect(find.text('一番'), findsNothing); // not shown as one merged unit
    },
  );

  testWidgets(
    "targetCharacter's ruby strips trailing okurigana already visible as "
    "plain text, instead of repeating it -- 一つ/ひとつ shows ruby ひと "
    "above the drawn 一, not the whole word's reading above [box]つ",
    (tester) async {
      const withOkurigana = [
        SentenceToken(surface: '一つ', reading: 'ひとつ', isTarget: true),
      ];
      await tester.pumpWidget(
        testApp(
          home: Scaffold(
            body: FuriganaSentence(
              tokens: withOkurigana,
              targetCharacter: '一',
              targetReplacement: const Icon(Icons.edit),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.text('つ'), findsOneWidget); // okurigana still shown as-is
      expect(find.text('ひと'), findsOneWidget); // ruby: kanji-only portion
      expect(find.text('ひとつ'), findsNothing); // not the whole word's reading
    },
  );

  testWidgets(
    'falls back to the full reading when there is no trailing kana to '
    'strip, or it doesn\'t match the reading\'s own tail',
    (tester) async {
      // 一番: no trailing kana in the surface at all.
      await tester.pumpWidget(
        testApp(
          home: Scaffold(
            body: FuriganaSentence(
              tokens: tokens,
              targetCharacter: '番',
              targetReplacement: const Icon(Icons.edit),
            ),
          ),
        ),
      );
      expect(find.text('いちばん'), findsOneWidget);
    },
  );

  testWidgets('highlightTargetBox draws a red border around the target base text', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        home: Scaffold(
          body: FuriganaSentence(tokens: tokens, highlightTargetBox: true),
        ),
      ),
    );

    final container = tester.widget<Container>(
      find.ancestor(
        of: find.text('一番'),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.border!.top.color, Colors.red);
  });
}
