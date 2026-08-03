import 'package:flutter/material.dart';

import '../../data/stroke_paths_repository.dart';

/// Draws [paths] progressively: [progress] is a fractional stroke count --
/// its integer part is how many strokes are fully drawn, its fractional
/// part is how far into the *next* stroke the animation has reached (via
/// PathMetric.extractPath, not a scale/opacity trick, so the growing stroke
/// looks like it's actually being drawn rather than fading in).
class StrokeOrderPainter extends CustomPainter {
  final List<Path> paths;
  final double progress;
  final Color color;

  // KanjiVG's own default (see the stroke-width in each SVG's <g> style
  // attribute) -- the natural visual weight this path data was authored at.
  static const double _strokeWidthInViewBox = 3;

  StrokeOrderPainter({
    required this.paths,
    required this.progress,
    this.color = Colors.black87,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / kanjiVgViewBoxSize;
    canvas.scale(scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidthInViewBox
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fullyDrawn = progress.floor().clamp(0, paths.length);
    for (var i = 0; i < fullyDrawn; i++) {
      canvas.drawPath(paths[i], paint);
    }

    if (fullyDrawn >= paths.length) return;
    final t = (progress - fullyDrawn).clamp(0.0, 1.0);
    if (t <= 0) return;

    for (final metric in paths[fullyDrawn].computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * t), paint);
    }
  }

  @override
  bool shouldRepaint(covariant StrokeOrderPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.paths != paths ||
      oldDelegate.color != color;
}
