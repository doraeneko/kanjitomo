import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/canonicalize.dart';
import '../../core/theme/app_colors.dart';
import '../../core/drawing_canvas.dart';
import '../../core/kanji_rasterizer.dart';
import '../../core/kanji_recognizer.dart';
import '../../l10n/app_localizations.dart';

/// Shared draw-then-pick-from-top-K interaction for the drawFromMeaning and
/// drawInSentence card types: draw on the canvas, which recognizes
/// automatically as soon as each stroke ends (no separate "Recognize" step),
/// then tap whichever of the top-K non-reject candidates the user believes
/// they drew. Doesn't know the target character itself -- grading (comparing
/// the pick against the target) is the caller's job via [onPicked], since
/// this widget is purely the drawing/recognition mechanic. Shows at most
/// [topK] candidates, but collapses to just the top one whenever the
/// recognizer is already confident (>= [confidentThreshold]) -- no point
/// making the user disambiguate against distractors when there's nothing
/// to disambiguate.
class DrawAndPickWidget extends StatefulWidget {
  final KanjiRecognizer recognizer;
  final double displaySize;
  final int topK;
  final double confidentThreshold;
  final void Function(List<Prediction> topCandidates, String userPick)
  onPicked;
  final VoidCallback? onDontKnow;
  final bool allowKana;
  /// When true, candidates are shown to the right of the canvas instead of
  /// below it, and the "Which one did you draw?" text is omitted. The top
  /// candidate gets a larger button for fast tapping. "Clear drawing" moves
  /// below the canvas on the left side.
  final bool candidatesOnSide;
  /// Optional callback shown as a "Clear word" button next to "Clear drawing"
  /// in the side layout. Ignored in column layout.
  final VoidCallback? onClearWord;
  /// Label for the clear-word button. Required when [onClearWord] is provided.
  final String? clearWordLabel;

  const DrawAndPickWidget({
    super.key,
    required this.recognizer,
    required this.onPicked,
    this.onDontKnow,
    this.displaySize = 260,
    this.topK = 3,
    this.confidentThreshold = 0.9,
    this.allowKana = false,
    this.candidatesOnSide = false,
    this.onClearWord,
    this.clearWordLabel,
  });

  @override
  State<DrawAndPickWidget> createState() => _DrawAndPickWidgetState();
}

class _DrawAndPickWidgetState extends State<DrawAndPickWidget> {
  static const int _supersampleSize = 256;
  static const double _brushWidth = 2.0;
  // Requesting extra beyond topK so isReject predictions don't shrink the
  // real candidate list below topK when they land in the raw top-K.
  int get _candidateK => widget.topK + 3;

  final List<Stroke> _strokes = [];
  Stroke? _currentStroke;
  Float32List? _canonicalizedInput;
  bool _recognizing = false;
  List<Prediction>? _topCandidates;

  void _onStrokeStart(Offset gridPoint) {
    setState(() => _currentStroke = Stroke()..points.add(gridPoint));
  }

  void _onStrokeUpdate(Offset gridPoint) {
    setState(() => _currentStroke?.points.add(gridPoint));
  }

  Future<void> _onStrokeEnd() async {
    final stroke = _currentStroke;
    if (stroke == null) return;
    setState(() {
      _strokes.add(stroke);
      _currentStroke = null;
    });
    final image = await KanjiRasterizer.rasterize(
      _strokes,
      brushWidth: _brushWidth,
      size: _supersampleSize,
    );
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    _canonicalizedInput = canonicalize(rgba!, image.width, image.height);
    if (mounted) setState(() => _topCandidates = null);
    await _recognize();
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
      _canonicalizedInput = null;
      _topCandidates = null;
    });
  }

  Future<void> _undoLastStroke() async {
    if (_strokes.isEmpty) return;
    setState(() {
      _strokes.removeLast();
      _topCandidates = null;
    });
    if (_strokes.isEmpty) {
      setState(() => _canonicalizedInput = null);
      return;
    }
    final image = await KanjiRasterizer.rasterize(
      _strokes,
      brushWidth: _brushWidth,
      size: _supersampleSize,
    );
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    _canonicalizedInput = canonicalize(rgba!, image.width, image.height);
    if (mounted) setState(() => _topCandidates = null);
    await _recognize();
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

  static bool _isKatakana(String char) {
    if (char.isEmpty) return false;
    final c = char.codeUnitAt(0);
    return c >= 0x30A0 && c <= 0x30FF;
  }

  Future<void> _recognize() async {
    final input = _canonicalizedInput;
    if (input == null || !widget.recognizer.isReady) return;
    setState(() => _recognizing = true);
    try {
      final raw = await widget.recognizer.predictTopK(input, k: _candidateK);
      final nonReject = raw.where((p) => !p.isReject && (widget.allowKana || !_isKana(p.label))).toList();
      final shown =
          (nonReject.isNotEmpty &&
              nonReject.first.probability >= widget.confidentThreshold)
          ? nonReject.take(1).toList()
          : nonReject.take(widget.topK).toList();
      if (mounted) setState(() => _topCandidates = shown);
    } finally {
      if (mounted) setState(() => _recognizing = false);
    }
  }

  Widget _buildCandidateButton(Prediction p, List<Prediction> topCandidates, {bool large = false, bool compact = false}) {
    final fontSize = compact ? 28.0 : large ? 36.0 : 28.0;
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
        : large
            ? const EdgeInsets.symmetric(horizontal: 24, vertical: 14)
            : const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    return FilledButton.tonal(
      onPressed: () => widget.onPicked(topCandidates, p.label),
      style: FilledButton.styleFrom(padding: padding),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            p.label,
            style: TextStyle(fontSize: fontSize, fontFamily: 'NotoSansJP'),
          ),
          if (_isHiragana(p.label) || _isKatakana(p.label)) ...[
            const SizedBox(width: 4),
            Text(
              _isHiragana(p.label) ? 'H' : 'K',
              style: TextStyle(
                fontSize: 11,
                color: context.appColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final topCandidates = _topCandidates;

    if (widget.candidatesOnSide) {
      return _buildSideLayout(l, topCandidates);
    }
    return _buildColumnLayout(l, topCandidates);
  }

  Widget _buildColumnLayout(AppLocalizations l, List<Prediction>? topCandidates) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DrawingCanvas(
          displaySize: widget.displaySize,
          brushWidth: _brushWidth,
          strokes: _strokes,
          currentStroke: _currentStroke,
          onStrokeStart: _onStrokeStart,
          onStrokeUpdate: _onStrokeUpdate,
          onStrokeEnd: _onStrokeEnd,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: _clear, child: const Text('Clear')),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _strokes.isEmpty ? null : _undoLastStroke,
              icon: const Icon(Icons.undo, size: 18),
              label: const Text('Undo'),
            ),
          ],
        ),
        if (_recognizing)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l.drawAndPickRecognizing),
          ),
        if (topCandidates != null) ...[
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: topCandidates
                .map((p) => _buildCandidateButton(p, topCandidates))
                .toList(),
          ),
        ],
        if (widget.onDontKnow != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton(
              onPressed: widget.onDontKnow,
              child: Text(l.reviewDontKnow),
            ),
          ),
      ],
    );
  }

  Widget _buildSideLayout(AppLocalizations l, List<Prediction>? topCandidates) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side: canvas (constrained to displaySize width)
            SizedBox(
              width: widget.displaySize,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DrawingCanvas(
                    displaySize: widget.displaySize,
                    brushWidth: _brushWidth,
                    strokes: _strokes,
                    currentStroke: _currentStroke,
                    onStrokeStart: _onStrokeStart,
                    onStrokeUpdate: _onStrokeUpdate,
                    onStrokeEnd: _onStrokeEnd,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right side: candidates stacked vertically, constrained to canvas height
            Expanded(
              child: SizedBox(
                height: widget.displaySize.toDouble(),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  if (_recognizing)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(l.drawAndPickRecognizing),
                    ),
                  if (topCandidates != null)
                    ...topCandidates.asMap().entries.map((e) {
                      final isFirst = e.key == 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildCandidateButton(e.value, topCandidates, large: isFirst, compact: true),
                      );
                    }),
                  if (widget.onDontKnow != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: OutlinedButton(
                        onPressed: widget.onDontKnow,
                        child: Text(l.reviewDontKnow),
                      ),
                    ),
                ],
              ),
              ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(onPressed: _clear, child: const Text('Clear')),
            ElevatedButton.icon(
              onPressed: _strokes.isEmpty ? null : _undoLastStroke,
              icon: const Icon(Icons.undo, size: 18),
              label: const Text('Undo'),
            ),
            if (widget.onClearWord != null)
              ElevatedButton(onPressed: widget.onClearWord, child: Text(widget.clearWordLabel ?? '')),
          ],
        ),
      ],
    );
  }
}
