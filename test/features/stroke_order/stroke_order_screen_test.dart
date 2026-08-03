import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanjitomo/features/stroke_order/stroke_order_screen.dart';
import 'package:kanjitomo/features/stroke_order/stroke_order_view.dart';

import 'stroke_order_test_helpers.dart';

void main() {
  testWidgets('loads real asset data and auto-plays on a loop for 愛', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: StrokeOrderScreen()),
    );
    // Real asset load (assets/stroke_paths.json, ~2.4MB) -- not mocked, so
    // this also verifies the asset is registered and well-formed.
    await pumpUntilLoaded(tester);

    expect(find.text('Failed to load stroke data', findRichText: true), findsNothing);
    expect(find.text('No stroke data for this character.'), findsNothing);

    final view = tester.widget<StrokeOrderView>(find.byType(StrokeOrderView));
    expect(view.paths, hasLength(13)); // 愛 is a 13-stroke kanji

    // Playing starts automatically, no button tap needed. Can't use
    // pumpAndSettle anywhere near this animation -- it repeats forever, so
    // pumpAndSettle would never see frame scheduling stop and would time
    // out regardless of how the animation is actually behaving.
    await tester.pump(); // first frame
    await tester.pump(const Duration(milliseconds: 250)); // mid-animation
    var painter = findStrokeOrderPainter(tester);
    expect(painter.progress, greaterThan(0));
    expect(painter.progress, lessThan(13));

    // 13 strokes x 500ms = 6.5s per loop -- pump past one full cycle and
    // confirm it wrapped back around instead of stopping at the end.
    await tester.pump(const Duration(seconds: 7));
    painter = findStrokeOrderPainter(tester);
    expect(painter.progress, lessThan(13));
  });
}
