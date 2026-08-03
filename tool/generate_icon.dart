// ignore_for_file: avoid_print
// Renders the cat mascot to a 1024x1024 PNG for use as the launcher icon.
// Run with: flutter run tool/generate_icon.dart
// (needs a Flutter engine to access dart:ui)

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const size = 1024.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

  // Background
  canvas.drawRect(
    Rect.fromLTWH(0, 0, size, size),
    Paint()..color = const Color(0xFFFFF8E1), // amber 50 - warm cream
  );

  _paintCat(canvas, size);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  final file = File('assets/icon/app_icon.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  print('Wrote ${file.path} (${bytes.lengthInBytes} bytes)');
  exit(0);
}

void _paintCat(Canvas canvas, double s) {
  final center = s * 0.5;

  // -- head: rounded square, warm orange --
  final headColor = const Color(0xFFFF9800);
  final headPaint = Paint()..color = headColor;
  final headRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(s * 0.12, s * 0.22, s * 0.76, s * 0.68),
    Radius.circular(s * 0.22),
  );
  canvas.drawRRect(headRect, headPaint);

  // -- ears --
  final earPaint = Paint()..color = headColor;
  final innerEarPaint = Paint()..color = const Color(0xFFFFCC80);

  final leftEar = Path()
    ..moveTo(s * 0.12, s * 0.35)
    ..lineTo(s * 0.22, s * 0.05)
    ..lineTo(s * 0.38, s * 0.28)
    ..close();
  canvas.drawPath(leftEar, earPaint);
  final leftInner = Path()
    ..moveTo(s * 0.17, s * 0.32)
    ..lineTo(s * 0.23, s * 0.13)
    ..lineTo(s * 0.34, s * 0.29)
    ..close();
  canvas.drawPath(leftInner, innerEarPaint);

  final rightEar = Path()
    ..moveTo(s * 0.88, s * 0.35)
    ..lineTo(s * 0.78, s * 0.05)
    ..lineTo(s * 0.62, s * 0.28)
    ..close();
  canvas.drawPath(rightEar, earPaint);
  final rightInner = Path()
    ..moveTo(s * 0.83, s * 0.32)
    ..lineTo(s * 0.77, s * 0.13)
    ..lineTo(s * 0.66, s * 0.29)
    ..close();
  canvas.drawPath(rightInner, innerEarPaint);

  // -- 字 on forehead --
  final textPainter = TextPainter(
    text: TextSpan(
      text: '字',
      style: TextStyle(
        fontSize: s * 0.24,
        fontWeight: FontWeight.w900,
        color: const Color(0xBF4E342E),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  textPainter.paint(canvas, Offset((s - textPainter.width) / 2, s * 0.24));

  // -- eyes --
  final eyeWhite = Paint()..color = Colors.white;
  final eyeOutline = Paint()
    ..color = const Color(0xFF4E342E)
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.02;
  final pupilPaint = Paint()..color = const Color(0xFF4E342E);
  final shinePaint = Paint()..color = Colors.white;

  final eyeY = s * 0.52;
  final eyeRx = s * 0.10;
  final eyeRy = s * 0.11;

  canvas.drawOval(Rect.fromCenter(center: Offset(s * 0.34, eyeY), width: eyeRx * 2, height: eyeRy * 2), eyeWhite);
  canvas.drawOval(Rect.fromCenter(center: Offset(s * 0.34, eyeY), width: eyeRx * 2, height: eyeRy * 2), eyeOutline);
  canvas.drawCircle(Offset(s * 0.36, eyeY), s * 0.055, pupilPaint);
  canvas.drawCircle(Offset(s * 0.37, eyeY - s * 0.02), s * 0.018, shinePaint);

  canvas.drawOval(Rect.fromCenter(center: Offset(s * 0.66, eyeY), width: eyeRx * 2, height: eyeRy * 2), eyeWhite);
  canvas.drawOval(Rect.fromCenter(center: Offset(s * 0.66, eyeY), width: eyeRx * 2, height: eyeRy * 2), eyeOutline);
  canvas.drawCircle(Offset(s * 0.68, eyeY), s * 0.055, pupilPaint);
  canvas.drawCircle(Offset(s * 0.69, eyeY - s * 0.02), s * 0.018, shinePaint);

  // -- nose --
  final nosePaint = Paint()..color = const Color(0xFFE91E63);
  final nosePath = Path()
    ..moveTo(center, s * 0.62)
    ..lineTo(center - s * 0.03, s * 0.66)
    ..lineTo(center + s * 0.03, s * 0.66)
    ..close();
  canvas.drawPath(nosePath, nosePaint);

  // -- mouth --
  final mouthPaint = Paint()
    ..color = const Color(0xFF4E342E)
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.018
    ..strokeCap = StrokeCap.round;
  final mouthPath = Path()
    ..moveTo(s * 0.36, s * 0.70)
    ..quadraticBezierTo(s * 0.43, s * 0.74, center, s * 0.67)
    ..quadraticBezierTo(s * 0.57, s * 0.74, s * 0.64, s * 0.70);
  canvas.drawPath(mouthPath, mouthPaint);

  // -- whiskers --
  final whiskerPaint = Paint()
    ..color = const Color(0xFF5D4037)
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.012
    ..strokeCap = StrokeCap.round;

  canvas.drawLine(Offset(s * 0.28, s * 0.63), Offset(s * 0.04, s * 0.58), whiskerPaint);
  canvas.drawLine(Offset(s * 0.28, s * 0.67), Offset(s * 0.03, s * 0.67), whiskerPaint);
  canvas.drawLine(Offset(s * 0.28, s * 0.71), Offset(s * 0.04, s * 0.76), whiskerPaint);
  canvas.drawLine(Offset(s * 0.72, s * 0.63), Offset(s * 0.96, s * 0.58), whiskerPaint);
  canvas.drawLine(Offset(s * 0.72, s * 0.67), Offset(s * 0.97, s * 0.67), whiskerPaint);
  canvas.drawLine(Offset(s * 0.72, s * 0.71), Offset(s * 0.96, s * 0.76), whiskerPaint);

  // -- blush --
  final blushPaint = Paint()..color = const Color(0x30E91E63);
  canvas.drawOval(Rect.fromCenter(center: Offset(s * 0.22, s * 0.66), width: s * 0.11, height: s * 0.07), blushPaint);
  canvas.drawOval(Rect.fromCenter(center: Offset(s * 0.78, s * 0.66), width: s * 0.11, height: s * 0.07), blushPaint);
}
