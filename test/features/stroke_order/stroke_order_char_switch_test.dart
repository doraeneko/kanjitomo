import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanjitomo/features/stroke_order/stroke_order_screen.dart';
import 'package:kanjitomo/features/stroke_order/stroke_order_view.dart';

import 'stroke_order_test_helpers.dart';

// Kept in its own file, not merged into stroke_order_screen_test.dart's
// testWidgets group: confirmed directly that a second real asset load
// (tester.runAsync + rootBundle.loadString) in the same test *process* can
// hang indefinitely even with a generous bounded poll, whereas each test
// file gets a fresh process. See stroke_order_test_helpers.dart's
// pumpUntilLoaded doc comment for the full story.
void main() {
  testWidgets('typing a different character swaps the displayed strokes', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: StrokeOrderScreen()));
    await pumpUntilLoaded(tester);

    await tester.enterText(find.byType(TextField), '一');
    await tester.pump();

    final view = tester.widget<StrokeOrderView>(find.byType(StrokeOrderView));
    expect(view.paths, hasLength(1)); // 一 is a single stroke
  });
}
