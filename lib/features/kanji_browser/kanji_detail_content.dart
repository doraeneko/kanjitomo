import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../../app_dependencies.dart';
import '../../data/composita_repository.dart';
import '../../data/sentences_repository.dart';
import '../../l10n/app_localizations.dart';
import '../review/furigana_sentence.dart';
import '../review/review_repository.dart';
import '../stroke_order/stroke_order_view.dart';

/// Shared kanji-detail content: readings/meaning, stroke order, the user's
/// personal keyword+story (editable, autosaved -- kept as two separate
/// fields so a short recall-cue keyword can be shown as a pre-draw hint
/// elsewhere without giving away the fuller story), and composita
/// (compound words). Embedded both in the lookup screen's bottom sheet (tap
/// a recognized candidate) and the kanji browser's detail screen (tap a
/// grid cell) -- same content, different presentation shell.
class KanjiDetailContent extends StatefulWidget {
  final String character;
  final AppDependencies deps;

  /// When `false`, the inner `SingleChildScrollView` is omitted so this
  /// widget can be embedded inside an outer scrollable without nesting
  /// scroll views.
  final bool scrollable;

  const KanjiDetailContent({
    super.key,
    required this.character,
    required this.deps,
    this.scrollable = true,
  });

  @override
  State<KanjiDetailContent> createState() => _KanjiDetailContentState();
}

class _KanjiDetailContentState extends State<KanjiDetailContent> {
  late final ReviewRepository _reviewRepo;
  late final TextEditingController _keywordController;
  late final TextEditingController _storyController;
  Timer? _keywordDebounce;
  Timer? _storyDebounce;

  static const _autosaveDelay = Duration(milliseconds: 500);

  // Kana have no on'yomi/kun'yomi/meaning, story, or composita -- a kanji
  // mnemonic keyword/story makes no sense for a character that already IS
  // its own reading, so this widget shows just the character and stroke
  // order for these instead of a mostly-empty kanji editor.
  bool get _isKana {
    if (widget.character.isEmpty) return false;
    final c = widget.character.codeUnitAt(0);
    return (c >= 0x3040 && c <= 0x309F) || (c >= 0x30A0 && c <= 0x30FF);
  }

  @override
  void initState() {
    super.initState();
    _reviewRepo = ReviewRepository(widget.deps.database);
    _keywordController = TextEditingController();
    _storyController = TextEditingController();
    if (!_isKana) {
      // Plain one-shot reads, not Streams: this widget is the only editor of
      // its own keyword/story fields, so there's no other writer to react to
      // while it's open. Deliberately not watchNote(...).first -- that still
      // opens and cancels a drift query stream, whose cleanup schedules a
      // timer that can outlive a widget test's tear-down and trip
      // flutter_test's "pending timer" check (confirmed directly once this
      // widget started being embedded inside the review session's feedback
      // screen).
      _reviewRepo.getStoryKeyword(widget.character).then((keyword) {
        if (mounted) _keywordController.text = keyword;
      });
      _reviewRepo.getNote(widget.character).then((story) {
        if (mounted) _storyController.text = story;
      });
    }
  }

  void _onKeywordChanged(String text) {
    _keywordDebounce?.cancel();
    _keywordDebounce = Timer(_autosaveDelay, () {
      _reviewRepo.upsertStoryKeyword(widget.character, text);
    });
  }

  void _onStoryChanged(String text) {
    _storyDebounce?.cancel();
    _storyDebounce = Timer(_autosaveDelay, () {
      _reviewRepo.upsertNote(widget.character, text);
    });
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.character));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.kanjiDetailCopied(widget.character)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _keywordDebounce?.cancel();
    _storyDebounce?.cancel();
    _keywordController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  // The bundled composita.json is capped PER JLPT level (not one flat
  // per-kanji cap) so the review engine's JLPT-ceiling filtering has a
  // genuinely level-balanced set to work with -- a common kanji can now
  // have well over 100 entries there. This lookup screen re-ranks (see
  // rankComposita) for display only and caps to [_maxDisplayedComposita]
  // (the review engine still consumes the full, level-balanced list from
  // CompositaRepository directly).
  static const _maxDisplayedComposita = 10;

  // Per displayed composita word, not per kanji overall -- SentencesRepository
  // already caps each word's own list at ~5, curated/shortest first, so this
  // just trims further to keep the (last, most space-hungry) section from
  // dwarfing everything above it.
  static const _maxSentencesPerComposita = 2;

  List<Composita> _selectComposita(List<Composita> all) =>
      rankComposita(all).take(_maxDisplayedComposita).toList();

  List<(Composita, ExampleSentence)> _exampleSentencesFor(
    List<Composita> composita,
  ) {
    final entries = <(Composita, ExampleSentence)>[];
    for (final c in composita) {
      final sentences = widget.deps.sentences.lookup(c.word);
      for (final s in sentences.take(_maxSentencesPerComposita)) {
        entries.add((c, s));
      }
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isKana = _isKana;
    final info = widget.deps.kanjiInfo.lookup(widget.character);
    final strokes = widget.deps.strokePaths.lookup(widget.character);
    final composita = isKana
        ? const <Composita>[]
        : _selectComposita(widget.deps.composita.lookup(widget.character));
    final exampleSentences = isKana
        ? const <(Composita, ExampleSentence)>[]
        : _exampleSentencesFor(composita);

    final column = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(widget.character, style: const TextStyle(fontSize: 56)),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: l.copyToClipboard,
                onPressed: _copyToClipboard,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (info == null && !isKana)
            Text(
              l.kanjiDetailNoDictionaryEntry,
              style: const TextStyle(color: Colors.black54),
            )
          else if (info != null) ...[
            if (info.on.isNotEmpty)
              _InfoLine(label: l.kanjiDetailOnyomi, value: info.on.join('、')),
            if (info.kun.isNotEmpty)
              _InfoLine(label: l.kanjiDetailKunyomi, value: info.kun.join('、')),
            if (info.meanings.isNotEmpty)
              _InfoLine(label: l.kanjiDetailMeaning, value: info.meanings.join(', ')),
          ],
          if (strokes != null) ...[
            const SizedBox(height: 16),
            Text(
              l.kanjiDetailStrokeOrder,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Center(
              child: StrokeOrderView(
                key: ValueKey(widget.character),
                paths: strokes.paths,
                displaySize: 110,
              ),
            ),
          ],
          if (!isKana) ...[
            const SizedBox(height: 16),
            Text(
              l.kanjiDetailKeyword,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _keywordController,
              onChanged: _onKeywordChanged,
              decoration: InputDecoration(
                hintText: l.kanjiDetailKeywordHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            Text(l.kanjiDetailStory, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _storyController,
              onChanged: _onStoryChanged,
              maxLines: null,
              minLines: 2,
              decoration: InputDecoration(
                hintText: l.kanjiDetailStoryHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
          if (composita.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l.kanjiDetailComposita,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...composita.map((c) => _CompositaLine(composita: c)),
          ],
          if (exampleSentences.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l.kanjiDetailExampleSentences,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final entry in exampleSentences)
              _ExampleSentenceBlock(composita: entry.$1, sentence: entry.$2),
          ],
        ],
      );

    return widget.scrollable
        ? SingleChildScrollView(child: column)
        : column;
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _CompositaLine extends StatelessWidget {
  final Composita composita;

  const _CompositaLine({required this.composita});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: composita.word,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: ' (${composita.reading}): ${composita.meaning}'),
            if (composita.effectiveJlptLevel != null)
              TextSpan(
                // "?" marks an estimate (inferred from this word's hardest
                // constituent kanji, not a real word-level JLPT tag -- see
                // Composita.isLevelInferred).
                text: composita.isLevelInferred
                    ? ' [N${composita.effectiveJlptLevel}?]'
                    : ' [N${composita.effectiveJlptLevel}]',
                style: TextStyle(color: Colors.grey.shade600),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExampleSentenceBlock extends StatelessWidget {
  final Composita composita;
  final ExampleSentence sentence;

  const _ExampleSentenceBlock({required this.composita, required this.sentence});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            composita.word,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          FuriganaSentence(tokens: sentence.tokens, highlightTargetBox: true),
          if (sentence.translation != null) ...[
            const SizedBox(height: 4),
            Text(
              sentence.translation!,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
