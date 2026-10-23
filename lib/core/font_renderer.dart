import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Renders a single character to a [ui.Image] using NotoSansJP, suitable for
/// feeding through [canonicalize] + [KanjiRecognizer.predictTopK]. Same
/// PictureRecorder + Canvas pattern as [KanjiRasterizer.rasterize].
Future<ui.Image> renderCharacterToImage(String character, {int size = 256}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
  );

  // White background (matches KanjiRasterizer's white-bg convention).
  canvas.drawRect(
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Paint()..color = Colors.white,
  );

  // Black character, centered, filling most of the square.
  final textStyle = ui.TextStyle(
    color: Colors.black,
    fontSize: size * 0.8,
    fontFamily: 'NotoSansJP',
    fontWeight: FontWeight.bold,
  );
  final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
    textAlign: TextAlign.center,
  ))
    ..pushStyle(textStyle)
    ..addText(character);
  final paragraph = paragraphBuilder.build()
    ..layout(ui.ParagraphConstraints(width: size.toDouble()));

  // Center vertically.
  final textHeight = paragraph.height;
  final yOffset = (size - textHeight) / 2;
  canvas.drawParagraph(paragraph, Offset(0, yOffset));

  final picture = recorder.endRecording();
  return picture.toImage(size, size);
}
