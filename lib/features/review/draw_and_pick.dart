import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/canonicalize.dart';
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

  const DrawAndPickWidget({
    super.key,
    required this.recognizer,
    required this.onPicked,
    this.displaySize = 260,
    this.topK = 3,
    this.confidentThreshold = 0.9,
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

  Future<void> _recognize() async {
    final input = _canonicalizedInput;
    if (input == null || !widget.recognizer.isReady) return;
    setState(() => _recognizing = true);
    try {
      final raw = await widget.recognizer.predictTopK(input, k: _candidateK);
      final nonReject = raw.where((p) => !p.isReject).toList();
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final topCandidates = _topCandidates;
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
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _clear, child: Text(l.drawAndPickClearDrawing)),
        if (_recognizing)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(l.drawAndPickRecognizing),
          ),
        if (topCandidates != null) ...[
          const SizedBox(height: 16),
          Text(l.drawAndPickWhichOne),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: topCandidates
                .map(
                  (p) => OutlinedButton(
                    onPressed: () => widget.onPicked(topCandidates, p.label),
                    child: Text(
                      p.label,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
