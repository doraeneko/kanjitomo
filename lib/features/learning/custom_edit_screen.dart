import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, LengthLimitingTextInputFormatter;
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_dependencies.dart';
import '../../core/kanji_recognizer.dart';
import '../../data/composita_repository.dart';
import '../../data/word_index_repository.dart';
import '../../l10n/app_localizations.dart';
import '../kanji_browser/kanji_detail_content.dart';
import '../pro/pro_paywall_sheet.dart';
import '../review/draw_and_pick.dart';
import '../review/review_repository.dart';
import '../review/study_scope.dart';
import 'composita_picker.dart';

enum _AddMode { byKanji, byWord }

/// Edits the custom-mode [StudyScope]'s kanji set: draw a kanji to add it
/// (same draw -> top-3 -> pick mechanic as the review quiz's draw-based
/// cards, [DrawAndPickWidget], reused here for "add" instead of "grade
/// against a target" -- whichever candidate is tapped is what gets added),
/// tap an existing entry to remove it, long-press to pick which of its
/// composita words are tested (C+D) -- custom mode has no JLPT-style
/// ceiling, so composita/sentence testing stays off for a kanji until the
/// user explicitly opts words in here (see CustomComposita). Also offers
/// clearing the whole set. Assumes the caller (LearningScreen) has already
/// put the scope into custom mode.
///
/// A segmented toggle at the top switches between "By kanji" (the existing
/// draw-single-kanji flow) and "By word" (the word lookup flow, which
/// draws characters to build a word, looks it up in JMdict, and adds the
/// word as composita for the kanji it contains).
class CustomEditScreen extends StatefulWidget {
  final AppDependencies deps;

  const CustomEditScreen({super.key, required this.deps});

  @override
  State<CustomEditScreen> createState() => _CustomEditScreenState();
}

class _CustomEditScreenState extends State<CustomEditScreen> {
  static const _dailyNewCapKey = 'review.daily_new_cap';
  static const _defaultDailyNewCap = 10;
  static const _minDailyNewCap = 1;
  static const _maxDailyNewCap = 999;
  static const _freeCustomLimit = 50;

  bool get _isPro => widget.deps.proStatus.isProUnlocked.value;

  late final ReviewRepository _reviewRepo;
  late final TextEditingController _dailyNewCapController;
  // Bumped after each successful add so DrawAndPickWidget remounts with a
  // blank canvas for the next kanji, instead of lingering on the previous
  // drawing/top-3 pick.
  int _drawKeyCounter = 0;
  // character -> its selected custom composita words, for the small badge
  // on each cell -- refreshed after every add/remove and after the
  // composita picker sheet closes.
  Map<String, Set<String>> _customComposita = {};
  _AddMode _addMode = _AddMode.byKanji;

  // ── "By word" state ──────────────────────────────────────────────────
  final _wordController = TextEditingController();
  int _wordDrawKeyCounter = 0;
  List<WordEntry> _wordResults = const [];
  final Set<String> _addedWords = {};

  @override
  void initState() {
    super.initState();
    _reviewRepo = ReviewRepository(widget.deps.database);
    _dailyNewCapController = TextEditingController(text: '$_defaultDailyNewCap');
    _loadDailyNewCap();
    _loadCustomComposita(widget.deps.studyScope.scope.value);
    _wordController.addListener(_wordLookup);
  }

  @override
  void dispose() {
    _dailyNewCapController.dispose();
    _wordController.removeListener(_wordLookup);
    _wordController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyNewCap() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_dailyNewCapKey);
    if (stored != null && mounted) {
      _dailyNewCapController.text = '$stored';
    }
  }

  void _onDailyNewCapChanged(String text) async {
    final parsed = int.tryParse(text);
    if (parsed == null || parsed < _minDailyNewCap || parsed > _maxDailyNewCap) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyNewCapKey, parsed);
  }

  Future<void> _loadCustomComposita(StudyScope scope) async {
    final loaded = await _reviewRepo.customCompositaForCharacters(
      scope.customCharacters,
    );
    if (mounted) setState(() => _customComposita = loaded);
  }

  Future<void> _confirmRemoveCharacter(StudyScope scope, String char) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.customEditRemoveDialogTitle(char)),
        content: Text(l.customEditRemoveDialogContent(char)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.dialogCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.dialogRemove),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final chars = Set<String>.from(scope.customCharacters)..remove(char);
      widget.deps.studyScope.update(scope.copyWith(customCharacters: chars));
    }
  }

  static bool _isKana(String char) {
    if (char.isEmpty) return false;
    final c = char.codeUnitAt(0);
    return (c >= 0x3040 && c <= 0x309F) || (c >= 0x30A0 && c <= 0x30FF);
  }

  static bool _isKanaCodeUnit(int codeUnit) {
    return (codeUnit >= 0x3040 && codeUnit <= 0x309F) ||
        (codeUnit >= 0x30A0 && codeUnit <= 0x30FF);
  }

  void _addDrawnCharacter(StudyScope scope, String char) {
    setState(() => _drawKeyCounter++); // fresh canvas for the next kanji
    final l = AppLocalizations.of(context)!;
    if (_isKana(char)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.customEditIsKana(char))),
      );
      return;
    }
    if (scope.customCharacters.contains(char)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.customEditAlreadyInSet(char))),
      );
      return;
    }
    if (!_isPro && scope.customCharacters.length >= _freeCustomLimit) {
      showProPaywallSheet(context, widget.deps.purchaseService);
      return;
    }
    final chars = Set<String>.from(scope.customCharacters)..add(char);
    widget.deps.studyScope.update(scope.copyWith(customCharacters: chars));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.customEditAdded(char))));
    _openKanjiDialog(scope, char);
  }

  Future<void> _confirmClear(StudyScope scope) async {
    final count = scope.customCharacters.length;
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.customEditClearDialogTitle),
        content: Text(l.customEditClearDialogContent(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.dialogCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.dialogClear),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      widget.deps.studyScope.update(scope.copyWith(customCharacters: {}));
    }
  }

  Future<void> _openKanjiDialog(StudyScope scope, String char) async {
    final all = rankComposita(widget.deps.composita.lookup(char));
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CompositaPicker(
                    character: char,
                    composita: all,
                    reviewRepo: _reviewRepo,
                    wordIndex: widget.deps.wordIndex,
                  ),
                  const Divider(height: 32),
                  KanjiDetailContent(
                    character: char,
                    deps: widget.deps,
                    scrollable: false,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    _loadCustomComposita(scope); // refresh badge counts once the sheet closes
  }

  // ── "By word" methods ────────────────────────────────────────────────

  void _wordLookup() {
    setState(
      () => _wordResults = widget.deps.wordIndex.lookup(_wordController.text),
    );
  }

  void _wordAppendCharacter(String char) {
    setState(() => _wordDrawKeyCounter++);
    _wordController.text += char;
  }

  void _wordClear() {
    _wordController.clear();
  }

  Future<void> _addWordToReview(WordEntry entry) async {
    final word = entry.kanji.isNotEmpty ? entry.kanji.first : entry.kana.first;
    final reading = entry.kana.first;
    final meaning = entry.meaning;

    final knownKanji = widget.deps.kanjiInfo.characters.toSet();
    final kanjiChars = word.runes
        .map((r) => String.fromCharCode(r))
        .where((c) => c.length == 1 && !_isKanaCodeUnit(c.codeUnitAt(0)))
        .where((c) => knownKanji.contains(c))
        .toList();

    if (kanjiChars.isEmpty) return;

    final Set<String> selectedChars;
    if (kanjiChars.length == 1) {
      selectedChars = {kanjiChars.first};
    } else {
      final picked = await _showKanjiPickerDialog(word, kanjiChars);
      if (picked == null || picked.isEmpty) return;
      selectedChars = picked;
    }

    for (final char in selectedChars) {
      final scope = widget.deps.studyScope.scope.value;
      if (!scope.customCharacters.contains(char) &&
          !_isPro &&
          scope.customCharacters.length >= _freeCustomLimit) {
        if (mounted) showProPaywallSheet(context, widget.deps.purchaseService);
        return;
      }

      await _reviewRepo.addUserComposita(char, word, reading, meaning);

      final currentScope = widget.deps.studyScope.scope.value;
      if (!currentScope.customCharacters.contains(char)) {
        final newChars = {...currentScope.customCharacters, char};
        await widget.deps.studyScope.update(
          currentScope.copyWith(customCharacters: newChars),
        );
      }
    }

    if (!mounted) return;
    setState(() => _addedWords.add(word));
    _loadCustomComposita(widget.deps.studyScope.scope.value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.wordLookupAddedToReview(word),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<Set<String>?> _showKanjiPickerDialog(
    String word,
    List<String> kanjiChars,
  ) async {
    final l = AppLocalizations.of(context)!;
    final selected = Set<String>.from(kanjiChars);
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
                title: Text(char, style: const TextStyle(fontSize: 28)),
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

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.customEditTitle),
        actions: [
          ValueListenableBuilder<StudyScope>(
            valueListenable: widget.deps.studyScope.scope,
            builder: (context, scope, _) => TextButton(
              onPressed: scope.customCharacters.isEmpty
                  ? null
                  : () => _confirmClear(scope),
              child: Text(l.customEditClear),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<StudyScope>(
          valueListenable: widget.deps.studyScope.scope,
          builder: (context, scope, _) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── Mode toggle ──────────────────────────────────
                  SegmentedButton<_AddMode>(
                    segments: [
                      ButtonSegment(
                        value: _AddMode.byKanji,
                        label: Text(l.customEditAddByKanji),
                        icon: const Icon(Icons.brush),
                      ),
                      ButtonSegment(
                        value: _AddMode.byWord,
                        label: Text(l.customEditAddByWord),
                        icon: const Icon(Icons.search),
                      ),
                    ],
                    selected: {_addMode},
                    onSelectionChanged: (v) => setState(() => _addMode = v.first),
                  ),
                  const SizedBox(height: 12),
                  // ── Mode-specific content ────────────────────────
                  if (_addMode == _AddMode.byKanji) ...[
                    _buildByKanjiContent(scope, l),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(l.reviewStartNewKanjiPerDay),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: _dailyNewCapController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[1-9][0-9]*'),
                              ),
                              LengthLimitingTextInputFormatter(3),
                            ],
                            onChanged: _onDailyNewCapChanged,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_addMode == _AddMode.byWord)
                    ..._buildByWordContent(l),
                  // ── Shared: kanji set grid ───────────────────────
                  const SizedBox(height: 8),
                  const Divider(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      scope.customCharacters.isEmpty
                          ? l.customEditSetEmpty
                          : l.customEditSetInstruction,
                    ),
                  ),
                  if (scope.customCharacters.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _isPro
                            ? l.customEditKanjiCountPro(scope.customCharacters.length)
                            : l.customEditKanjiCount(scope.customCharacters.length, _freeCustomLimit),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: scope.customCharacters.map((char) {
                          final compositaCount =
                              _customComposita[char]?.length ?? 0;
                          return InkWell(
                            key: ValueKey('remove-$char'),
                            onTap: () => _openKanjiDialog(scope, char),
                            onLongPress: () =>
                                _confirmRemoveCharacter(scope, char),
                            child: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    char,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  if (compositaCount > 0)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.indigo,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '$compositaCount',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildByKanjiContent(StudyScope scope, AppLocalizations l) {
    return Column(
      children: [
        Text(l.customEditDrawInstruction, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        DrawAndPickWidget(
          key: ValueKey(_drawKeyCounter),
          recognizer: widget.deps.recognizer,
          onPicked: (List<Prediction> top3, String pick) =>
              _addDrawnCharacter(scope, pick),
        ),
      ],
    );
  }

  List<Widget> _buildByWordContent(AppLocalizations l) {
    return [
      Text(l.wordLookupDrawInstruction, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Listener(
        onPointerDown: (_) => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Center(
          child: DrawAndPickWidget(
            key: ValueKey('word-$_wordDrawKeyCounter'),
            recognizer: widget.deps.recognizer,
            onPicked: (List<Prediction> topCandidates, String pick) =>
                _wordAppendCharacter(pick),
          ),
        ),
      ),
      const SizedBox(height: 8),
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
            onPressed: _wordController.text.isEmpty ? null : _wordClear,
            icon: const Icon(Icons.clear),
          ),
        ],
      ),
      if (_wordController.text.isNotEmpty && _wordResults.isEmpty) ...[
        const SizedBox(height: 8),
        Text(l.wordLookupNoEntry, textAlign: TextAlign.center),
      ],
      for (final entry in _wordResults)
        _buildWordResult(entry, l),
    ];
  }

  Widget _buildWordResult(WordEntry entry, AppLocalizations l) {
    final primary = entry.kanji.isNotEmpty
        ? entry.kanji.join('、')
        : entry.kana.join('、');
    final wordKey =
        entry.kanji.isNotEmpty ? entry.kanji.first : entry.kana.first;
    final alreadyAdded = _addedWords.contains(wordKey);
    return Card(
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
            Text(entry.meaning, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: alreadyAdded ? null : () => _addWordToReview(entry),
              icon: Icon(alreadyAdded ? Icons.check : Icons.add),
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
  }
}
