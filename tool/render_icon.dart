// Renders the KanjiMascot (cat with 字) to PNG files for launcher icon
// and splash screen.
//
// Run: flutter run -t tool/render_icon.dart -d macos

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../lib/core/kanji_mascot.dart';

// We need to re-create the painter here since _CatMascotPainter is private.
// Instead, we'll use the same painting logic directly.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load NotoSansJP-Bold so TextPainter can render 字 on the forehead.
  // In a tool entrypoint the pubspec font declarations aren't active, so we
  // must register the font manually via loadFontFromList.
  final fontData = await rootBundle.load('assets/fonts/NotoSansJP-Bold.ttf');
  await ui.loadFontFromList(fontData.buffer.asUint8List(), fontFamily: 'NotoSansJP');

  // Launcher icon sizes (mipmap)
  final iconSizes = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
  };

  // Adaptive icon foreground sizes (drawable, 108dp with safe zone)
  final foregroundSizes = {
    'mdpi': 108,
    'hdpi': 162,
    'xhdpi': 216,
    'xxhdpi': 324,
    'xxxhdpi': 432,
  };

  // Splash screen (launch_image) sizes
  final splashSizes = {
    'mdpi': 192,
    'hdpi': 288,
    'xhdpi': 384,
    'xxhdpi': 576,
    'xxxhdpi': 768,
  };

  // Use app container's temp directory to avoid macOS sandbox restrictions
  final basePath = '${Directory.systemTemp.path}/kanjitomo_icons';

  for (final entry in iconSizes.entries) {
    final density = entry.key;
    final size = entry.value;
    final image = await _renderMascot(size, size, scale: 1.3);
    final path = '$basePath/mipmap-$density/ic_launcher.png';
    await _savePng(image, path);
    print('Wrote $path (${size}x$size)');
  }

  for (final entry in foregroundSizes.entries) {
    final density = entry.key;
    final size = entry.value;
    // Adaptive icon: mascot centered in the safe zone (inner 66% of 108dp)
    final image = await _renderMascotAdaptive(size);
    final path = '$basePath/drawable-$density/ic_launcher_foreground.png';
    await _savePng(image, path);
    print('Wrote $path (${size}x$size)');
  }

  for (final entry in splashSizes.entries) {
    final density = entry.key;
    final size = entry.value;
    final image = await _renderMascot(size, size, padding: 0.08);
    final path = '$basePath/mipmap-$density/launch_image.png';
    await _savePng(image, path);
    print('Wrote $path (${size}x$size)');
  }

  // High-res source icon for assets/icon/app_icon.png and store listing
  final appIcon = await _renderMascot(1024, 1024, scale: 1.3);
  final appIconPath = '$basePath/app_icon.png';
  await _savePng(appIcon, appIconPath);
  print('Wrote $appIconPath (1024x1024)');

  // Also load the regular weight for the feature graphic text
  final fontRegData = await rootBundle.load('assets/fonts/NotoSansJP-Regular.ttf');
  await ui.loadFontFromList(fontRegData.buffer.asUint8List(), fontFamily: 'NotoSansJP');

  // Feature graphic for Google Play Store (1024x500)
  final featureGraphic = await _renderFeatureGraphic();
  final featurePath = '$basePath/feature_graphic.png';
  await _savePng(featureGraphic, featurePath);
  print('Wrote $featurePath (1024x500)');

  print('\nDone! All icons generated.');
  print('Copy app_icon.png to assets/icon/app_icon.png, then run:');
  print('  flutter pub run flutter_launcher_icons');
  exit(0);
}

Future<ui.Image> _renderMascot(int width, int height, {double padding = 0, double scale = 1.0}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

  // Light background
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFFFFF8E1), // warm cream
  );

  // scale > 1.0 makes the cat overflow the canvas (cropped by PNG bounds),
  // so it appears larger in the final icon.
  final mascotSize = width * (1.0 - padding * 2) * scale;
  final offset = (width - mascotSize) / 2;

  canvas.save();
  canvas.translate(offset, offset);
  _paintCatMascot(canvas, mascotSize);
  canvas.restore();

  final picture = recorder.endRecording();
  return picture.toImage(width, height);
}

Future<ui.Image> _renderMascotAdaptive(int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));

  // Transparent background (adaptive icons have separate background)
  // The safe zone is the inner 66/108 = ~61% centered
  final mascotSize = size * 0.82; // fill most of the safe zone
  final offset = (size - mascotSize) / 2;

  canvas.save();
  canvas.translate(offset, offset);
  _paintCatMascot(canvas, mascotSize);
  canvas.restore();

  final picture = recorder.endRecording();
  return picture.toImage(size, size);
}

Future<void> _savePng(ui.Image image, String path) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) throw Exception('Failed to encode PNG');
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(byteData.buffer.asUint8List());
}

// Copied from kanji_mascot.dart since _CatMascotPainter is private
void _paintCatMascot(Canvas canvas, double mascotSize) {
  final s = mascotSize;
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
        fontFamily: 'NotoSansJP',
        fontWeight: FontWeight.w900,
        color: const Color(0xBF4E342E),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  textPainter.paint(canvas, Offset((s - textPainter.width) / 2, s * 0.18));

  // -- eyes --
  final eyeWhite = Paint()..color = const Color(0xFFFFFFFF);
  final eyeOutline = Paint()
    ..color = const Color(0xFF4E342E)
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.02;
  final pupilPaint = Paint()..color = const Color(0xFF4E342E);
  final shinePaint = Paint()..color = const Color(0xFFFFFFFF);

  final eyeY = s * 0.52;
  final eyeRx = s * 0.10;
  final eyeRy = s * 0.11;

  canvas.drawOval(
    Rect.fromCenter(center: Offset(s * 0.34, eyeY), width: eyeRx * 2, height: eyeRy * 2),
    eyeWhite,
  );
  canvas.drawOval(
    Rect.fromCenter(center: Offset(s * 0.34, eyeY), width: eyeRx * 2, height: eyeRy * 2),
    eyeOutline,
  );
  canvas.drawCircle(Offset(s * 0.36, eyeY), s * 0.055, pupilPaint);
  canvas.drawCircle(Offset(s * 0.37, eyeY - s * 0.02), s * 0.018, shinePaint);

  canvas.drawOval(
    Rect.fromCenter(center: Offset(s * 0.66, eyeY), width: eyeRx * 2, height: eyeRy * 2),
    eyeWhite,
  );
  canvas.drawOval(
    Rect.fromCenter(center: Offset(s * 0.66, eyeY), width: eyeRx * 2, height: eyeRy * 2),
    eyeOutline,
  );
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
  canvas.drawOval(
    Rect.fromCenter(center: Offset(s * 0.22, s * 0.66), width: s * 0.11, height: s * 0.07),
    blushPaint,
  );
  canvas.drawOval(
    Rect.fromCenter(center: Offset(s * 0.78, s * 0.66), width: s * 0.11, height: s * 0.07),
    blushPaint,
  );
}

Future<ui.Image> _renderFeatureGraphic() async {
  const w = 1024.0;
  const h = 500.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, w, h));

  // Background: warm cream matching the app theme
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, w, h),
    Paint()..color = const Color(0xFFFFF8E1),
  );

  // Subtle decorative kanji scattered in background
  final bgKanji = ['漢', '読', '書', '学', '語', '記', '話', '文'];
  final bgPaint = const Color(0x0A4E342E);
  for (var i = 0; i < bgKanji.length; i++) {
    final tp = TextPainter(
      text: TextSpan(
        text: bgKanji[i],
        style: TextStyle(
          fontSize: 80,
          fontFamily: 'NotoSansJP',
          fontWeight: FontWeight.w700,
          color: bgPaint,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final x = (i % 4) * 260.0 + 20;
    final y = (i ~/ 4) * 280.0 + 30;
    tp.paint(canvas, Offset(x, y));
  }

  // Cat mascot on the left, vertically centered, with padding
  final mascotSize = h * 0.78;
  final mascotX = 60.0;
  final mascotY = (h - mascotSize) / 2;

  canvas.save();
  canvas.translate(mascotX, mascotY);
  _paintCatMascot(canvas, mascotSize);
  canvas.restore();

  // Text block on the right side
  final textX = mascotX + mascotSize + 60;
  final textAreaWidth = w - textX - 40;

  // App name
  final titlePainter = TextPainter(
    text: const TextSpan(
      text: 'kanjitomo',
      style: TextStyle(
        fontSize: 64,
        fontFamily: 'NotoSansJP',
        fontWeight: FontWeight.w700,
        color: Color(0xFF4E342E),
        letterSpacing: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: textAreaWidth);

  // Tagline
  final taglinePainter = TextPainter(
    text: const TextSpan(
      text: 'Draw. Recall. Master.',
      style: TextStyle(
        fontSize: 30,
        fontFamily: 'NotoSansJP',
        fontWeight: FontWeight.w400,
        color: Color(0xFF795548),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: textAreaWidth);

  // Subtitle
  final subtitlePainter = TextPainter(
    text: const TextSpan(
      text: 'Learn kanji by hand',
      style: TextStyle(
        fontSize: 24,
        fontFamily: 'NotoSansJP',
        fontWeight: FontWeight.w400,
        color: Color(0xFF8D6E63),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: textAreaWidth);

  // Vertically center the text block
  final totalTextHeight =
      titlePainter.height + 12 + taglinePainter.height + 8 + subtitlePainter.height;
  var textY = (h - totalTextHeight) / 2;

  titlePainter.paint(canvas, Offset(textX, textY));
  textY += titlePainter.height + 12;
  taglinePainter.paint(canvas, Offset(textX, textY));
  textY += taglinePainter.height + 8;
  subtitlePainter.paint(canvas, Offset(textX, textY));

  final picture = recorder.endRecording();
  return picture.toImage(w.toInt(), h.toInt());
}
