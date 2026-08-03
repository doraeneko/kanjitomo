import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:path_provider/path_provider.dart';

class Prediction {
  final String label;
  final double probability;
  final bool isReject;
  const Prediction(this.label, this.probability, this.isReject);
}

/// Loads the exported model + class list + inference contract from assets
/// (see scripts/export_onnx.py) and runs top-k inference.
class KanjiRecognizer {
  static const _modelAsset = 'assets/model/model.onnx';
  static const _classesAsset = 'assets/model/classes.json';
  static const _inferenceConfigAsset = 'assets/model/inference_config.json';

  OrtSession? _session;
  List<String> _classes = [];
  int _rejectIndex = -1;
  bool get isReady => _session != null;

  Future<void> load() async {
    final ort = OnnxRuntime();
    // NOT createSessionFromAsset(_modelAsset): that plugin method caches the
    // extracted file by filename only (e.g. "model.onnx") in the temp
    // directory, and reuses whatever's there across app rebuilds WITHOUT
    // checking if the underlying asset changed. Across this project's several
    // model swaps (all named model.onnx), that silently kept running a stale
    // model long after the asset was updated -- confirmed by comparing raw
    // ONNX logits between a direct Python run and this app's inference on
    // identical input. Content-addressed caching (hash in the filename) makes
    // that class of bug structurally impossible: a changed asset always gets
    // a new path, so there's never a stale hit.
    final modelData = await rootBundle.load(_modelAsset);
    final modelBytes = modelData.buffer.asUint8List(
      modelData.offsetInBytes,
      modelData.lengthInBytes,
    );
    final hash = md5.convert(modelBytes).toString();
    final tempDir = await getTemporaryDirectory();
    final versionedFile = File('${tempDir.path}/model_$hash.onnx');
    if (!await versionedFile.exists()) {
      await versionedFile.writeAsBytes(modelBytes);
    }
    _session = await ort.createSession(versionedFile.path);

    final classesJson = await rootBundle.loadString(_classesAsset);
    _classes = List<String>.from(jsonDecode(classesJson) as List);

    final inferenceJson =
        jsonDecode(await rootBundle.loadString(_inferenceConfigAsset))
            as Map<String, dynamic>;
    _rejectIndex = inferenceJson['reject_class_index'] as int;
  }

  Future<void> dispose() async {
    await _session?.close();
    _session = null;
  }

  Future<List<Prediction>> predictTopK(
    Float32List canonicalizedInput, {
    int k = 10,
  }) async {
    final session = _session;
    if (session == null) {
      throw StateError(
        'KanjiRecognizer.load() must complete before predicting.',
      );
    }

    final inputs = {
      'image': await OrtValue.fromList(canonicalizedInput, [1, 1, 64, 64]),
    };
    final outputs = await session.run(inputs);
    final rawLogits = await outputs['logits']!.asFlattenedList();
    final logits = rawLogits.map((e) => (e as num).toDouble()).toList();

    for (final v in outputs.values) {
      await v.dispose();
    }
    for (final v in inputs.values) {
      await v.dispose();
    }

    final probs = _softmax(logits);
    final indices = List<int>.generate(probs.length, (i) => i)
      ..sort((a, b) => probs[b].compareTo(probs[a]));

    return indices
        .take(k)
        .map((i) => Prediction(_classes[i], probs[i], i == _rejectIndex))
        .toList();
  }

  List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce(math.max);
    final exps = logits.map((l) => math.exp(l - maxLogit)).toList();
    final sumExp = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sumExp).toList();
  }
}
