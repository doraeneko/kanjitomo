import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/canonicalize.dart';
import '../../core/drawing_canvas.dart';
import '../../core/kanji_rasterizer.dart';
import '../../core/kanji_recognizer.dart';
import '../../core/theme/app_colors.dart';

/// A grid of small drawing cells (like 原稿用紙) for writing words character
/// by character. Each cell auto-recognizes after a stroke and shows the top
/// candidate. Tapping a cell selects it for drawing. The recognized word is
/// the concatenation of all non-empty cells' top candidates.
class WritingGrid extends StatefulWidget {
  final KanjiRecognizer recognizer;
  final int columns;
  final int rows;
  final ValueChanged<String> onWordChanged;

  const WritingGrid({
    super.key,
    required this.recognizer,
    required this.onWordChanged,
    this.columns = 3,
    this.rows = 3,
  });

  @override
  State<WritingGrid> createState() => _WritingGridState();
}

class _WritingGridState extends State<WritingGrid> {
  static const int _supersampleSize = 256;
  static const double _brushWidth = 2.0;
  static const int _candidateK = 6;

  late List<_CellState> _cells;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    final count = widget.columns * widget.rows;
    _cells = List.generate(count, (_) => _CellState());
  }

  int get _cellCount => widget.columns * widget.rows;

  String get _word {
    final buf = StringBuffer();
    for (final cell in _cells) {
      if (cell.recognized != null) {
        buf.write(cell.recognized);
      }
    }
    return buf.toString();
  }

  void _notifyWord() {
    widget.onWordChanged(_word);
  }

  void _onStrokeStart(int index, Offset gridPoint) {
    if (index != _activeIndex) {
      setState(() => _activeIndex = index);
    }
    setState(() {
      _cells[index].currentStroke = Stroke()..points.add(gridPoint);
    });
  }

  void _onStrokeUpdate(int index, Offset gridPoint) {
    setState(() {
      _cells[index].currentStroke?.points.add(gridPoint);
    });
  }

  Future<void> _onStrokeEnd(int index) async {
    final cell = _cells[index];
    final stroke = cell.currentStroke;
    if (stroke == null) return;
    setState(() {
      cell.strokes.add(stroke);
      cell.currentStroke = null;
    });
    await _recognize(index);
  }

  Future<void> _recognize(int index) async {
    final cell = _cells[index];
    if (cell.strokes.isEmpty || !widget.recognizer.isReady) return;

    final image = await KanjiRasterizer.rasterize(
      cell.strokes,
      brushWidth: _brushWidth,
      size: _supersampleSize,
    );
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final input = canonicalize(rgba!, image.width, image.height);

    final raw = await widget.recognizer.predictTopK(input, k: _candidateK);
    final nonReject = raw.where((p) => !p.isReject).toList();
    if (!mounted) return;

    setState(() {
      cell.candidates = nonReject.take(5).toList();
      if (nonReject.isNotEmpty) {
        cell.recognized = nonReject.first.label;
      }
    });
    _notifyWord();
  }

  void _pickCandidate(int index, String label) {
    setState(() {
      _cells[index].recognized = label;
    });
    _notifyWord();
  }

  void _clearCell(int index) {
    setState(() {
      _cells[index] = _CellState();
    });
    _notifyWord();
  }

  void _clearAll() {
    setState(() {
      for (var i = 0; i < _cells.length; i++) {
        _cells[i] = _CellState();
      }
      _activeIndex = 0;
    });
    _notifyWord();
  }

  void _undoStroke(int index) async {
    final cell = _cells[index];
    if (cell.strokes.isEmpty) return;
    setState(() {
      cell.strokes.removeLast();
      cell.candidates = null;
      cell.recognized = null;
    });
    if (cell.strokes.isNotEmpty) {
      await _recognize(index);
    } else {
      _notifyWord();
    }
  }

  void _backspace() {
    // Find the last non-empty cell and clear it
    for (var i = _cells.length - 1; i >= 0; i--) {
      if (_cells[i].strokes.isNotEmpty || _cells[i].recognized != null) {
        _clearCell(i);
        setState(() => _activeIndex = i);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        // Cell size: fit columns with spacing
        const spacing = 3.0;
        final cellSize = ((availableWidth - spacing * (widget.columns - 1)) /
                widget.columns)
            .floorToDouble();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grid
            for (var row = 0; row < widget.rows; row++)
              Padding(
                padding: EdgeInsets.only(bottom: row < widget.rows - 1 ? spacing : 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var col = 0; col < widget.columns; col++)
                      _buildCell(
                        row * widget.columns + col,
                        cellSize,
                        spacing,
                        col < widget.columns - 1,
                        appColors,
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            // Candidate bar for active cell
            _buildCandidateBar(appColors),
            const SizedBox(height: 4),
            // Toolbar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _cells[_activeIndex].strokes.isEmpty
                      ? null
                      : () => _undoStroke(_activeIndex),
                  icon: const Icon(Icons.undo, size: 20),
                  tooltip: 'Undo',
                ),
                IconButton(
                  onPressed: _cells[_activeIndex].strokes.isEmpty
                      ? null
                      : () => _clearCell(_activeIndex),
                  icon: const Icon(Icons.clear, size: 20),
                  tooltip: 'Clear cell',
                ),
                IconButton(
                  onPressed: _word.isEmpty ? null : _backspace,
                  icon: const Icon(Icons.backspace_outlined, size: 20),
                  tooltip: 'Backspace',
                ),
                IconButton(
                  onPressed: _word.isEmpty ? null : _clearAll,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'Clear all',
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCell(
    int index,
    double cellSize,
    double spacing,
    bool addSpacing,
    AppColors appColors,
  ) {
    if (index >= _cellCount) return const SizedBox.shrink();
    final cell = _cells[index];
    final isActive = index == _activeIndex;

    return Padding(
      padding: EdgeInsets.only(right: addSpacing ? spacing : 0),
      child: Container(
          width: cellSize,
          height: cellSize,
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : appColors.textTertiary.withValues(alpha: 0.3),
              width: isActive ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
                  children: [
                    // Number hint for empty cells
                    if (cell.strokes.isEmpty && cell.recognized == null)
                      Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            color: appColors.textTertiary.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    DrawingCanvas(
                      displaySize: cellSize,
                      brushWidth: _brushWidth,
                      strokes: cell.strokes,
                      currentStroke: cell.currentStroke,
                      onStrokeStart: (p) => _onStrokeStart(index, p),
                      onStrokeUpdate: (p) => _onStrokeUpdate(index, p),
                      onStrokeEnd: () => _onStrokeEnd(index),
                    ),
                    // Show recognized character in corner
                    if (cell.recognized != null)
                      Positioned(
                        right: 1,
                        bottom: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 2, vertical: 0),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            cell.recognized!,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'NotoSansJP',
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
    );
  }

  Widget _buildCandidateBar(AppColors appColors) {
    final cell = _cells[_activeIndex];
    final candidates = cell.candidates;
    if (candidates == null || candidates.isEmpty) {
      return const SizedBox(height: 36);
    }
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: candidates.map((p) {
          final isSelected = p.label == cell.recognized;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () => _pickCandidate(_activeIndex, p.label),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : appColors.textTertiary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  p.label,
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'NotoSansJP',
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CellState {
  List<Stroke> strokes = [];
  Stroke? currentStroke;
  String? recognized;
  List<Prediction>? candidates;
}
