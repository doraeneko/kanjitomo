import '../../test_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kanjitomo/features/kanji_browser/kanji_detail_content.dart';

import 'kanji_browser_test_helpers.dart';

// This only covers the widget's own local behavior (initial state, text
// entry updates the field). It deliberately does NOT drive the debounced
// save through to a persisted read: confirmed directly (multiple times,
// including after removing a persistent stream subscription that looked
// like a plausible culprit) that triggering the debounce Timer via
// tester.pump() and then waiting -- even via tester.runAsync() -- for the
// resulting real drift write to complete and be readable again hangs
// indefinitely in this fake-async widget-test harness. The same
// upsertNote()/watchNote() round-trip works fine in a plain (non-widget)
// test -- see review_repository_test.dart's "kanji_notes upsert and watch
// round-trip" -- which is where the actual save-persists coverage lives;
// this file stays widget-local.
void main() {
  testWidgets(
    'keyword/story fields start pre-filled with the seeded values and '
    'reflect typed text independently',
    (tester) async {
      final deps = await loadTestDeps(tester);
      // Scaffold, not bare KanjiDetailContent: TextField needs a Material
      // ancestor, which production always provides (KanjiDetailScreen's own
      // Scaffold, or showModalBottomSheet's built-in Material wrapper).
      await tester.pumpWidget(
        testApp(
          home: Scaffold(body: KanjiDetailContent(character: '一', deps: deps)),
        ),
      );
      await tester.pump();

      // deps.load() seeds kanji_notes from the bundled stories.json (see
      // AppDatabase.seedStories) -- 一's keyword is "eins" (a real
      // karten.json entry split on its first colon), with an empty story
      // body, so the keyword field starts pre-filled and the story field
      // starts empty.
      expect(find.widgetWithText(TextField, 'eins'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));

      // The story field is the second one (keyword renders first).
      await tester.enterText(
        find.byType(TextField).at(1),
        'My test mnemonic',
      );
      await tester.pump();

      expect(find.text('My test mnemonic'), findsOneWidget);
      // Unaffected by editing the story field.
      expect(find.widgetWithText(TextField, 'eins'), findsOneWidget);
    },
  );
}
