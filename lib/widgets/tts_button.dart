import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_tts/flutter_tts.dart';

/// A small speaker-icon button that speaks [text] aloud using the device's
/// Japanese TTS engine. Uses a single shared [FlutterTts] instance so
/// concurrent buttons don't fight over the audio channel.
class TtsButton extends StatefulWidget {
  final String text;

  const TtsButton({super.key, required this.text});

  /// Shared instance — callers can call [stop] from their own dispose().
  static final FlutterTts tts = FlutterTts();
  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    await tts.setLanguage('ja-JP');
  }

  /// Convenience for screens that want to stop speech on disposal.
  /// Swallows [MissingPluginException] so widget tests (no platform
  /// channel) don't fail when a screen's dispose() calls this.
  static Future<void> stop() async {
    try {
      await tts.stop();
    } on MissingPluginException {
      // No TTS platform available (e.g. widget tests).
    }
  }

  @override
  State<TtsButton> createState() => _TtsButtonState();
}

class _TtsButtonState extends State<TtsButton> {
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    TtsButton.tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
    TtsButton.tts.setCancelHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
  }

  Future<void> _speak() async {
    await TtsButton._ensureInitialized();
    await TtsButton.tts.stop();
    setState(() => _speaking = true);
    await TtsButton.tts.speak(widget.text);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_speaking ? Icons.volume_up : Icons.volume_up_outlined),
      iconSize: 20,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      tooltip: 'Play',
      onPressed: _speak,
    );
  }
}
