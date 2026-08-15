import 'package:flutter/material.dart';

import '../../core/kanji_recognizer.dart';
import '../../data/composita_repository.dart';
import '../../data/word_index_repository.dart';
import '../../l10n/app_localizations.dart';
import '../review/draw_and_pick.dart';
import '../review/review_repository.dart';

/// Checklist of one kanji's composita words, letting the user pick which
/// ones are eligible for C+D (composita/sentence) testing in the custom
/// scope -- toggles [ReviewRepository.addCustomComposita]/
/// [removeCustomComposita] immediately (optimistic UI, no separate "save"
/// step) rather than batching changes for an explicit confirm.
///
/// Includes two ways to add new words:
/// 1. "Draw composita" — opens a full-screen dialog where the user draws
///    characters to build a word, then looks it up in JMdict.
/// 2. JMdict text search — type a word and search.
class CompositaPicker extends StatefulWidget {
  final String character;
  final List<Composita> composita;
  final ReviewRepository reviewRepo;
  final WordIndexRepository wordIndex;
  final KanjiRecognizer? recognizer;

  const CompositaPicker({
    super.key,
    required this.character,
    required this.composita,
    required this.reviewRepo,
    required this.wordIndex,
    this.recognizer,
  });

  @override
  State<CompositaPicker> createState() => _CompositaPickerState();
}

class _CompositaPickerState extends State<CompositaPicker> {
  static const _maxDisplayed = 10;

  Set<String>? _selected; // null while loading
  List<Composita> _userComposita = [];
  Set<String> _userWords = {};

  // JMdict search state.
  final _searchController = TextEditingController();
  List<WordEntry> _searchResults = const [];
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final selected = await widget.reviewRepo.customCompositaFor(
      widget.character,
    );
    final userComposita = await widget.reviewRepo.userCompositaFor(
      widget.character,
    );
    if (!mounted) return;
    setState(() {
      _selected = selected;
      _userComposita = userComposita;
      _userWords = userComposita.map((c) => c.word).toSet();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggle(String word, bool? value) async {
    setState(() => _selected = {...?_selected});
    if (value == true) {
      _selected!.add(word);
      await widget.reviewRepo.addCustomComposita(widget.character, word);
      await widget.reviewRepo.introduceCompositaCardsForWord(widget.character, word);
    } else {
      _selected!.remove(word);
      await widget.reviewRepo.removeCustomComposita(widget.character, word);
      await widget.reviewRepo.deleteCompositaCardsForWord(widget.character, word);
    }
  }

  void _search() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = const [];
        _searchError = null;
      });
      return;
    }
    final results = widget.wordIndex.lookup(query);
    // Filter to entries whose kanji spellings contain this picker's character.
    final matching = results
        .where((e) => e.kanji.any((k) => k.contains(widget.character)))
        .toList();
    setState(() {
      _searchResults = matching;
      _searchError = results.isNotEmpty && matching.isEmpty
          ? AppLocalizations.of(context)!
                .compositaPickerWordNotForChar(widget.character)
          : null;
    });
  }

  Future<void> _addFromSearch(WordEntry entry) async {
    final word = entry.kanji.firstWhere(
      (k) => k.contains(widget.character),
      orElse: () => entry.kanji.first,
    );
    final reading = entry.kana.first;
    final meaning = entry.meaning;

    await widget.reviewRepo.addUserComposita(
      widget.character,
      word,
      reading,
      meaning,
    );
    await widget.reviewRepo.introduceCompositaCardsForWord(widget.character, word);
    if (!mounted) return;

    final composita = Composita(
      word: word,
      reading: reading,
      meaning: meaning,
      jlptLevel: null,
      inferredJlptLevel: null,
      frequencyRank: 1,
    );
    setState(() {
      _userComposita.add(composita);
      _userWords.add(word);
      _selected = {...?_selected, word};
    });
  }

  /// Opens a full-screen dialog with a draw canvas + word field for
  /// building a composita word by drawing characters.
  Future<void> _openDrawComposita() async {
    final recognizer = widget.recognizer;
    if (recognizer == null) return;
    final result = await Navigator.of(context).push<_DrawnWordResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _DrawCompositaScreen(
          character: widget.character,
          recognizer: recognizer,
          wordIndex: widget.wordIndex,
        ),
      ),
    );
    if (result == null || !mounted) return;

    // Add the word as user composita.
    await widget.reviewRepo.addUserComposita(
      widget.character,
      result.word,
      result.reading,
      result.meaning,
    );
    await widget.reviewRepo.introduceCompositaCardsForWord(widget.character, result.word);
    if (!mounted) return;

    final composita = Composita(
      word: result.word,
      reading: result.reading,
      meaning: result.meaning,
      jlptLevel: null,
      inferredJlptLevel: null,
      frequencyRank: 1,
    );
    setState(() {
      _userComposita.add(composita);
      _userWords.add(result.word);
      _selected = {...?_selected, result.word};
    });
  }

  /// All composita to display: user-added first, then bundled, deduplicated.
  List<Composita> get _allComposita {
    final seen = <String>{};
    final result = <Composita>[];
    for (final c in _userComposita) {
      if (seen.add(c.word)) result.add(c);
    }
    for (final c in widget.composita) {
      if (seen.add(c.word)) result.add(c);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final l = AppLocalizations.of(context)!;
    final allComposita = _allComposita;
    final displayed = allComposita.length > _maxDisplayed
        ? allComposita.sublist(0, _maxDisplayed)
        : allComposita;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.compositaPickerTitle(widget.character),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          l.compositaPickerDescription,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 8),
        if (selected == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          // ── Draw composita button ──────────────────────────
          if (widget.recognizer != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openDrawComposita,
                  icon: const Icon(Icons.brush),
                  label: Text(l.compositaPickerDrawButton),
                ),
              ),
            ),
          // ── JMdict search ──────────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l.compositaPickerSearchHint,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _search,
                icon: const Icon(Icons.search),
              ),
            ],
          ),
          if (_searchError != null) ...[
            const SizedBox(height: 8),
            Text(
              _searchError!,
              style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
            ),
          ],
          if (_searchController.text.isNotEmpty &&
              _searchResults.isEmpty &&
              _searchError == null) ...[
            const SizedBox(height: 8),
            Text(
              l.compositaPickerNoResults,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
          for (final entry in _searchResults) ...[
            const SizedBox(height: 4),
            _buildSearchResult(entry, l),
          ],
          const Divider(),
          // ── Composita list (max 10) ─────────────────────────
          if (allComposita.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(l.compositaPickerEmpty),
            )
          else
            for (final c in displayed)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: selected.contains(c.word),
                onChanged: (v) => _toggle(c.word, v),
                title: Text(
                  '${c.word} (${c.reading})'
                  '${_userWords.contains(c.word) ? ' *' : ''}',
                ),
                subtitle: Text(c.meaning),
              ),
        ],
      ],
    );
  }

  Widget _buildSearchResult(WordEntry entry, AppLocalizations l) {
    final word = entry.kanji.firstWhere(
      (k) => k.contains(widget.character),
      orElse: () => entry.kanji.first,
    );
    final alreadyAdded = _userWords.contains(word) ||
        widget.composita.any((c) => c.word == word);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entry.kanji.join("、")} (${entry.kana.join("、")})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                entry.meaning,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        if (alreadyAdded)
          Chip(label: Text(l.compositaPickerAdded(word)))
        else
          TextButton(
            onPressed: () => _addFromSearch(entry),
            child: Text(l.compositaPickerAdd),
          ),
      ],
    );
  }
}

// ── Draw composita screen ──────────────────────────────────────────────

class _DrawnWordResult {
  final String word;
  final String reading;
  final String meaning;

  const _DrawnWordResult({
    required this.word,
    required this.reading,
    required this.meaning,
  });
}

/// Full-screen dialog for drawing characters to build a composita word.
/// The canvas stays outside the scrollable area to avoid gesture conflicts.
class _DrawCompositaScreen extends StatefulWidget {
  final String character;
  final KanjiRecognizer recognizer;
  final WordIndexRepository wordIndex;

  const _DrawCompositaScreen({
    required this.character,
    required this.recognizer,
    required this.wordIndex,
  });

  @override
  State<_DrawCompositaScreen> createState() => _DrawCompositaScreenState();
}

class _DrawCompositaScreenState extends State<_DrawCompositaScreen> {
  final _wordController = TextEditingController();
  int _drawKeyCounter = 0;
  List<WordEntry> _wordResults = const [];

  @override
  void initState() {
    super.initState();
    _wordController.addListener(_wordLookup);
  }

  @override
  void dispose() {
    _wordController.removeListener(_wordLookup);
    _wordController.dispose();
    super.dispose();
  }

  void _wordLookup() {
    setState(
      () => _wordResults = widget.wordIndex.lookup(_wordController.text),
    );
  }

  void _appendCharacter(String char) {
    setState(() => _drawKeyCounter++);
    _wordController.text += char;
  }

  void _clearWord() {
    _wordController.clear();
    setState(() => _drawKeyCounter++);
  }

  void _selectEntry(WordEntry entry) {
    final word = entry.kanji.firstWhere(
      (k) => k.contains(widget.character),
      orElse: () => entry.kanji.isNotEmpty ? entry.kanji.first : entry.kana.first,
    );
    Navigator.of(context).pop(_DrawnWordResult(
      word: word,
      reading: entry.kana.first,
      meaning: entry.meaning,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.compositaPickerDrawTitle(widget.character)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Flexible: instruction + canvas ──────────────────
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.wordLookupDrawInstruction,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: Listener(
                        onPointerDown: (_) => FocusScope.of(context).unfocus(),
                        behavior: HitTestBehavior.translucent,
                        child: Center(
                          child: DrawAndPickWidget(
                            key: ValueKey('draw-composita-$_drawKeyCounter'),
                            recognizer: widget.recognizer,
                            allowKana: true,
                            onPicked: (List<Prediction> _, String pick) =>
                                _appendCharacter(pick),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Scrollable: word field + results ──────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _wordController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 24),
                            decoration: InputDecoration(
                              labelText: l.wordLookupWordLabel,
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _wordController.text.isEmpty
                              ? null
                              : _clearWord,
                          icon: const Icon(Icons.clear),
                        ),
                      ],
                    ),
                    if (_wordController.text.isNotEmpty &&
                        _wordResults.isEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        l.wordLookupNoEntry,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    for (final entry in _wordResults) ...[
                      const SizedBox(height: 4),
                      _buildResult(entry, l),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(WordEntry entry, AppLocalizations l) {
    final primary = entry.kanji.isNotEmpty
        ? entry.kanji.join('、')
        : entry.kana.join('、');
    return Card(
      child: InkWell(
        onTap: () => _selectEntry(entry),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                primary,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (entry.kanji.isNotEmpty)
                Text(
                  entry.kana.join('、'),
                  style: const TextStyle(color: Colors.black54),
                ),
              const SizedBox(height: 4),
              Text(
                entry.meaning,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
