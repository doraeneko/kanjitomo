import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app_dependencies.dart';
import '../../core/canonicalize.dart';
import '../../core/font_renderer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/drawing_canvas.dart';
import '../../core/kanji_mascot.dart';
import '../../core/kanji_rasterizer.dart';
import '../../core/kanji_recognizer.dart';
import '../../data/composita_repository.dart';
import '../../l10n/app_localizations.dart';
import '../kanji_browser/kanji_detail_content.dart';
import '../learning/composita_picker.dart';
import '../review/review_repository.dart';
import '../review/sentence_selection.dart'
    show isKanji, compositaWithinCeiling, selectCompositaForIntroduction;
import '../../widgets/coffee_button.dart';
import 'camera_ocr_screen.dart';

/// Draw -> up to 3 non-reject matches (collapsed to just the top one when
/// the recognizer is already confident, see [_confidentThreshold]) -> tap
/// one for its full detail (info sheet, sharing [KanjiDetailContent] with
/// the kanji browser). This is the ported recognition pipeline (canvas ->
/// rasterize -> canonicalize -> ONNX inference), same contract as
/// kanjirec's DrawScreen.
class LookupScreen extends StatefulWidget {
  final AppDependencies deps;

  const LookupScreen({super.key, required this.deps});

  @override
  State<LookupScreen> createState() => _LookupScreenState();
}

class _LookupScreenState extends State<LookupScreen> {
  double _displaySize = 300;
  static const double _maxDisplaySize = 300;
  static const double _minDisplaySize = 180;
  static const double _horizontalPadding = 32;

  // Matches config.SUPERSAMPLE_SIZE on the Python side -- canonicalizing
  // straight from a 64x64 capture would upscale a tiny crop back out.
  static const int _supersampleSize = 256;

  // Calibrated brush width, in 64x64 grid units -- must stay in sync with
  // what the model was trained on (kanjirec's config.BRUSH_WIDTH_UNITS).
  static const double _brushWidth = 2.0;

  // Requesting more than we show so isReject predictions (which don't count
  // as a usable candidate) don't shrink the real candidate list below
  // _shownCandidates when they land in the raw top-K.
  static const int _candidateK = 6;
  static const int _shownCandidates = 3;
  // Above this top-match probability, there's nothing to disambiguate --
  // show just the one candidate instead of distractors.
  static const double _confidentThreshold = 0.9;

  final List<Stroke> _strokes = [];
  Stroke? _currentStroke;
  String? _injectedCharacter;
  /// Remaining OCR picks from the camera (multi-select).
  List<String> _ocrQueue = [];

  Float32List? _canonicalizedInput;

  bool _recognizerLoading = true;
  String? _recognizerError;
  List<Prediction>? _predictions;
  bool _recognizing = false;

  KanjiRecognizer get _recognizer => widget.deps.recognizer;

  @override
  void initState() {
    super.initState();
    widget.deps.recognizerReady
        .then((_) {
          if (mounted) setState(() => _recognizerLoading = false);
        })
        .catchError((Object e) {
          if (mounted) {
            setState(() {
              _recognizerLoading = false;
              _recognizerError = e.toString();
            });
          }
        });
  }

  void _onStrokeStart(Offset gridPoint) {
    setState(() {
      _injectedCharacter = null;
      _currentStroke = Stroke()..points.add(gridPoint);
    });
  }

  void _onStrokeUpdate(Offset gridPoint) {
    setState(() {
      _currentStroke?.points.add(gridPoint);
    });
  }

  Future<void> _onStrokeEnd() async {
    final stroke = _currentStroke;
    if (stroke != null) {
      setState(() {
        _strokes.add(stroke);
        _currentStroke = null;
      });
      await _updatePreview();
      await _recognize();
    }
  }

  Future<void> _updatePreview() async {
    final image = await KanjiRasterizer.rasterize(
      _strokes,
      brushWidth: _brushWidth,
      size: _supersampleSize,
    );
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final canonicalizedInput = canonicalize(rgba!, image.width, image.height);
    if (!mounted) return;
    setState(() {
      _canonicalizedInput = canonicalizedInput;
      _predictions = null;
    });
  }

  Future<void> _recognize() async {
    final input = _canonicalizedInput;
    if (input == null || !_recognizer.isReady) return;
    setState(() => _recognizing = true);
    try {
      final raw = await _recognizer.predictTopK(input, k: _candidateK);
      final nonReject = raw.where((p) => !p.isReject).toList();
      final shown =
          (nonReject.isNotEmpty &&
              nonReject.first.probability >= _confidentThreshold)
          ? nonReject.take(1).toList()
          : nonReject.take(_shownCandidates).toList();
      if (!mounted) return;
      setState(() => _predictions = shown);
    } finally {
      if (mounted) setState(() => _recognizing = false);
    }
  }

  void _showKanjiInfo(String char) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: _AddToCustomButton(
                      character: char,
                      deps: widget.deps,
                    ),
                  ),
                  const SizedBox(height: 16),
                  KanjiDetailContent(
                    character: char,
                    deps: widget.deps,
                    scrollable: false,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
      _injectedCharacter = null;
      _ocrQueue = [];
      _canonicalizedInput = null;
      _predictions = null;
    });
  }

  Future<void> _undoLastStroke() async {
    if (_strokes.isEmpty) return;
    setState(() {
      _strokes.removeLast();
      _predictions = null;
    });
    if (_strokes.isEmpty) {
      setState(() => _canonicalizedInput = null);
      return;
    }
    await _updatePreview();
    await _recognize();
  }

  Future<void> _openCameraOcr() async {
    final items = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(builder: (_) => const CameraOcrScreen()),
    );
    if (items == null || items.isEmpty || !mounted) return;
    setState(() => _ocrQueue = List.of(items));
    await _recognizeInjectedCharacter(items.first);
  }

  void _pickFromOcrQueue(String character) {
    _recognizeInjectedCharacter(character);
  }

  Future<void> _recognizeInjectedCharacter(String character) async {
    setState(() {
      _injectedCharacter = character;
      _strokes.clear();
      _currentStroke = null;
      _predictions = null;
    });

    final image = await renderCharacterToImage(character, size: _supersampleSize);
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final input = canonicalize(rgba!, image.width, image.height);
    if (!mounted) return;
    setState(() {
      _canonicalizedInput = input;
      _recognizing = true;
    });

    try {
      final raw = await _recognizer.predictTopK(input, k: _candidateK);
      final nonReject = raw.where((p) => !p.isReject).toList();
      final shown =
          (nonReject.isNotEmpty &&
              nonReject.first.probability >= _confidentThreshold)
          ? nonReject.take(1).toList()
          : nonReject.take(_shownCandidates).toList();
      if (!mounted) return;
      setState(() => _predictions = shown);
    } finally {
      if (mounted) setState(() => _recognizing = false);
    }
  }

  static bool _isKana(String char) {
    if (char.isEmpty) return false;
    final c = char.codeUnitAt(0);
    return (c >= 0x3040 && c <= 0x309F) || (c >= 0x30A0 && c <= 0x30FF);
  }

  static bool _isHiragana(String char) {
    if (char.isEmpty) return false;
    final c = char.codeUnitAt(0);
    return c >= 0x3040 && c <= 0x309F;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    _displaySize = (screenWidth - _horizontalPadding).clamp(
      _minDisplaySize,
      _maxDisplaySize,
    );

    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const KanjiMascot(size: 40),
            const SizedBox(width: 8),
            Text(l.lookupTitle),
          ],
        ),
        actions: const [CoffeeButton()],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        DrawingCanvas(
                          displaySize: _displaySize,
                          brushWidth: _brushWidth,
                          strokes: _strokes,
                          currentStroke: _currentStroke,
                          onStrokeStart: _onStrokeStart,
                          onStrokeUpdate: _onStrokeUpdate,
                          onStrokeEnd: _onStrokeEnd,
                        ),
                        if (_injectedCharacter != null)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Center(
                                child: Text(
                                  _injectedCharacter!,
                                  style: TextStyle(
                                    fontSize: _displaySize * 0.7,
                                    fontFamily: 'NotoSansJP',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _strokes.isEmpty ? null : _undoLastStroke,
                          icon: const Icon(Icons.undo),
                          label: Text(l.undoStroke),
                        ),
                        ElevatedButton(
                          onPressed: _clear,
                          child: Text(l.lookupClearDrawing),
                        ),
                        ElevatedButton.icon(
                          onPressed: _openCameraOcr,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(l.lookupCamera),
                        ),
                      ],
                    ),
                    if (_ocrQueue.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            itemCount: _ocrQueue.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 6),
                            itemBuilder: (context, index) {
                              final char = _ocrQueue[index];
                              final isCurrent =
                                  char == _injectedCharacter;
                              return InkWell(
                                onTap: () => _pickFromOcrQueue(char),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                        : null,
                                    border: Border.all(
                                      color: isCurrent
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .outline,
                                      width: isCurrent ? 2 : 1,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    char,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontFamily: 'NotoSansJP',
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    if (_recognizing)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(l.lookupRecognizing),
                      ),
                    if (_recognizerLoading)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(l.lookupLoadingModel),
                      ),
                    if (_recognizerError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          l.lookupModelFailed(_recognizerError!),
                          style: TextStyle(
                            color: context.appColors.statusRed,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_predictions != null) ...[
                        Text(
                          _predictions!.length == 1
                              ? l.lookupBestMatch
                              : l.lookupTopN(_predictions!.length),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: _displaySize,
                          child: Column(
                            children: _predictions!.asMap().entries.map((
                              entry,
                            ) {
                              final rank = entry.key + 1;
                              final p = entry.value;
                              return InkWell(
                                onTap: () => _showKanjiInfo(p.label),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        child: Text('$rank.'),
                                      ),
                                      SizedBox(
                                        width: 48,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              p.label,
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontFamily: 'NotoSansJP',
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (_isKana(p.label))
                                              Padding(
                                                padding: const EdgeInsets.only(left: 2),
                                                child: Text(
                                                  _isHiragana(p.label) ? 'H' : 'K',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: context.appColors.textTertiary,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: p.probability,
                                            minHeight: 12,
                                            backgroundColor:
                                                context.appColors.progressBg,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 52,
                                        child: Text(
                                          '${(p.probability * 100).toStringAsFixed(1)}%',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Button that adds a kanji to the custom review set. Once added, it
/// opens the composita picker dialog so the user can immediately
/// configure which words to test.
class _AddToCustomButton extends StatefulWidget {
  final String character;
  final AppDependencies deps;

  const _AddToCustomButton({required this.character, required this.deps});

  @override
  State<_AddToCustomButton> createState() => _AddToCustomButtonState();
}

class _AddToCustomButtonState extends State<_AddToCustomButton> {
  bool _added = false;

  @override
  void initState() {
    super.initState();
    final scope = widget.deps.studyScope.scope.value;
    _added = scope.characters.contains(widget.character);
  }

  void _addAndOpenComposita() async {
    await widget.deps.ensureComposita();
    final char = widget.character;
    final scope = widget.deps.studyScope.scope.value;
    final reviewRepo = ReviewRepository(widget.deps.database);

    // Auto-select composita (same logic as Add/Remove screen).
    final bundled = widget.deps.composita.lookup(char);
    final ceiling = scope.compositaCeiling;
    final charLevel = widget.deps.jlptLevels.levelOf(char);
    final eligible = bundled.where((c) {
      if (!c.word.runes.any((r) => isKanji(r))) return false;
      return compositaWithinCeiling(c, ceiling, charJlptLevel: charLevel);
    }).toList();
    final selected = selectCompositaForIntroduction(
      char, eligible, scope.maxCompositaPerKanji,
      kanjiInfo: widget.deps.kanjiInfo.lookup(char),
    );
    final seen = <String>{};
    final words = [
      for (final c in selected)
        if (seen.add(c.word)) c.word,
    ];

    // Register composita and create cards.
    for (final word in words) {
      await reviewRepo.addCustomComposita(char, word);
    }
    await reviewRepo.introduceCardsForCharacters(
      {char},
      compositaWordsByChar: {char: words},
    );
    if (!scope.characters.contains(char)) {
      await widget.deps.studyScope.addCharacters({char});
    }

    if (!mounted) return;
    setState(() => _added = true);

    // Close the current sheet, then open the composita picker (only if
    // there are composita to adjust).
    Navigator.of(context).pop();

    if (bundled.isEmpty) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.lookupAddedNoComposita(char)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final all = rankComposita(bundled);
    showModalBottomSheet<void>(
      context: Navigator.of(context).context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CompositaPicker(
                    character: char,
                    composita: all,
                    reviewRepo: reviewRepo,
                    wordIndex: widget.deps.wordIndex,
                  ),
                  const Divider(height: 32),
                  KanjiDetailContent(
                    character: char,
                    deps: widget.deps,
                    scrollable: false,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static bool _isKana(String char) {
    if (char.isEmpty) return false;
    final c = char.codeUnitAt(0);
    return (c >= 0x3040 && c <= 0x309F) || (c >= 0x30A0 && c <= 0x30FF);
  }

  @override
  Widget build(BuildContext context) {
    if (_isKana(widget.character)) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      onPressed: _added ? null : _addAndOpenComposita,
      icon: Icon(_added ? Icons.check : Icons.add),
      label: Text(_added ? l.lookupInCustomReview : l.lookupAddToCustomReview),
    );
  }
}
