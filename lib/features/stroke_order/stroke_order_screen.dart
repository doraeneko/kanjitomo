import 'package:flutter/material.dart';

import '../../data/stroke_paths_repository.dart';
import 'stroke_order_view.dart';

/// Minimal harness for the stroke-order animation: type a character, see
/// its reference stroke order. Once the kanji browser exists, this
/// becomes a widget embedded in the kanji-detail screen rather than its
/// own screen with a text field.
class StrokeOrderScreen extends StatefulWidget {
  const StrokeOrderScreen({super.key});

  @override
  State<StrokeOrderScreen> createState() => _StrokeOrderScreenState();
}

class _StrokeOrderScreenState extends State<StrokeOrderScreen> {
  final StrokePathsRepository _repo = StrokePathsRepository();
  final TextEditingController _textController = TextEditingController(
    text: '愛',
  );
  bool _loading = true;
  String? _error;
  String _currentChar = '愛';

  @override
  void initState() {
    super.initState();
    _repo
        .load()
        .then((_) {
          if (mounted) setState(() => _loading = false);
        })
        .catchError((Object e) {
          if (mounted) {
            setState(() {
              _loading = false;
              _error = e.toString();
            });
          }
        });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _showChar(String char) {
    if (char.isEmpty) return;
    setState(() => _currentChar = char.substring(0, 1));
  }

  @override
  Widget build(BuildContext context) {
    final strokes = _loading ? null : _repo.lookup(_currentChar);

    return Scaffold(
      appBar: AppBar(title: const Text('Stroke order')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _textController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32),
                maxLength: 1,
                decoration: const InputDecoration(
                  labelText: 'Character',
                  counterText: '',
                ),
                onChanged: _showChar,
                onSubmitted: _showChar,
              ),
              const SizedBox(height: 24),
              if (_loading)
                const CircularProgressIndicator()
              else if (_error != null)
                Text(
                  'Failed to load stroke data: $_error',
                  style: const TextStyle(color: Colors.red),
                )
              else if (strokes == null)
                const Text('No stroke data for this character.')
              else
                StrokeOrderView(
                  key: ValueKey(_currentChar),
                  paths: strokes.paths,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
