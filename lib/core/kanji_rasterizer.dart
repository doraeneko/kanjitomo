import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// One continuous finger stroke, recorded directly in 64x64 grid-space
/// coordinates (not display pixels) -- see [KanjiRasterizer.gridSize].
class Stroke {
  final List<Offset> points = [];
}

/// Pure rendering logic: turns recorded strokes into the exact 64x64 raster
/// the model would see. Kept separate from any widget so it's directly
/// testable without a running app.
class KanjiRasterizer {
  static const int gridSize = 64;

  static Future<ui.Image> rasterize(
    List<Stroke> strokes, {
    required double brushWidth,
    int size = gridSize,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    );
    final scale = size / gridSize;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      Paint()..color = Colors.white,
    );

    final strokePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = brushWidth * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()..color = Colors.black;

    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      if (stroke.points.length == 1) {
        canvas.drawCircle(
          stroke.points.first * scale,
          (brushWidth * scale) / 2,
          dotPaint,
        );
        continue;
      }
      final path = Path()
        ..moveTo(
          stroke.points.first.dx * scale,
          stroke.points.first.dy * scale,
        );
      for (final p in stroke.points.skip(1)) {
        path.lineTo(p.dx * scale, p.dy * scale);
      }
      canvas.drawPath(path, strokePaint);
    }

    final picture = recorder.endRecording();
    return picture.toImage(size, size);
  }

  static Future<Uint8List> toPngBytes(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
