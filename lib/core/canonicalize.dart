import 'dart:typed_data';

/// Ports kanjirec/preprocessing.py::canonicalize() to Dart so training and
/// inference preprocessing stay identical -- this is "the contract". Values
/// below match models/*_preprocessing_config.json; if that file's values
/// ever change, update these too.
///
/// Callers should feed this a base image rendered well above targetSize
/// (e.g. KanjiRasterizer at 256, matching config.SUPERSAMPLE_SIZE) rather
/// than exactly targetSize -- cropping a small drawing's ink to its bounding
/// box and rescaling to fill the frame is a big magnification, and doing
/// that from a source that's already only 64x64 throws away most of the
/// detail before it even gets here.
class CanonicalizeConfig {
  final int targetSize;
  final bool binarize;
  final double marginFrac;
  final int inkThreshold;

  const CanonicalizeConfig({
    this.targetSize = 64,
    this.binarize = true,
    this.marginFrac = 0.10,
    this.inkThreshold = 200,
  });
}

/// White-background (255), dark-ink RGBA input -> a targetSize x targetSize
/// Float32List in [0, 1], ink near 1.0, background near 0.0 (matches the
/// Python side's canonicalize() output, which the model was trained on).
Float32List canonicalize(
  ByteData rgba,
  int width,
  int height, {
  CanonicalizeConfig config = const CanonicalizeConfig(),
}) {
  final gray = Uint8List(width * height);
  for (int i = 0; i < width * height; i++) {
    gray[i] = rgba.getUint8(
      i * 4,
    ); // R channel; drawing is black/white so R=G=B
  }

  int minX = width, minY = height, maxX = -1, maxY = -1;
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      if (gray[y * width + x] < config.inkThreshold) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  Uint8List square;
  int side;
  if (maxX < 0) {
    // Blank canvas: nothing to crop, just carry the (blank) image through.
    square = gray;
    side = width;
  } else {
    final w = maxX - minX + 1;
    final h = maxY - minY + 1;
    side = ((w > h ? w : h) * (1 + 2 * config.marginFrac)).round();
    square = Uint8List(side * side)..fillRange(0, side * side, 255);
    final yOff = (side - h) ~/ 2;
    final xOff = (side - w) ~/ 2;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        square[(yOff + y) * side + (xOff + x)] =
            gray[(minY + y) * width + (minX + x)];
      }
    }
  }

  final resized = _resizeAreaAverage(
    square,
    side,
    side,
    config.targetSize,
    config.targetSize,
  );

  final out = Float32List(config.targetSize * config.targetSize);
  for (int i = 0; i < resized.length; i++) {
    int v = resized[i];
    if (config.binarize) {
      v = v < config.inkThreshold ? 0 : 255;
    }
    out[i] = 1.0 - (v / 255.0);
  }
  return out;
}

/// Area-average resize (matches cv2.INTER_AREA reasonably well) -- each
/// destination pixel is the mean of the source pixels it covers, which is
/// what you want when shrinking (the common case here: 256-ish crop -> 64).
/// Degrades gracefully to nearest-neighbor-ish behavior when enlarging.
Uint8List _resizeAreaAverage(
  Uint8List src,
  int srcW,
  int srcH,
  int dstW,
  int dstH,
) {
  final dst = Uint8List(dstW * dstH);
  final scaleX = srcW / dstW;
  final scaleY = srcH / dstH;
  for (int y = 0; y < dstH; y++) {
    final srcY0 = (y * scaleY).floor();
    final srcY1 = ((y + 1) * scaleY).ceil().clamp(srcY0 + 1, srcH);
    for (int x = 0; x < dstW; x++) {
      final srcX0 = (x * scaleX).floor();
      final srcX1 = ((x + 1) * scaleX).ceil().clamp(srcX0 + 1, srcW);

      int sum = 0;
      int count = 0;
      for (int sy = srcY0; sy < srcY1; sy++) {
        for (int sx = srcX0; sx < srcX1; sx++) {
          sum += src[sy * srcW + sx];
          count++;
        }
      }
      dst[y * dstW + x] = (sum / count).round();
    }
  }
  return dst;
}
