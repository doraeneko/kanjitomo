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

      // deps.load(loadAll: true) seeds kanji_notes from the bundled stories.json (see
      // AppDatabase.seedStories) -- 一's keyword is "eins" (a real
      // karten.json entry split on its first colon), with an empty story
      // body, so the keyword field starts pre-filled (as read-only Text)
      // and the story field starts empty (showing hint text).
      //
      // Fields are now read-only by default -- keyword shows as plain Text,
      // story shows hint text. Tap the edit icon to switch to a TextField.
      expect(find.text('eins'), findsOneWidget);
      // No TextFields initially — both fields are in read-only mode.
      expect(find.byType(TextField), findsNothing);

      // Tap the story edit icon to enter editing mode, then type.
      final editIcons = find.byIcon(Icons.edit);
      expect(editIcons, findsNWidgets(2)); // keyword + story edit icons
      await tester.tap(editIcons.at(1)); // second icon = story
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'My test mnemonic');
      await tester.pump();

      expect(find.text('My test mnemonic'), findsOneWidget);
      // Keyword still displayed as read-only Text, unaffected.
      expect(find.text('eins'), findsOneWidget);
    },
  );
}
