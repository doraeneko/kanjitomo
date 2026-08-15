import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, LengthLimitingTextInputFormatter;
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_dependencies.dart';
import '../../core/kanji_recognizer.dart';
import '../../data/composita_repository.dart';
import '../../l10n/app_localizations.dart';
import '../kanji_browser/kanji_detail_content.dart';
import '../kanji_browser/kanji_search.dart';
import '../review/draw_and_pick.dart';
import '../review/review_repository.dart';
import '../review/sentence_selection.dart';
import '../review/study_scope.dart';
import 'composita_picker.dart';

enum _PoolSort { rtk, added, modified }

/// Unified screen for adding kanji to (and removing them from) the learning
/// pool. Four tabs via bottom navigation:
/// 1. Add by JLPT level
/// 2. Add by RTK order
/// 3. Add by drawing
/// 4. Learning pool (view/edit/remove)
///
/// Composita settings (ceiling, max per kanji) live at the top of the JLPT
/// and RTK tabs since they affect the auto-selection algorithm.
class AddRemoveScreen extends StatefulWidget {
  final AppDependencies deps;

  const AddRemoveScreen({super.key, required this.deps});

  @override
  State<AddRemoveScreen> createState() => _AddRemoveScreenState();
}

class _AddRemoveScreenState extends State<AddRemoveScreen> {
  static const _jlptLevelKey = 'add_remove.jlpt_level';
  static const _tabIndexKey = 'add_remove.tab_index';
  static const _countKey = 'add_remove.count';

  late final ReviewRepository _reviewRepo;
  final _countController = TextEditingController(text: '5');
  final _poolSearchController = TextEditingController();
  int _selectedJlptLevel = 5;
  int _tabIndex = 0;
  String _poolQuery = '';
  _PoolSort _poolSort = _PoolSort.rtk;
  // Composita counts for pool kanji (character -> word count).
  Map<String, int> _compositaCounts = {};
  Map<String, DateTime> _addedDates = {};
  Map<String, DateTime> _modifiedDates = {};

  @override
  void initState() {
    super.initState();
    _reviewRepo = ReviewRepository(widget.deps.database);
    _loadCompositaCounts();
    _loadDates();
    _loadSavedPrefs();
    _poolSearchController.addListener(() {
      setState(() => _poolQuery = _poolSearchController.text.trim());
    });
    widget.deps.studyScope.scope.addListener(_onScopeChanged);
  }

  Future<void> _loadSavedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getInt(_jlptLevelKey);
    final tab = prefs.getInt(_tabIndexKey);
    final count = prefs.getInt(_countKey);
    if (mounted) {
      setState(() {
        if (level != null) _selectedJlptLevel = level;
        if (tab != null && tab >= 0 && tab < 4) _tabIndex = tab;
        if (count != null && count > 0) _countController.text = count.toString();
      });
    }
  }

  @override
  void dispose() {
    widget.deps.studyScope.scope.removeListener(_onScopeChanged);
    _countController.dispose();
    _poolSearchController.dispose();
    super.dispose();
  }

  void _onScopeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadDates() async {
    final added = await _reviewRepo.addedDates();
    final modified = await _reviewRepo.modifiedDates();
    if (mounted) {
      setState(() {
        _addedDates = added;
        _modifiedDates = modified;
      });
    }
  }

  Future<void> _loadCompositaCounts() async {
    final scope = widget.deps.studyScope.scope.value;
    final counts = <String, int>{};
    for (final char in scope.characters) {
      final selected = await _reviewRepo.customCompositaFor(char);
      counts[char] = selected.length;
    }
    if (mounted) setState(() => _compositaCounts = counts);
  }

  StudyScope get _scope => widget.deps.studyScope.scope.value;

  /// Returns the next N kanji in RTK order from [candidates] that aren't
  /// already in the pool.
  List<String> _nextKanjiInRtkOrder(List<String> candidates, int count) {
    final pool = _scope.characters;
    final sorted = candidates.where((c) => !pool.contains(c)).toList();
    sorted.sort((a, b) {
      final ai = widget.deps.rtkIndex.indexOf(a) ?? 99999;
      final bi = widget.deps.rtkIndex.indexOf(b) ?? 99999;
      return ai.compareTo(bi);
    });
    return sorted.take(count).toList();
  }

  /// Auto-selects composita for [chars] using the scope's ceiling + max per
  /// kanji settings.
  Map<String, List<String>> _autoSelectComposita(List<String> chars) {
    final scope = _scope;
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
          char,
          eligible,
          scope.maxCompositaPerKanji,
        );
        // Deduplicate by word — the DB key is (character, word), so two
        // entries with the same word but different readings collapse into one.
        final seen = <String>{};
        result[char] = [
          for (final c in selected)
            if (seen.add(c.word)) c.word,
        ];
      }
    }
    return result;
  }

  Future<void> _addByJlpt() async {
    final count = int.tryParse(_countController.text) ?? 5;
    if (count <= 0) return;
    SharedPreferences.getInstance().then((p) => p.setInt(_countKey, count));

    final allInLevel = widget.deps.jlptLevels.charsInLevels({_selectedJlptLevel});
    final toAdd = _nextKanjiInRtkOrder(allInLevel, count);
    if (toAdd.isEmpty) return;

    await _addKanjiToPool(toAdd);
  }

  Future<void> _addByRtk() async {
    final count = int.tryParse(_countController.text) ?? 5;
    if (count <= 0) return;
    SharedPreferences.getInstance().then((p) => p.setInt(_countKey, count));

    final allKanji = widget.deps.kanjiInfo.characters;
    final toAdd = _nextKanjiInRtkOrder(allKanji, count);
    if (toAdd.isEmpty) return;

    await _addKanjiToPool(toAdd);
  }

  Future<void> _addKanjiToPool(List<String> chars) async {
    final compositaByChar = _autoSelectComposita(chars);

    for (final entry in compositaByChar.entries) {
      for (final word in entry.value) {
        await _reviewRepo.addCustomComposita(entry.key, word);
      }
    }

    await _reviewRepo.introduceCardsForCharacters(
      chars.toSet(),
      compositaWordsByChar: compositaByChar,
    );

    await widget.deps.studyScope.addCharacters(chars.toSet());
    await _loadCompositaCounts();
    await _loadDates();

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IntroSlideshowScreen(
          deps: widget.deps,
          characters: chars,
          compositaByChar: compositaByChar,
        ),
      ),
    );
  }

  Future<void> _addByDraw(List<Prediction> _, String picked) async {
    if (_scope.characters.contains(picked)) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.addRemoveAlreadyInPool(picked)),
            duration: const Duration(seconds: 2),
          ),
        );
        _openCompositaPicker(picked);
      }
      return;
    }

    final compositaByChar = _autoSelectComposita([picked]);
    for (final word in compositaByChar[picked] ?? []) {
      await _reviewRepo.addCustomComposita(picked, word);
    }
    await _reviewRepo.introduceCardsForCharacters(
      {picked},
      compositaWordsByChar: compositaByChar,
    );
    await widget.deps.studyScope.addCharacters({picked});
    await _loadCompositaCounts();
    await _loadDates();

    if (mounted) _openCompositaPicker(picked);
  }

  Future<void> _removeCharacter(String char) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.addRemoveConfirmRemoveTitle),
        content: Text(l.addRemoveConfirmRemoveContent(char)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.dialogCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.addRemoveRemoveButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _reviewRepo.deleteProgressForCharacters({char});
    await widget.deps.studyScope.removeCharacters({char});
    _compositaCounts.remove(char);
    _addedDates.remove(char);
    _modifiedDates.remove(char);
    if (mounted) setState(() {});
  }

  Future<void> _clearAll() async {
    final l = AppLocalizations.of(context)!;
    final pool = _scope.characters;
    if (pool.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.addRemoveConfirmClearTitle),
        content: Text(l.addRemoveConfirmClearContent(pool.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.dialogCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.addRemoveRemoveButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _reviewRepo.deleteProgressForCharacters(pool);
    await widget.deps.studyScope.removeCharacters(pool);
    _compositaCounts.clear();
    _addedDates.clear();
    _modifiedDates.clear();
    if (mounted) setState(() {});
  }

  void _openCompositaPicker(String char) {
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
                character: char,
                composita: widget.deps.composita.lookup(char),
                reviewRepo: _reviewRepo,
                wordIndex: widget.deps.wordIndex,
                recognizer: widget.deps.recognizer,
              ),
            );
          },
        );
      },
    ).then((_) => _loadCompositaCounts());
  }

  void _updateCompositaCeiling(int? ceiling) {
    widget.deps.studyScope.update(
      _scope.copyWith(
        compositaCeiling: ceiling,
        clearCompositaCeiling: ceiling == null,
      ),
    );
    setState(() {});
  }

  void _updateMaxComposita(int max) {
    widget.deps.studyScope.update(
      _scope.copyWith(maxCompositaPerKanji: max),
    );
    setState(() {});
  }

  // ── Composita settings widget (shared by JLPT and RTK tabs) ──────────

  Widget _buildCompositaSettings(AppLocalizations l) {
    final scope = _scope;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.addRemoveCompositaSettings,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(l.addRemoveCompositaCeiling,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(l.addRemoveCompositaCeilingHelp,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(l.addRemoveCeilingOff),
              selected: scope.compositaCeiling == null,
              onSelected: (_) => _updateCompositaCeiling(null),
            ),
            for (final level in [5, 4, 3, 2])
              ChoiceChip(
                label: Text('N$level'),
                selected: scope.compositaCeiling == level,
                onSelected: (_) => _updateCompositaCeiling(level),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(l.addRemoveMaxComposita,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(l.addRemoveMaxCompositaHelp,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            for (final n in [2, 3, 4, 5])
              ChoiceChip(
                label: Text('$n'),
                selected: scope.maxCompositaPerKanji == n,
                onSelected: (_) => _updateMaxComposita(n),
              ),
          ],
        ),
      ],
    );
  }

  // ── Tab bodies ────────────────────────────────────────────────────────

  Widget _buildTip(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l.addRemoveAddTip,
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelp(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
      ),
    );
  }

  Widget _buildJlptTab(AppLocalizations l) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHelp(l.addRemoveJlptHelp),
        _buildTip(l),
        Wrap(
          spacing: 8,
          children: [
            for (final level in [5, 4, 3, 2, 1])
              ChoiceChip(
                label: Text('N$level'),
                selected: _selectedJlptLevel == level,
                onSelected: (_) {
                  setState(() => _selectedJlptLevel = level);
                  SharedPreferences.getInstance().then((p) => p.setInt(_jlptLevelKey, level));
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(l.addRemoveKanjiCount),
        const SizedBox(height: 4),
        Row(
          children: [
            SizedBox(
              width: 60,
              child: TextField(
                controller: _countController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _addByJlpt,
              child: Text(l.addRemoveAddJlptButton),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),
        _buildCompositaSettings(l),
      ],
    );
  }

  Widget _buildRtkTab(AppLocalizations l) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHelp(l.addRemoveRtkHelp),
        _buildTip(l),
        Text(l.addRemoveKanjiCount),
        const SizedBox(height: 4),
        Row(
          children: [
            SizedBox(
              width: 60,
              child: TextField(
                controller: _countController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _addByRtk,
              child: Text(l.addRemoveAddRtkButton),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),
        _buildCompositaSettings(l),
      ],
    );
  }

  Widget _buildDrawTab(AppLocalizations l) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHelp(l.addRemoveDrawHelp),
        Center(
          child: DrawAndPickWidget(
            key: const ValueKey('add-draw'),
            recognizer: widget.deps.recognizer,
            onPicked: _addByDraw,
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),
        _buildCompositaSettings(l),
      ],
    );
  }

  Widget _buildPoolTab(AppLocalizations l) {
    final allPool = _scope.characters.toList();
    switch (_poolSort) {
      case _PoolSort.rtk:
        allPool.sort((a, b) {
          final ai = widget.deps.rtkIndex.indexOf(a) ?? 99999;
          final bi = widget.deps.rtkIndex.indexOf(b) ?? 99999;
          return ai.compareTo(bi);
        });
      case _PoolSort.added:
        allPool.sort((a, b) {
          final da = _addedDates[a];
          final db = _addedDates[b];
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return db.compareTo(da); // newest first
        });
      case _PoolSort.modified:
        allPool.sort((a, b) {
          final da = _modifiedDates[a];
          final db = _modifiedDates[b];
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return db.compareTo(da); // newest first
        });
    }

    final pool = _poolQuery.isEmpty
        ? allPool
        : allPool.where((char) {
            return matchesKanjiSearch(
              character: char,
              info: widget.deps.kanjiInfo.lookup(char),
              strokeCount: widget.deps.strokePaths.lookup(char)?.strokeCount,
              query: _poolQuery,
            );
          }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l.addRemovePoolTip,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _poolSearchController,
                  decoration: InputDecoration(
                    labelText: l.addRemovePoolSearch,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: _poolQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _poolSearchController.clear,
                          ),
                  ),
                ),
              ),
              if (allPool.isNotEmpty) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _clearAll,
                  child: Text(l.addRemoveClearAll),
                ),
              ],
            ],
          ),
        ),
        if (allPool.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l.addRemovePoolSortRtk),
                  selected: _poolSort == _PoolSort.rtk,
                  onSelected: (_) => setState(() => _poolSort = _PoolSort.rtk),
                ),
                ChoiceChip(
                  label: Text(l.addRemovePoolSortAdded),
                  selected: _poolSort == _PoolSort.added,
                  onSelected: (_) => setState(() => _poolSort = _PoolSort.added),
                ),
                ChoiceChip(
                  label: Text(l.addRemovePoolSortModified),
                  selected: _poolSort == _PoolSort.modified,
                  onSelected: (_) => setState(() => _poolSort = _PoolSort.modified),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: allPool.isEmpty
              ? Center(
                  child: Text(
                    l.addRemovePoolEmpty,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: pool.map((char) {
                        final count = _compositaCounts[char] ?? 0;
                        return GestureDetector(
                          onTap: () => _openCompositaPicker(char),
                          onLongPress: () => _removeCharacter(char),
                          child: Chip(
                            label: Text(
                              char,
                              style: const TextStyle(fontSize: 20),
                            ),
                            deleteIcon: count > 0
                                ? CircleAvatar(
                                    radius: 10,
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  )
                                : null,
                            onDeleted: count > 0
                                ? () => _openCompositaPicker(char)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final bodies = [
      _buildJlptTab(l),
      _buildRtkTab(l),
      _buildDrawTab(l),
      _buildPoolTab(l),
    ];

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      appBar: AppBar(title: Text(l.addRemoveTitle)),
      body: SafeArea(child: bodies[_tabIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) {
          setState(() => _tabIndex = i);
          SharedPreferences.getInstance().then((p) => p.setInt(_tabIndexKey, i));
        },
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'JLPT',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.format_list_numbered),
            label: 'RTK',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.draw),
            label: l.addRemoveDrawToAdd,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.view_comfy),
            label: l.addRemovePoolTitle(_scope.characters.length),
          ),
        ],
      ),
    ),
    );
  }
}

// ── Introduction slideshow ───────────────────────────────────────────────

/// Full-screen slideshow introducing newly-added kanji. Shows each kanji's
/// detail (readings, meaning, keyword, story, stroke order) plus only the
/// composita words that were auto-selected for it.
class IntroSlideshowScreen extends StatefulWidget {
  final AppDependencies deps;
  final List<String> characters;
  final Map<String, List<String>> compositaByChar;

  const IntroSlideshowScreen({
    super.key,
    required this.deps,
    required this.characters,
    required this.compositaByChar,
  });

  @override
  State<IntroSlideshowScreen> createState() => IntroSlideshowScreenState();
}

class IntroSlideshowScreenState extends State<IntroSlideshowScreen> {
  int _index = 0;

  String get _char => widget.characters[_index];
  bool get _isLast => _index == widget.characters.length - 1;

  void _next() {
    if (_isLast) {
      Navigator.of(context).pop();
    } else {
      setState(() => _index++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final words = widget.compositaByChar[_char] ?? [];
    return Scaffold(
      appBar: AppBar(
        title: Text(l.addRemoveSlideshowTitle(_index + 1, widget.characters.length)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KanjiDetailContent(
                      key: ValueKey(_char),
                      character: _char,
                      deps: widget.deps,
                      scrollable: false,
                      compact: true,
                    ),
                    const SizedBox(height: 16),
                    CompositaPicker(
                      key: ValueKey('picker-$_char'),
                      character: _char,
                      composita: widget.deps.composita.lookup(_char),
                      reviewRepo: ReviewRepository(widget.deps.database),
                      wordIndex: widget.deps.wordIndex,
                      recognizer: widget.deps.recognizer,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(_isLast ? l.addRemoveSlideshowDone : l.addRemoveSlideshowNext),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompositaLine(String word) {
    final composita = widget.deps.composita
        .lookup(_char)
        .cast<Composita?>()
        .firstWhere((c) => c!.word == word, orElse: () => null);
    if (composita == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(word, style: const TextStyle(fontSize: 16)),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '${composita.word} (${composita.reading}) — ${composita.meaning}',
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
