import 'package:flutter/material.dart';

import '../../data/composita_repository.dart';
import '../../data/word_index_repository.dart';
import '../../l10n/app_localizations.dart';
import '../review/review_repository.dart';

/// Checklist of one kanji's composita words, letting the user pick which
/// ones are eligible for C+D (composita/sentence) testing in the custom
/// scope -- toggles [ReviewRepository.addCustomComposita]/
/// [removeCustomComposita] immediately (optimistic UI, no separate "save"
/// step) rather than batching changes for an explicit confirm.
///
/// Also includes a JMdict search field so users can find and add words
/// not in the bundled composita.json -- added words are stored as
/// [UserComposita] and immediately appear in the checkbox list.
class CompositaPicker extends StatefulWidget {
  final String character;
  final List<Composita> composita;
  final ReviewRepository reviewRepo;
  final WordIndexRepository wordIndex;

  const CompositaPicker({
    super.key,
    required this.character,
    required this.composita,
    required this.reviewRepo,
    required this.wordIndex,
  });

  @override
  State<CompositaPicker> createState() => _CompositaPickerState();
}

class _CompositaPickerState extends State<CompositaPicker> {
  Set<String>? _selected; // null while loading
  // User-added composita for this character, merged into the checkbox list.
  List<Composita> _userComposita = [];
  // Words already known to be user-added (for showing "Added" vs "Add").
  Set<String> _userWords = {};

  // JMdict search state.
  final _searchController = TextEditingController();
  List<WordEntry> _searchResults = const [];
  String? _searchError; // non-null when the query doesn't match this char

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

  void _toggle(String word, bool? value) {
    setState(() => _selected = {...?_selected});
    if (value == true) {
      _selected!.add(word);
      widget.reviewRepo.addCustomComposita(widget.character, word);
    } else {
      _selected!.remove(word);
      widget.reviewRepo.removeCustomComposita(widget.character, word);
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

  /// All composita to display: bundled + user-added, deduplicated by word.
  List<Composita> get _allComposita {
    final seen = <String>{};
    final result = <Composita>[];
    for (final c in widget.composita) {
      if (seen.add(c.word)) result.add(c);
    }
    for (final c in _userComposita) {
      if (seen.add(c.word)) result.add(c);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final l = AppLocalizations.of(context)!;
    final allComposita = _allComposita;
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
          if (allComposita.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(l.compositaPickerEmpty),
            )
          else
            for (final c in allComposita)
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
          const Divider(),
          const SizedBox(height: 8),
          // JMdict search field
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
