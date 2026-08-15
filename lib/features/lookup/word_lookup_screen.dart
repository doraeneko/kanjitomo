import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../../app_dependencies.dart';
import '../../core/kanji_recognizer.dart';
import '../../data/composita_repository.dart';
import '../../data/word_index_repository.dart';
import '../../l10n/app_localizations.dart';
import '../learning/add_remove_screen.dart';
import '../review/draw_and_pick.dart';
import '../review/review_repository.dart';
import '../review/sentence_selection.dart'
    show isKanji, compositaWithinCeiling, selectCompositaForIntroduction;
import '../../widgets/coffee_button.dart';

/// Draw kanji/kana one character at a time to build up a word, then look it
/// up in JMdict (via [WordIndexRepository], an exact-word index -- see
/// kanjirec/scripts/build_word_index.py). Reuses [DrawAndPickWidget] (the
/// same draw -> auto-recognize -> tap-a-candidate mechanic as the review
/// quiz and the kanji browser's custom-set editor): tapping a candidate
/// appends it to the word field instead of grading or adding to a set.
/// Lookup re-runs on every change to the word, whether from drawing or
/// directly editing the field.
class WordLookupScreen extends StatefulWidget {
  final AppDependencies deps;

  const WordLookupScreen({super.key, required this.deps});

  @override
  State<WordLookupScreen> createState() => _WordLookupScreenState();
}

class _WordLookupScreenState extends State<WordLookupScreen> {
  final _wordController = TextEditingController();
  // Bumped after each character add so DrawAndPickWidget remounts with a
  // blank canvas for the next character, instead of lingering on the
  // previous drawing/candidate pick -- same pattern as the kanji browser's
  // custom-set editor.
  int _drawKeyCounter = 0;
  List<WordEntry> _results = const [];
  late final ReviewRepository _reviewRepo;
  // Words already added to review in this session (for disabling buttons).
  final Set<String> _addedWords = {};

  @override
  void initState() {
    super.initState();
    _reviewRepo = ReviewRepository(widget.deps.database);
    _wordController.addListener(_lookup);
  }

  @override
  void dispose() {
    _wordController.removeListener(_lookup);
    _wordController.dispose();
    super.dispose();
  }

  void _lookup() {
    setState(() => _results = widget.deps.wordIndex.lookup(_wordController.text));
  }

  void _appendCharacter(String char) {
    setState(() => _drawKeyCounter++); // fresh canvas for the next character
    _wordController.text += char;
  }

  void _clearWord() {
    _wordController.clear();
  }

  Future<void> _copyToClipboard(String word) async {
    await Clipboard.setData(ClipboardData(text: word));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.wordLookupCopied(word)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Map<String, List<String>> _autoSelectComposita(List<String> chars) {
    final scope = widget.deps.studyScope.scope.value;
    final result = <String, List<String>>{};
    for (final char in chars) {
      final bundled = widget.deps.composita.lookup(char);
      final ceiling = scope.compositaCeiling;
      final charLevel = widget.deps.jlptLevels.levelOf(char);
      final eligible = bundled.where((c) {
        if (!c.word.runes.any((r) => isKanji(r))) return false;
        return compositaWithinCeiling(c, ceiling, charJlptLevel: charLevel);
      }).toList();
      if (eligible.isNotEmpty) {
        final selected = selectCompositaForIntroduction(
          char, eligible, scope.maxCompositaPerKanji,
        );
        final seen = <String>{};
        result[char] = [
          for (final c in selected)
            if (seen.add(c.word)) c.word,
        ];
      }
    }
    return result;
  }

  static bool _isKana(int codeUnit) {
    return (codeUnit >= 0x3040 && codeUnit <= 0x309F) ||
        (codeUnit >= 0x30A0 && codeUnit <= 0x30FF);
  }

  Future<void> _addToReview(WordEntry entry) async {
    final word = entry.kanji.isNotEmpty ? entry.kanji.first : entry.kana.first;
    final reading = entry.kana.first;
    final meaning = entry.meaning;

    // Extract kanji characters from the word (filter out kana), limited to
    // characters in the bundled kanji dictionary -- non-Jōyō kanji have no
    // kanjiStatic row, so introduceNewCards (which joins kanjiStatic) would
    // silently skip them, and they'd never appear in review.
    final knownKanji = widget.deps.kanjiInfo.characters.toSet();
    final kanjiChars = word.runes
        .map((r) => String.fromCharCode(r))
        .where((c) => c.length == 1 && !_isKana(c.codeUnitAt(0)))
        .where((c) => knownKanji.contains(c))
        .toList();

    if (kanjiChars.isEmpty) return; // kana-only word, nothing to add

    // Single kanji: add directly. Multiple: let the user pick which ones.
    final Set<String> selectedChars;
    if (kanjiChars.length == 1) {
      selectedChars = {kanjiChars.first};
    } else {
      final picked = await _showKanjiPickerDialog(word, kanjiChars);
      if (picked == null || picked.isEmpty) return; // cancelled
      selectedChars = picked;
    }

    final scope = widget.deps.studyScope.scope.value;
    final newChars = <String>[];

    for (final char in selectedChars) {
      await _reviewRepo.addUserComposita(char, word, reading, meaning);

      // If char not in pool, add it + introduce review cards.
      if (!scope.characters.contains(char)) {
        newChars.add(char);
      }
    }

    if (newChars.isNotEmpty) {
      // Auto-select composita for newly added kanji (same logic as
      // learning_screen's quick-add).
      final compositaByChar = _autoSelectComposita(newChars);
      // Ensure the user's explicitly chosen word is included for each
      // new kanji — it may not be in the bundled composita list.
      for (final char in newChars) {
        final list = compositaByChar.putIfAbsent(char, () => []);
        if (!list.contains(word)) list.insert(0, word);
      }
      for (final entry in compositaByChar.entries) {
        for (final w in entry.value) {
          await _reviewRepo.addCustomComposita(entry.key, w);
        }
      }
      await _reviewRepo.introduceCardsForCharacters(
        newChars.toSet(),
        compositaWordsByChar: compositaByChar,
      );
      await widget.deps.studyScope.addCharacters(newChars.toSet());

      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => IntroSlideshowScreen(
              deps: widget.deps,
              characters: newChars,
              compositaByChar: compositaByChar,
            ),
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() => _addedWords.add(word));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.wordLookupAddedToReview(word),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Dialog with checkboxes for each kanji in the word, all checked by
  /// default. Returns the selected set, or null if cancelled.
  Future<Set<String>?> _showKanjiPickerDialog(
    String word,
    List<String> kanjiChars,
  ) async {
    final l = AppLocalizations.of(context)!;
    final selected = Set<String>.from(kanjiChars); // all checked initially
    return showDialog<Set<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l.wordLookupPickKanjiTitle(word)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: kanjiChars.map((char) {
              return CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: selected.contains(char),
                onChanged: (v) {
                  setDialogState(() {
                    if (v == true) {
                      selected.add(char);
                    } else {
                      selected.remove(char);
                    }
                  });
                },
                title: Text(
                  char,
                  style: const TextStyle(fontSize: 28),
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(l.dialogCancel),
            ),
            TextButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.of(ctx).pop(Set<String>.from(selected)),
              child: Text(l.wordLookupPickKanjiConfirm),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.wordLookupTitle),
        actions: const [CoffeeButton()],
      ),
      // The canvas is deliberately kept OUT of any SingleChildScrollView --
      // a scrollable ancestor's own drag recognizer competes with the
      // canvas's raw pointer Listener for any vertical stroke and can win,
      // which reads as "the screen scrolls while I'm drawing" (see
      // drawing_canvas.dart's own doc comment on the same underlying
      // gesture-arena issue). Only the word field + results below it, which
      // can grow arbitrarily long, scroll.
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Hide the drawing area when vertical space is tight (keyboard
            // open). The canvas + text + padding needs ~360px; if less is
            // available the canvas would overflow.
            final showCanvas = constraints.maxHeight > 500;
            return Column(
              children: [
                if (showCanvas)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    children: [
                      Text(
                        l.wordLookupDrawInstruction,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      // Drawing (and picking a candidate, or hitting Clear)
                      // should always dismiss the word field's keyboard first --
                      // otherwise the field can stay focused while the user
                      // returns to drawing, and the still-open keyboard fighting
                      // the layout for space causes odd resizing.
                      Listener(
                        onPointerDown: (_) => FocusScope.of(context).unfocus(),
                        behavior: HitTestBehavior.translucent,
                        child: Center(
                          child: DrawAndPickWidget(
                            key: ValueKey(_drawKeyCounter),
                            recognizer: widget.deps.recognizer,
                            allowKana: true,
                            onPicked:
                                (List<Prediction> topCandidates, String pick) =>
                                    _appendCharacter(pick),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _wordController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 28),
                            decoration: InputDecoration(
                              labelText: l.wordLookupWordLabel,
                              border: const OutlineInputBorder(),
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
                    const SizedBox(height: 24),
                    if (_wordController.text.isNotEmpty && _results.isEmpty)
                      Text(
                        l.wordLookupNoEntry,
                        textAlign: TextAlign.center,
                      ),
                    ..._results.map((entry) {
                      final primary = entry.kanji.isNotEmpty
                          ? entry.kanji.join('、')
                          : entry.kana.join('、');
                      final wordKey = entry.kanji.isNotEmpty
                          ? entry.kanji.first
                          : entry.kana.first;
                      final alreadyAdded = _addedWords.contains(wordKey);
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      primary,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy),
                                    tooltip: l.copyToClipboard,
                                    onPressed: () =>
                                        _copyToClipboard(primary),
                                  ),
                                ],
                              ),
                              if (entry.kanji.isNotEmpty)
                                Text(
                                  entry.kana.join('、'),
                                  style: const TextStyle(
                                    color: Colors.black54,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(entry.meaning),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: alreadyAdded
                                    ? null
                                    : () => _addToReview(entry),
                                icon: Icon(
                                  alreadyAdded
                                      ? Icons.check
                                      : Icons.add,
                                ),
                                label: Text(
                                  alreadyAdded
                                      ? l.wordLookupAddedToReview(wordKey)
                                      : l.wordLookupAddToReview,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
              ],
            );
          },
        ),
      ),
    );
  }
}
