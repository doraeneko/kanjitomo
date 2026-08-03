import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_drawing/path_drawing.dart';

/// KanjiVG's fixed SVG viewBox size -- every stroke's path data (and the
/// stroke-width the source data was authored at) is in this coordinate
/// space. See kanjirec/scripts/build_stroke_paths.py, which produced the
/// asset this repository loads.
const double kanjiVgViewBoxSize = 109;

class KanjiStrokes {
  final int strokeCount;
  final List<ui.Path> paths; // in the 109x109 KanjiVG viewBox space, one per stroke, in stroke order
  const KanjiStrokes({required this.strokeCount, required this.paths});
}

/// Loads assets/stroke_paths.json (raw KanjiVG stroke path data) once, then
/// parses SVG path data into ui.Path lazily per character -- 2,321 entries
/// is cheap to hold as decoded JSON, but eagerly building a Path for every
/// stroke of every character at startup isn't worth it when most will never
/// be viewed in a given session.
class StrokePathsRepository {
  static const _asset = 'assets/stroke_paths.json';

  Map<String, dynamic> _raw = {};
  final Map<String, KanjiStrokes> _cache = {};

  Future<void> load() async {
    _raw = jsonDecode(await rootBundle.loadString(_asset)) as Map<String, dynamic>;
  }

  /// Null for REJECT or any character absent from the bundled data (not
  /// expected for the 2,321 kanji/kana classes, but defensive against a
  /// future class-list change outpacing this asset).
  KanjiStrokes? lookup(String char) {
    final cached = _cache[char];
    if (cached != null) return cached;

    final entry = _raw[char] as Map<String, dynamic>?;
    if (entry == null) return null;

    final strokes = (entry['strokes'] as List).cast<Map<String, dynamic>>();
    final paths = strokes
        .map((s) => parseSvgPathData(s['d'] as String))
        .toList();
    final result = KanjiStrokes(
      strokeCount: entry['strokeCount'] as int,
      paths: paths,
    );
    _cache[char] = result;
    return result;
  }
}
