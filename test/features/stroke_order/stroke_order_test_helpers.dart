import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanjitomo/features/stroke_order/stroke_order_painter.dart';

/// Waits for the real asset-load I/O to finish, then pumps to reflect the
/// resulting setState. Two gotchas stacked here, not one:
/// (1) can't use pumpAndSettle -- the loading state's indeterminate
/// CircularProgressIndicator animates forever, so it would never see frame
/// scheduling stop and would time out regardless of how quickly the load
/// finishes; (2) plain tester.pump() runs inside FakeAsync, whose virtual
/// clock never actually elapses real wall-clock time, so a real (non-fake)
/// Future like rootBundle.loadString()'s disk read never gets the actual
/// time it needs to complete -- confirmed directly against a bare `test()`,
/// where the same repository load resolves near-instantly. tester.runAsync()
/// briefly leaves the FakeAsync zone so real I/O can actually finish. Polls
/// in a bounded loop against the actual loading-finished condition rather
/// than guessing one fixed duration, since real-time cost isn't constant
/// (confirmed: a second real asset load in the same test *process* can be
/// meaningfully slower, or hang outright, which is why the two
/// StrokeOrderScreen tests live in separate files -- each test file gets
/// its own process, sidestepping that interaction rather than fighting it).
Future<void> pumpUntilLoaded(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) return;
  }
  throw StateError('Stroke data never finished loading within the bounded wait');
}

/// StrokeOrderView's subtree contains more than one CustomPaint (the Play/
/// Reset ElevatedButtons each have their own for ink/hover effects), so
/// find.byType(CustomPaint) alone is ambiguous -- match on the painter type
/// instead of position in the tree.
StrokeOrderPainter findStrokeOrderPainter(WidgetTester tester) {
  return tester
      .widget<CustomPaint>(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is StrokeOrderPainter,
        ),
      )
      .painter as StrokeOrderPainter;
}
