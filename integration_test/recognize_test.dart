// Runs against a real platform (e.g. `flutter test integration_test/recognize_test.dart -d macos`)
// so the actual native flutter_onnxruntime plugin backs the platform channel calls --
// a plain `flutter test` widget test can't exercise this, since there's no real
// native implementation registered in that harness. Pattern ported from
// kanjirec/flutter_app/integration_test/recognize_test.dart.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:kanjitomo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('draw a stroke, recognize, see top-5 predictions with valid probabilities', (
    tester,
  ) async {
    await tester.pumpWidget(const KanjitomoApp());

    // Wait for the ONNX model to finish loading from assets.
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.text('Loading model...'), findsNothing);
    expect(find.textContaining('failed to load'), findsNothing);

    final canvas = find.byKey(const Key('drawing_canvas'));
    await tester.runAsync(() async {
      // kind: PointerDeviceKind.mouse -- the default .touch silently drops
      // most simulated strokes on a mouse-native macOS run (known gotcha,
      // confirmed in kanjirec's own integration tests).
      final gesture = await tester.startGesture(
        tester.getCenter(canvas) + const Offset(-100, -20),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(200, 40));
      await gesture.up();
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    final recognizeButton = find.widgetWithText(ElevatedButton, 'Recognize');
    expect(recognizeButton, findsOneWidget);
    expect(tester.widget<ElevatedButton>(recognizeButton).onPressed, isNotNull);

    await tester.tap(recognizeButton);
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    await tester.pumpAndSettle();

    expect(find.text('Top 5:'), findsOneWidget);

    final percentTexts = find
        .byWidgetPredicate((w) => w is Text && w.data != null && w.data!.endsWith('%'))
        .evaluate()
        .map((e) => (e.widget as Text).data!)
        .toList();
    expect(percentTexts.length, 5, reason: 'expected exactly 5 predictions');

    final probs = percentTexts.map((s) => double.parse(s.replaceAll('%', ''))).toList();
    for (final p in probs) {
      expect(p, inInclusiveRange(0.0, 100.0));
    }
    // Descending order (top-1 highest probability).
    for (int i = 1; i < probs.length; i++) {
      expect(probs[i - 1], greaterThanOrEqualTo(probs[i]));
    }
  });
}
