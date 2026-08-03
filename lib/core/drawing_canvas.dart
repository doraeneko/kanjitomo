import 'package:flutter/material.dart';

import 'kanji_rasterizer.dart';

/// A fixed-size square drawing surface -- raw pointer capture converted to
/// 64x64 grid-space points, plus live stroke rendering. Stateless/
/// "controlled component": the owner holds strokes/currentStroke and reacts
/// to the three callbacks, rather than this widget owning any drawing state
/// itself. Used both by the main draw screen (feeds recognition) and the
/// quiz screen (a plain scratch pad, no recognition needed) -- extracted
/// here once a second real call site showed up, so the two can't
/// accidentally drift apart on the subtle fixes already baked in below.
class DrawingCanvas extends StatelessWidget {
  final double displaySize;
  final double brushWidth; // in 64x64 grid units
  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final ValueChanged<Offset> onStrokeStart; // grid-space point
  final ValueChanged<Offset> onStrokeUpdate; // grid-space point
  final VoidCallback onStrokeEnd;

  const DrawingCanvas({
    super.key,
    required this.displaySize,
    required this.brushWidth,
    required this.strokes,
    required this.currentStroke,
    required this.onStrokeStart,
    required this.onStrokeUpdate,
    required this.onStrokeEnd,
  });

  double get _displayScale => displaySize / KanjiRasterizer.gridSize;

  Offset _toGridSpace(Offset localPosition) {
    final dx = (localPosition.dx / _displayScale).clamp(
      0.0,
      KanjiRasterizer.gridSize.toDouble(),
    );
    final dy = (localPosition.dy / _displayScale).clamp(
      0.0,
      KanjiRasterizer.gridSize.toDouble(),
    );
    return Offset(dx, dy);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Listener gets raw pointer events directly, bypassing the gesture
      // arena entirely -- a plain GestureDetector's PanGestureRecognizer
      // here competes with an enclosing scrollable's own drag recognizer
      // for any drag with a vertical component, and can lose (confirmed:
      // only horizontal strokes got through before this fix).
      onPointerDown: (e) => onStrokeStart(_toGridSpace(e.localPosition)),
      // Once a pointer goes down inside a Listener, it keeps receiving that
      // pointer's move/up events for the rest of the gesture even if the
      // finger wanders outside the widget's bounds (no re-hit-testing per
      // move). Without this check, points get silently clamped to the
      // canvas edge while the finger is off-canvas, which reads as "drawing
      // outside the canvas". Ending the stroke instead, matching how a
      // physical drawing surface behaves.
      onPointerMove: (e) {
        final inside =
            e.localPosition.dx >= 0 &&
            e.localPosition.dx <= displaySize &&
            e.localPosition.dy >= 0 &&
            e.localPosition.dy <= displaySize;
        if (inside) {
          onStrokeUpdate(_toGridSpace(e.localPosition));
        } else {
          onStrokeEnd();
        }
      },
      onPointerUp: (_) => onStrokeEnd(),
      child: Container(
        key: const Key('drawing_canvas'),
        width: displaySize,
        height: displaySize,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400, width: 2),
        ),
        child: CustomPaint(
          painter: StrokesPainter(
            strokes: strokes,
            currentStroke: currentStroke,
            brushWidth: brushWidth,
            displayScale: _displayScale,
          ),
          size: Size(displaySize, displaySize),
        ),
      ),
    );
  }
}

class StrokesPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final double brushWidth;
  final double displayScale;

  StrokesPainter({
    required this.strokes,
    required this.currentStroke,
    required this.brushWidth,
    required this.displayScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = brushWidth * displayScale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in [
      ...strokes,
      if (currentStroke != null) currentStroke!,
    ]) {
      if (stroke.points.length < 2) continue;
      final path = Path()
        ..moveTo(
          stroke.points.first.dx * displayScale,
          stroke.points.first.dy * displayScale,
        );
      for (final p in stroke.points.skip(1)) {
        path.lineTo(p.dx * displayScale, p.dy * displayScale);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StrokesPainter oldDelegate) => true;
}
