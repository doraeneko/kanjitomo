import 'package:flutter/material.dart';

import '../../app_dependencies.dart';
import 'kanji_detail_content.dart';

/// Full-screen shell for [KanjiDetailContent], reached from the kanji
/// browser grid. The lookup screen embeds the same content in a bottom
/// sheet instead -- same widget, different presentation.
class KanjiDetailScreen extends StatelessWidget {
  final String character;
  final AppDependencies deps;

  const KanjiDetailScreen({
    super.key,
    required this.character,
    required this.deps,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(character)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: KanjiDetailContent(character: character, deps: deps),
        ),
      ),
    );
  }
}
