import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../../app_dependencies.dart';
import '../../data/composita_repository.dart';
import '../../data/kanji_info_repository.dart';
import '../../data/sentences_repository.dart';
import '../../l10n/app_localizations.dart';
import '../learning/composita_picker.dart';
import '../review/furigana_sentence.dart';
import '../review/review_repository.dart';
import '../review/sentence_selection.dart'
    show isKanji, compositaWithinCeiling, mergeComposita, selectCompositaForIntroduction;
import '../review/study_scope.dart';
import '../stroke_order/stroke_order_view.dart';
import '../../widgets/tts_button.dart';

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

  /// When `true`, only shows kanji, readings/meaning, keyword, and story --
  /// omits stroke order, composita list, and example sentences. Used by the
  /// custom edit screen's bottom sheet where a CompositaPicker follows and
  /// the full detail would be redundant.
  final bool compact;

  const KanjiDetailContent({
    super.key,
    required this.character,
    required this.deps,
    this.scrollable = true,
    this.compact = false,
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
  Set<String>? _selectedComposita;
  List<Composita> _userComposita = [];
  /// User-added sentences grouped by word, with their DB ids for deletion.
  Map<String, List<({int id, ExampleSentence sentence})>> _userSentencesByWord = {};

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
      _reviewRepo.customCompositaFor(widget.character).then((selected) {
        if (mounted) setState(() => _selectedComposita = selected);
      });
      _reviewRepo.userCompositaFor(widget.character).then((user) {
        if (mounted) setState(() => _userComposita = user);
      });
      _loadUserSentences();
    }
  }

  Future<void> _loadUserSentences() async {
    // Load user sentences for all composita words of this character.
    final bundled = widget.deps.composita.lookup(widget.character);
    final user = await _reviewRepo.userCompositaFor(widget.character);
    final merged = mergeComposita(bundled, user);
    final result = <String, List<({int id, ExampleSentence sentence})>>{};
    for (final c in merged) {
      final sentences = await _reviewRepo.userSentencesFor(c.word, c.reading);
      if (sentences.isNotEmpty) {
        result[c.word] = sentences;
      }
    }
    if (mounted) setState(() => _userSentencesByWord = result);
  }

  Future<void> _showAddSentenceDialog(String word) async {
    final l = AppLocalizations.of(context)!;
    final sentenceController = TextEditingController();
    final translationController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.addSentenceButton),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: sentenceController,
                decoration: InputDecoration(
                  hintText: l.addSentenceHint(word),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || !v.contains(word)) {
                    return l.addSentenceValidation(word);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: translationController,
                decoration: InputDecoration(
                  hintText: l.addSentenceTranslationHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.dialogCancel),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: Text(l.addSentenceButton),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      final sentence = sentenceController.text;
      final translation = translationController.text.isEmpty
          ? null
          : translationController.text;
      await _reviewRepo.addUserSentence(word, sentence, translation);
      await _loadUserSentences();
    }
  }

  void _showWordPickerForSentence(List<Composita> composita) {
    if (composita.length == 1) {
      _showAddSentenceDialog(composita.first.word);
      return;
    }
    // Multiple composita — let the user pick which word to add a sentence for.
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final c in composita)
                ListTile(
                  title: Text('${c.word} (${c.reading})'),
                  subtitle: Text(c.meaning, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showAddSentenceDialog(c.word);
                  },
                ),
            ],
          ),
        );
      },
    );
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

  // Per displayed composita word, not per kanji overall -- SentencesRepository
  // already caps each word's own list at ~5, curated/shortest first, so this
  // just trims further to keep the (last, most space-hungry) section from
  // dwarfing everything above it.
  static const _maxSentencesPerComposita = 2;

  /// Returns all composita for this kanji: user-added first, then bundled
  /// ranked by frequency. No display cap — the user asked to see all.
  List<Composita> _selectComposita(List<Composita> all) {
    final userWords = _userComposita.map((c) => c.word).toSet();
    final user = all.where((c) => userWords.contains(c.word)).toList();
    final bundled = all.where((c) => !userWords.contains(c.word)).toList();
    final ranked = rankComposita(bundled);
    final seen = <String>{};
    final result = <Composita>[];
    for (final c in [...user, ...ranked]) {
      if (seen.add(c.word)) result.add(c);
    }
    return result;
  }

  List<(Composita, ExampleSentence, int?)> _exampleSentencesFor(
    List<Composita> composita,
  ) {
    final entries = <(Composita, ExampleSentence, int?)>[];
    for (final c in composita) {
      // User sentences first, with their DB ids for deletion.
      final userSentences = _userSentencesByWord[c.word] ?? [];
      for (final us in userSentences) {
        entries.add((c, us.sentence, us.id));
      }
      final sentences = widget.deps.sentences.lookup(c.word);
      for (final s in sentences.take(_maxSentencesPerComposita)) {
        entries.add((c, s, null));
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
        : _selectComposita(mergeComposita(
            widget.deps.composita.lookup(widget.character),
            _userComposita,
          ));
    final exampleSentences = isKana
        ? const <(Composita, ExampleSentence, int?)>[]
        : _exampleSentencesFor(composita);

    final column = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(widget.character, style: const TextStyle(fontSize: 56, fontFamily: 'NotoSansJP')),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: l.copyToClipboard,
                onPressed: _copyToClipboard,
              ),
              if (!isKana && !widget.compact)
                _PoolActionButton(
                  character: widget.character,
                  deps: widget.deps,
                  reviewRepo: _reviewRepo,
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
              _ReadingsLine(
                label: l.kanjiDetailOnyomi,
                readings: info.on,
                character: widget.character,
                deps: widget.deps,
              ),
            if (info.kun.isNotEmpty)
              _ReadingsLine(
                label: l.kanjiDetailKunyomi,
                readings: info.kun,
                character: widget.character,
                deps: widget.deps,
              ),
            if (info.meanings.isNotEmpty)
              _InfoLine(label: l.kanjiDetailMeaning, value: info.meanings.join(', ')),
          ],
          if (strokes != null && !widget.compact) ...[
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
          if (composita.isNotEmpty && !widget.compact) ...[
            const SizedBox(height: 16),
            Text(
              l.kanjiDetailComposita,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...composita.map((c) => _CompositaLine(
              composita: c,
              isSelected: _selectedComposita?.contains(c.word) ?? false,
            )),
          ],
          if (exampleSentences.isNotEmpty && !widget.compact) ...[
            const SizedBox(height: 16),
            Text(
              l.kanjiDetailExampleSentences,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < exampleSentences.length; i++) ...[
              if (i > 0) const Divider(),
              _ExampleSentenceBlock(
                composita: exampleSentences[i].$1,
                sentence: exampleSentences[i].$2,
                kanjiLookup: widget.deps.kanjiInfo.lookup,
                userSentenceId: exampleSentences[i].$3,
                onDelete: exampleSentences[i].$3 != null
                    ? () async {
                        await _reviewRepo.removeUserSentence(
                            exampleSentences[i].$3!);
                        await _loadUserSentences();
                      }
                    : null,
              ),
            ],
          ],
          if (composita.isNotEmpty && !widget.compact) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  // Show a picker dialog for which composita word to add a sentence for.
                  _showWordPickerForSentence(composita);
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text(l.addSentenceButton),
              ),
            ),
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

/// Like [_InfoLine] but renders each reading as a separate span, italicizing
/// rare readings (those appearing in ≤2 composita words). KANJIDIC readings
/// use katakana for on'yomi and hiragana with okurigana dots for kun'yomi;
/// composita-derived frequencies use plain hiragana stems — this widget
/// normalizes both sides before comparing.
class _ReadingsLine extends StatelessWidget {
  final String label;
  final List<String> readings;
  final String character;
  final AppDependencies deps;

  const _ReadingsLine({
    required this.label,
    required this.readings,
    required this.character,
    required this.deps,
  });

  /// Normalize a KANJIDIC reading to a plain hiragana stem for frequency
  /// lookup: strip the okurigana part after "." (kun readings), then convert
  /// katakana to hiragana (on readings).
  static String _normalize(String reading) {
    // Strip okurigana marker and everything after it.
    final dotIdx = reading.indexOf('.');
    final stem = dotIdx >= 0 ? reading.substring(0, dotIdx) : reading;
    // Katakana → hiragana (offset 0x60).
    return String.fromCharCodes(stem.runes.map((r) {
      if (r >= 0x30A1 && r <= 0x30F6) return r - 0x60;
      return r;
    }));
  }

  @override
  Widget build(BuildContext context) {
    final freq = deps.readingFrequency;
    final spans = <InlineSpan>[];
    for (var i = 0; i < readings.length; i++) {
      if (i > 0) spans.add(const TextSpan(text: '、'));
      final r = readings[i];
      final normalized = _normalize(r);
      final rare = freq.isRare(character, normalized);
      if (rare) {
        spans.add(TextSpan(
          text: '[$r]',
          style: TextStyle(color: Colors.grey.shade500),
        ));
      } else {
        spans.add(TextSpan(text: r));
      }
    }
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
            ...spans,
          ],
        ),
      ),
    );
  }
}

class _CompositaLine extends StatelessWidget {
  final Composita composita;
  final bool isSelected;

  const _CompositaLine({required this.composita, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            if (isSelected)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.check,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
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

/// Shows "Add to learning" or "Edit composita" depending on pool membership.
class _PoolActionButton extends StatefulWidget {
  final String character;
  final AppDependencies deps;
  final ReviewRepository reviewRepo;

  const _PoolActionButton({
    required this.character,
    required this.deps,
    required this.reviewRepo,
  });

  @override
  State<_PoolActionButton> createState() => _PoolActionButtonState();
}

class _PoolActionButtonState extends State<_PoolActionButton> {
  @override
  void initState() {
    super.initState();
    widget.deps.studyScope.scope.addListener(_onScopeChanged);
  }

  @override
  void dispose() {
    widget.deps.studyScope.scope.removeListener(_onScopeChanged);
    super.dispose();
  }

  void _onScopeChanged() {
    if (mounted) setState(() {});
  }

  bool get _inPool =>
      widget.deps.studyScope.scope.value.characters.contains(widget.character);

  void _addToPool() async {
    final char = widget.character;
    final scope = widget.deps.studyScope.scope.value;

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
      await widget.reviewRepo.addCustomComposita(char, word);
    }
    await widget.reviewRepo.introduceCardsForCharacters(
      {char},
      compositaWordsByChar: {char: words},
    );
    await widget.deps.studyScope.addCharacters({char});
    // Only open the picker if there are composita to adjust; otherwise
    // the user would see an empty sheet they can only dismiss.
    if (mounted && bundled.isNotEmpty) _openCompositaPicker();
  }

  void _openCompositaPicker() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: CompositaPicker(
                character: widget.character,
                composita: widget.deps.composita.lookup(widget.character),
                reviewRepo: widget.reviewRepo,
                wordIndex: widget.deps.wordIndex,
                recognizer: widget.deps.recognizer,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (_inPool) {
      return IconButton(
        icon: const Icon(Icons.tune, color: Colors.indigo),
        tooltip: l.kanjiDetailEditComposita,
        onPressed: _openCompositaPicker,
      );
    }
    return IconButton(
      icon: const Icon(Icons.add_circle_outline),
      tooltip: l.kanjiDetailAddToLearning,
      onPressed: _addToPool,
    );
  }
}

class _ExampleSentenceBlock extends StatelessWidget {
  final Composita composita;
  final ExampleSentence sentence;
  final KanjiInfo? Function(String char)? kanjiLookup;
  final int? userSentenceId;
  final VoidCallback? onDelete;

  const _ExampleSentenceBlock({
    required this.composita,
    required this.sentence,
    this.kanjiLookup,
    this.userSentenceId,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isUser = sentence.source == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                composita.word,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 6),
                Text(
                  l.userSentenceSource,
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade400),
                ),
              ],
              const Spacer(),
              if (isUser && onDelete != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onDelete,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FuriganaSentence(
                  tokens: sentence.tokens,
                  highlightTargetBox: true,
                  kanjiLookup: kanjiLookup,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TtsButton(text: sentence.sentence),
              ),
            ],
          ),
          if (!isUser && sentence.source != 'synthetic')
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  sentence.source == 'tatoeba' ? 'Tatoeba' : 'LLM-generated',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ),
            ),
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
