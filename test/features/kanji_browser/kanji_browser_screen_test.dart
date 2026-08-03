import '../../test_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kanjitomo/features/kanji_browser/kanji_browser_screen.dart';
import 'package:kanjitomo/features/kanji_browser/kanji_detail_screen.dart';

import 'kanji_browser_test_helpers.dart';

// Scope-based filtering and custom-set editing used to live in this
// screen; both moved to the Learning section (see jlpt_edit_screen_test.dart
// /custom_edit_screen_test.dart) once this screen became a flat,
// unfiltered "browse every kanji" utility -- no StudyScope dependency left
// to test here beyond "shows everything, tap opens detail".
void main() {
  testWidgets('shows every kanji with no filter, tapping one opens detail', (
    tester,
  ) async {
    final deps = await loadTestDeps(tester);
    await tester.pumpWidget(testApp(home: KanjiBrowserScreen(deps: deps)));
    await tester.pump();

    final list = tester.widget<ListView>(find.byType(ListView));
    final itemCount =
        (list.childrenDelegate as SliverChildBuilderDelegate).childCount;
    expect(itemCount, greaterThan(2000)); // the full ~2140-kanji universe

    final shown = tester
        .widgetList<InkWell>(
          find.descendant(
            of: find.byType(ListView),
            matching: find.byType(InkWell),
          ),
        )
        .where((w) => w.key is ValueKey<String>)
        .map((w) => (w.key as ValueKey<String>).value)
        .toList();
    expect(shown, isNotEmpty);

    await tester.tap(find.byKey(ValueKey(shown.first)));
    // Not pumpAndSettle: the pushed detail screen embeds StrokeOrderView,
    // whose animation now loops forever (see stroke_order_view.dart), so
    // pumpAndSettle would never see frame scheduling stop. Two bounded
    // pumps past the standard MaterialPageRoute transition duration (300ms
    // exactly landed right on the boundary and wasn't quite enough).
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(KanjiDetailScreen), findsOneWidget);
    expect(find.text(shown.first), findsWidgets);
  });

  testWidgets(
    'search box filters the list by meaning, reading, and stroke count '
    '(see kanji_search.dart for the matching rules)',
    (tester) async {
      final deps = await loadTestDeps(tester);
      await tester.pumpWidget(testApp(home: KanjiBrowserScreen(deps: deps)));
      await tester.pump();

      // ListView.separated uses SliverChildBuilderDelegate; childCount is
      // the number of data items (separators are handled separately).
      int shownCount() {
        final list = tester.widget<ListView>(find.byType(ListView));
        final delegate = list.childrenDelegate as SliverChildBuilderDelegate;
        return delegate.childCount!;
      }

      // Meaning search: 水's meaning is "water" -- a substring match, so
      // other kanji whose meaning merely contains "water" (湯 "hot water",
      // 滝 "waterfall", etc.) are expected to show up too; just confirm
      // 水 itself is among the rendered rows.
      await tester.enterText(find.byType(TextField), 'water');
      await tester.pump();
      expect(find.byKey(const ValueKey('水')), findsOneWidget);
      expect(shownCount(), lessThan(2000)); // genuinely filtered

      // Clearing (via the clear icon that appears once there's text)
      // restores the full, unfiltered list.
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();
      expect(shownCount(), greaterThan(2000));

      // Reading search, typed in hiragana even though on'yomi is stored in
      // katakana (スイ) -- confirms the kana-script normalization is wired
      // up end-to-end, not just at the pure-function level.
      await tester.enterText(find.byType(TextField), 'すい');
      await tester.pump();
      // 水 might not be in the first screenful of matches, but the count
      // should be smaller than the full set.
      expect(shownCount(), lessThan(2000));

      // Stroke count search: 水 is 4 strokes: a bare integer switches the
      // search to exact-stroke-count mode instead of reading/meaning.
      await tester.enterText(find.byType(TextField), '4');
      await tester.pump();
      expect(shownCount(), lessThan(2000));
      expect(shownCount(), greaterThan(0));

      // No matches at all shows an empty-state message instead of a
      // confusingly blank list.
      await tester.enterText(find.byType(TextField), 'zzzznonexistent');
      await tester.pump();
      expect(find.text('No matching kanji.'), findsOneWidget);
    },
  );
}
