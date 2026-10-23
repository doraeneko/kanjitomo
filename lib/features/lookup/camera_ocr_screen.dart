import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/word_index_repository.dart';
import '../../l10n/app_localizations.dart';

/// Whether to return single kanji characters or whole words.
enum CameraOcrMode { kanji, word }

/// A recognized item with its bounding box in image coordinates.
class _OcrItem {
  final String text;
  final Rect imageRect;
  _OcrItem(this.text, this.imageRect);
}

/// Lets the user take a photo (direct camera, rear-facing, no confirm dialog)
/// or pick from gallery, runs ML Kit Japanese text recognition, and displays
/// results as tappable overlays on the image (pinch-to-zoom) plus chips below.
///
/// Supports multi-select: tapped items are collected in a list. The user taps
/// "Done" to return all selected items, or the back button to cancel.
///
/// In [CameraOcrMode.kanji]: shows only CJK ideographs (no kana).
/// In [CameraOcrMode.word]: segments text into dictionary words (greedy
/// longest-match against JMdict), shows only words containing kanji.
class CameraOcrScreen extends StatefulWidget {
  final CameraOcrMode mode;
  final WordIndexRepository? wordIndex;

  const CameraOcrScreen({
    super.key,
    this.mode = CameraOcrMode.kanji,
    this.wordIndex,
  });

  @override
  State<CameraOcrScreen> createState() => _CameraOcrScreenState();
}

class _CameraOcrScreenState extends State<CameraOcrScreen> {
  final _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.japanese);
  final _picker = ImagePicker();

  File? _imageFile;
  Size _imageSize = Size.zero;
  List<_OcrItem> _ocrItems = [];
  List<String> _uniqueItems = [];
  bool _processing = false;
  bool _noTextFound = false;

  /// Accumulated selections (in tap order).
  final List<String> _selected = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSourcePicker());
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  // ── Image acquisition ──────────────────────────────────────────────────

  Future<void> _showSourcePicker() async {
    final l = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l.cameraOcrFromCamera),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l.cameraOcrFromGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) {
      if (mounted && _imageFile == null) Navigator.pop(context);
      return;
    }

    if (source == ImageSource.camera) {
      await _takePhoto();
    } else {
      await _pickFromGallery();
    }
  }

  /// Opens the rear camera directly, takes a photo on tap, no confirm dialog.
  Future<void> _takePhoto() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      if (mounted && _imageFile == null) Navigator.pop(context);
      return;
    }
    // Prefer rear camera.
    final rear = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    if (!mounted) return;
    final file = await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (_) => _DirectCameraScreen(camera: rear),
      ),
    );

    if (file == null) {
      if (mounted && _imageFile == null) Navigator.pop(context);
      return;
    }

    _processFile(file);
  }

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) {
      if (mounted && _imageFile == null) Navigator.pop(context);
      return;
    }
    _processFile(File(picked.path));
  }

  void _processFile(File file) {
    setState(() {
      _imageFile = file;
      _processing = true;
      _noTextFound = false;
      _ocrItems = [];
      _uniqueItems = [];
      _selected.clear();
    });
    _convertAndRecognize(file);
  }

  // ── Crop ─────────────────────────────────────────────────────────────

  Future<void> _cropImage() async {
    if (_imageFile == null) return;
    final cropped = await ImageCropper().cropImage(
      sourcePath: _imageFile!.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop',
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop'),
      ],
    );
    if (cropped == null || !mounted) return;
    _processFile(File(cropped.path));
  }

  // ── Grayscale conversion ────────────────────────────────────────────

  /// Converts the image to grayscale and applies a light sharpen.
  /// Grayscale strips color noise (red pen marks, blue stamps, colored
  /// paper). Sharpening boosts edges so ML Kit picks up faint or slightly
  /// blurry characters it would otherwise miss.
  Future<File> _preprocessImage(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final w = image.width;
    final h = image.height;

    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return file;

    final src = byteData.buffer.asUint8List();

    // Step 1: convert to grayscale in-place.
    for (int i = 0; i < src.length; i += 4) {
      final gray = (src[i] * 0.299 + src[i + 1] * 0.587 + src[i + 2] * 0.114).round();
      src[i] = gray;
      src[i + 1] = gray;
      src[i + 2] = gray;
    }

    // Step 2: sharpen via 3x3 kernel:
    //   0  -1   0
    //  -1   5  -1
    //   0  -1   0
    final dst = Uint8List.fromList(src);
    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final i = (y * w + x) * 4;
        // Only need one channel since it's already grayscale.
        final v = src[i] * 5
            - src[i - 4]          // left
            - src[i + 4]          // right
            - src[i - w * 4]      // above
            - src[i + w * 4];     // below
        final clamped = v.clamp(0, 255);
        dst[i] = clamped;
        dst[i + 1] = clamped;
        dst[i + 2] = clamped;
      }
    }

    // Re-encode to PNG via ui.Image.
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final outCodec = await ui.ImageDescriptor.raw(
      await ui.ImmutableBuffer.fromUint8List(dst),
      width: w,
      height: h,
      pixelFormat: ui.PixelFormat.rgba8888,
    ).instantiateCodec();
    final outFrame = await outCodec.getNextFrame();
    canvas.drawImage(outFrame.image, Offset.zero, Paint());
    final picture = recorder.endRecording();
    final outImage = await picture.toImage(w, h);
    final pngData = await outImage.toByteData(format: ui.ImageByteFormat.png);

    image.dispose();
    outFrame.image.dispose();
    outImage.dispose();

    if (pngData == null) return file;

    final outFile = File('${file.parent.path}/processed_${file.uri.pathSegments.last}');
    await outFile.writeAsBytes(pngData.buffer.asUint8List());
    return outFile;
  }

  // ── OCR ────────────────────────────────────────────────────────────────

  Future<void> _convertAndRecognize(File file) async {
    // Grayscale + sharpen to reduce color noise and boost edges.
    final grayFile = await _preprocessImage(file);
    // Show the original image but recognize on the grayscale version.
    await _recognizeText(grayFile);
  }

  Future<void> _recognizeText(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final imgSize =
        Size(frame.image.width.toDouble(), frame.image.height.toDouble());
    frame.image.dispose();

    final inputImage = InputImage.fromFile(file);
    final recognized = await _textRecognizer.processImage(inputImage);

    final items = <_OcrItem>[];
    final seen = <String>{};
    final unique = <String>[];

    if (widget.mode == CameraOcrMode.kanji) {
      _extractKanji(recognized, items, seen, unique);
    } else {
      _extractWords(recognized, items, seen, unique);
    }

    if (!mounted) return;
    setState(() {
      _imageSize = imgSize;
      _ocrItems = items;
      _uniqueItems = unique;
      _processing = false;
      _noTextFound = items.isEmpty;
    });
  }

  void _extractKanji(RecognizedText recognized, List<_OcrItem> items,
      Set<String> seen, List<String> unique) {
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          final text = element.text;
          final bbox = element.boundingBox;
          int charIndex = 0;
          for (final rune in text.runes) {
            final char = String.fromCharCode(rune);
            final charCount = text.runes.length;
            final charWidth = bbox.width / charCount;
            final charRect = Rect.fromLTWH(
              bbox.left + charIndex * charWidth,
              bbox.top,
              charWidth,
              bbox.height,
            );
            if (_isCjk(rune)) {
              items.add(_OcrItem(char, charRect));
              if (seen.add(char)) unique.add(char);
            }
            charIndex++;
          }
        }
      }
    }
  }

  void _extractWords(RecognizedText recognized, List<_OcrItem> items,
      Set<String> seen, List<String> unique) {
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          final text = element.text;
          final bbox = element.boundingBox;
          if (!text.runes.any((r) => _isCjk(r))) continue;

          final tokens = _tokenize(text);
          final charCount = text.runes.length;
          final charWidth = bbox.width / charCount;

          int charOffset = 0;
          for (final token in tokens) {
            final tokenLen = token.runes.length;
            if (token.runes.any((r) => _isCjk(r))) {
              final tokenRect = Rect.fromLTWH(
                bbox.left + charOffset * charWidth,
                bbox.top,
                tokenLen * charWidth,
                bbox.height,
              );
              items.add(_OcrItem(token, tokenRect));
              if (seen.add(token)) unique.add(token);
            }
            charOffset += tokenLen;
          }
        }
      }
    }
  }

  List<String> _tokenize(String text) {
    final wordIndex = widget.wordIndex;
    if (wordIndex == null) return [text];

    final chars = text.runes.map((r) => String.fromCharCode(r)).toList();
    final result = <String>[];
    int i = 0;

    while (i < chars.length) {
      String? bestMatch;
      final maxLen = (chars.length - i).clamp(0, 8);
      for (int len = maxLen; len >= 2; len--) {
        final candidate = chars.sublist(i, i + len).join();
        if (wordIndex.containsWord(candidate)) {
          bestMatch = candidate;
          break;
        }
      }
      if (bestMatch != null) {
        result.add(bestMatch);
        i += bestMatch.runes.length;
      } else {
        result.add(chars[i]);
        i++;
      }
    }
    return result;
  }

  static bool _isCjk(int cp) {
    return (cp >= 0x4E00 && cp <= 0x9FFF) || (cp >= 0x3400 && cp <= 0x4DBF);
  }

  // ── Selection ──────────────────────────────────────────────────────────

  void _toggleItem(String item) {
    setState(() {
      if (_selected.contains(item)) {
        _selected.remove(item);
      } else {
        _selected.add(item);
      }
    });
  }

  void _confirmSelection() {
    Navigator.pop(context, List<String>.from(_selected));
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isWordMode = widget.mode == CameraOcrMode.word;
    return Scaffold(
      appBar: AppBar(
        title: Text(isWordMode ? l.cameraOcrTitleWord : l.cameraOcrTitle),
        actions: [
          if (_imageFile != null)
            IconButton(
              icon: const Icon(Icons.crop),
              tooltip: 'Crop',
              onPressed: _cropImage,
            ),
          if (_imageFile != null)
            IconButton(
              icon: const Icon(Icons.add_a_photo),
              onPressed: _showSourcePicker,
            ),
        ],
      ),
      body: SafeArea(
        child: _imageFile == null
            ? Center(child: Text(l.cameraOcrProcessing))
            : Column(
                children: [
                  // Image with overlaid markers (zoomable).
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 5.0,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return _buildImageWithOverlays(constraints);
                          },
                        ),
                      ),
                    ),
                  ),
                  if (_processing)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(l.cameraOcrProcessing),
                    ),
                  if (_noTextFound)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(l.cameraOcrNoText),
                    ),
                  // Selected items bar.
                  if (_selected.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selected.join(isWordMode ? '、' : ' '),
                              style: const TextStyle(
                                fontSize: 20,
                                fontFamily: 'NotoSansJP',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: _confirmSelection,
                            icon: const Icon(Icons.check, size: 18),
                            label: Text(l.cameraOcrDone),
                          ),
                        ],
                      ),
                    ),
                  // Instruction + chips.
                  if (_uniqueItems.isNotEmpty && _selected.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Text(
                        isWordMode
                            ? l.cameraOcrInstructionWord
                            : l.cameraOcrInstruction,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  if (_uniqueItems.isNotEmpty)
                    SizedBox(
                      height: 56,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        itemCount: _uniqueItems.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final item = _uniqueItems[index];
                          final isSelected = _selected.contains(item);
                          return InkWell(
                            onTap: () => _toggleItem(item),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: isWordMode
                                  ? const EdgeInsets.symmetric(horizontal: 12)
                                  : null,
                              width: isWordMode ? null : 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                    : null,
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outline,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: isWordMode ? 20 : 28,
                                  fontFamily: 'NotoSansJP',
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
      ),
    );
  }

  Widget _buildImageWithOverlays(BoxConstraints constraints) {
    if (_imageSize == Size.zero) {
      return Image.file(_imageFile!, fit: BoxFit.contain);
    }

    final aspectRatio = _imageSize.width / _imageSize.height;
    final availableAspect = constraints.maxWidth / constraints.maxHeight;

    double displayW, displayH, offsetX, offsetY;
    if (aspectRatio > availableAspect) {
      displayW = constraints.maxWidth;
      displayH = displayW / aspectRatio;
      offsetX = 0;
      offsetY = (constraints.maxHeight - displayH) / 2;
    } else {
      displayH = constraints.maxHeight;
      displayW = displayH * aspectRatio;
      offsetX = (constraints.maxWidth - displayW) / 2;
      offsetY = 0;
    }

    final scaleX = displayW / _imageSize.width;
    final scaleY = displayH / _imageSize.height;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.file(_imageFile!, fit: BoxFit.contain),
        ),
        for (final item in _ocrItems)
          Positioned(
            left: offsetX + item.imageRect.left * scaleX,
            top: offsetY + item.imageRect.top * scaleY,
            width: item.imageRect.width * scaleX,
            height: item.imageRect.height * scaleY,
            child: GestureDetector(
              onTap: () => _toggleItem(item.text),
              child: Container(
                decoration: BoxDecoration(
                  color: _selected.contains(item.text)
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.35)
                      : Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.4),
                  border: Border.all(
                    color: _selected.contains(item.text)
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.7),
                    width: _selected.contains(item.text) ? 2.5 : 1.5,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Direct camera screen (rear, no confirm dialog) ───────────────────────

class _DirectCameraScreen extends StatefulWidget {
  final CameraDescription camera;
  const _DirectCameraScreen({required this.camera});

  @override
  State<_DirectCameraScreen> createState() => _DirectCameraScreenState();
}

class _DirectCameraScreenState extends State<_DirectCameraScreen> {
  late CameraController _controller;
  late Future<void> _initFuture;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_capturing) return;
    setState(() => _capturing = true);
    try {
      final xFile = await _controller.takePicture();
      if (!mounted) return;
      Navigator.pop(context, File(xFile.path));
    } catch (_) {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              Center(child: CameraPreview(_controller)),
              // Shutter button.
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _capture,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: _capturing
                            ? Colors.white38
                            : Colors.white24,
                      ),
                    ),
                  ),
                ),
              ),
              // Close button.
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
