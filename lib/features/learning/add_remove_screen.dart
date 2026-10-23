import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, LengthLimitingTextInputFormatter;
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_dependencies.dart';
import '../../core/theme/app_colors.dart';
import '../../core/kanji_recognizer.dart';
import '../../data/composita_repository.dart';
import '../../l10n/app_localizations.dart';
import '../kanji_browser/kanji_detail_content.dart';
import '../kanji_browser/kanji_search.dart';
import '../review/draw_and_pick.dart';
import '../review/review_repository.dart';
import '../review/sentence_selection.dart';
import '../review/study_scope.dart';
import 'anki_import_screen.dart';
import 'composita_picker.dart';

enum _PoolSort { rtk, added, modified }

/// Unified screen for adding kanji to (and removing them from) the learning
/// pool. Three tabs via bottom navigation:
/// 1. Browse all kanji (by JLPT level, then stroke count)
/// 2. Add by drawing
/// 3. Learning pool (view/edit/remove)
///
/// Composita settings (ceiling, max per kanji) are in an ExpansionTile on the
/// Browse tab since they affect the auto-selection algorithm.
class AddRemoveScreen extends StatefulWidget {
  final AppDependencies deps;

  const AddRemoveScreen({super.key, required this.deps});

  @override
  State<AddRemoveScreen> createState() => _AddRemoveScreenState();
}

class _AddRemoveScreenState extends State<AddRemoveScreen> {
  static const _tabIndexKey = 'add_remove.tab_index';

  late final ReviewRepository _reviewRepo;
  final _poolSearchController = TextEditingController();
  final _browseSearchController = TextEditingController();
  final _batchCountController = TextEditingController(text: '5');
  int _tabIndex = 0;
  String _poolQuery = '';
  String _browseQuery = '';
  _PoolSort _poolSort = _PoolSort.rtk;
  bool _adding = false;
  // Composita counts for pool kanji (character -> word count).
  Map<String, int> _compositaCounts = {};
  Map<String, DateTime> _addedDates = {};
  Map<String, DateTime> _modifiedDates = {};
  // Pre-sorted kanji list for browse tab (computed once, filtered on search).
  List<String> _browseKanji = [];
  // JLPT level for each kanji in the browse list.
  Map<String, int?> _browseJlptLevels = {};
  // Which JLPT level to show in the browse tab.
  // -1 means "All", null means "Other" (non-JLPT), 1–5 means that level.
  int _browseLevelSelection = -1; // -1 = All

  @override
  void initState() {
    super.initState();
    _reviewRepo = ReviewRepository(widget.deps.database);
    _loadCompositaCounts();
    _loadDates();
    _loadSavedPrefs();
    _buildBrowseList();
    _poolSearchController.addListener(() {
      setState(() => _poolQuery = _poolSearchController.text.trim());
    });
    _browseSearchController.addListener(() {
      setState(() => _browseQuery = _browseSearchController.text.trim());
    });
    widget.deps.studyScope.scope.addListener(_onScopeChanged);
  }

  Future<void> _loadSavedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final tab = prefs.getInt(_tabIndexKey);
    if (mounted) {
      setState(() {
        if (tab != null && tab >= 0 && tab < 3) _tabIndex = tab;
      });
    }
  }

  /// Build the pre-sorted kanji list for the browse tab: primary sort by
  /// JLPT level (N5=5 first → N1=1 last, non-JLPT at bottom), secondary
  /// sort by stroke count ascending.
  void _buildBrowseList() {
    final allKanji = widget.deps.kanjiInfo.characters;
    final levels = <String, int?>{};
    for (final char in allKanji) {
      levels[char] = widget.deps.jlptLevels.levelOf(char);
    }
    _browseJlptLevels = levels;

    allKanji.sort((a, b) {
      final la = levels[a];
      final lb = levels[b];
      // Non-JLPT kanji sort after all JLPT kanji.
      final levelA = la != null ? (6 - la) : 100; // N5→1, N4→2, ..., N1→5, null→100
      final levelB = lb != null ? (6 - lb) : 100;
      if (levelA != levelB) return levelA.compareTo(levelB);
      final sa = widget.deps.strokePaths.lookup(a)?.strokeCount ?? 99;
      final sb = widget.deps.strokePaths.lookup(b)?.strokeCount ?? 99;
      return sa.compareTo(sb);
    });
    _browseKanji = allKanji;
  }

  @override
  void dispose() {
    widget.deps.studyScope.scope.removeListener(_onScopeChanged);
    _poolSearchController.dispose();
    _browseSearchController.dispose();
    _batchCountController.dispose();
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
          kanjiInfo: widget.deps.kanjiInfo.lookup(char),
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

  /// Add a single kanji from the browse tab.
  Future<void> _addSingleKanji(String char) async {
    if (_scope.characters.contains(char) || _adding) return;
    await widget.deps.ensureComposita();
    await _addKanjiToPool([char]);
  }

  /// Batch-add kanji from a specific JLPT level (or all non-JLPT) in RTK order.
  Future<void> _addBatchFromLevel(int levelSelection, int count) async {
    if (count <= 0 || _adding) return;
    await widget.deps.ensureComposita();
    final List<String> candidates;
    if (levelSelection == 0) {
      // "Other" — non-JLPT kanji
      candidates = widget.deps.kanjiInfo.characters
          .where((c) => widget.deps.jlptLevels.levelOf(c) == null)
          .toList();
    } else {
      candidates = widget.deps.jlptLevels.charsInLevels({levelSelection});
    }
    final toAdd = _nextKanjiInRtkOrder(candidates, count);
    if (toAdd.isEmpty) return;
    await _addKanjiToPool(toAdd);
  }

  Future<void> _importFromAnki() async {
    final result = await Navigator.of(context).push<AnkiImportResult>(
      MaterialPageRoute(
        builder: (_) => AnkiImportScreen(deps: widget.deps),
      ),
    );
    if (result == null || !mounted) return;

    await widget.deps.ensureComposita();

    // Merge extra composita from the import.
    for (final entry in result.extraComposita.entries) {
      for (final word in entry.value) {
        await _reviewRepo.addCustomComposita(entry.key, word);
      }
    }

    if (result.kanji.isNotEmpty) {
      await _addKanjiToPool(result.kanji);
    } else {
      // Only composita updates, no new kanji.
      await _loadCompositaCounts();
    }
  }

  Future<void> _addKanjiToPool(List<String> chars) async {
    setState(() => _adding = true);
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
    setState(() => _adding = false);

    if (chars.length > 1) {
      // Ask whether to go through the new kanji.
      final l = AppLocalizations.of(context)!;
      final goThrough = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.addRemoveGoThroughTitle(chars.length)),
          content: Text(l.addRemoveGoThroughMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l.addRemoveGoThroughNo),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l.addRemoveGoThroughYes),
            ),
          ],
        ),
      );
      if (goThrough != true || !mounted) return;
    }

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
    await widget.deps.ensureComposita();
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

    // Second confirmation — this is destructive and irreversible.
    if (!mounted) return;
    final reallyConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('本当に？'),
        content: Text(l.addRemoveClearSecondConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.dialogCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('本当！'),
          ),
        ],
      ),
    );
    if (reallyConfirmed != true) return;

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
                composita: rankComposita(widget.deps.composita.lookup(char)),
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

  // ── Composita settings ───────────────────────────────────────────────

  void _openCompositaSettings(AppLocalizations l) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.addRemoveCompositaSettings,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _buildCompositaSettingsContent(l, setSheetState),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCompositaSettingsContent(AppLocalizations l, StateSetter setSheetState) {
    final scope = _scope;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.addRemoveCompositaCeiling,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(l.addRemoveCompositaCeilingHelp,
            style: TextStyle(fontSize: 12, color: context.appColors.textTertiary)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(l.addRemoveCeilingOff),
              selected: scope.compositaCeiling == null,
              onSelected: (_) {
                _updateCompositaCeiling(null);
                setSheetState(() {});
              },
            ),
            for (final level in [5, 4, 3, 2])
              ChoiceChip(
                label: Text('N$level'),
                selected: scope.compositaCeiling == level,
                onSelected: (_) {
                  _updateCompositaCeiling(level);
                  setSheetState(() {});
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(l.addRemoveMaxComposita,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(l.addRemoveMaxCompositaHelp,
            style: TextStyle(fontSize: 12, color: context.appColors.textTertiary)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            for (final n in [2, 3, 4, 5])
              ChoiceChip(
                label: Text('$n'),
                selected: scope.maxCompositaPerKanji == n,
                onSelected: (_) {
                  _updateMaxComposita(n);
                  setSheetState(() {});
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompositaSettings(AppLocalizations l) {
    final scope = _scope;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 4),
        Text(l.addRemoveCompositaCeiling,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(l.addRemoveCompositaCeilingHelp,
            style: TextStyle(fontSize: 12, color: context.appColors.textTertiary)),
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
            style: TextStyle(fontSize: 12, color: context.appColors.textTertiary)),
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

  Widget _buildHelp(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: context.appColors.textSecondary),
      ),
    );
  }

  Widget _buildBrowseTab(AppLocalizations l) {
    final pool = _scope.characters;
    final levelFiltered = _browseLevelSelection == -1
        ? _browseKanji
        : _browseKanji.where((char) {
            final level = _browseJlptLevels[char];
            if (_browseLevelSelection == 0) return level == null; // "Other"
            return level == _browseLevelSelection;
          }).toList();
    final filtered = _browseQuery.isEmpty
        ? levelFiltered
        : levelFiltered.where((char) {
            return matchesKanjiSearch(
              character: char,
              info: widget.deps.kanjiInfo.lookup(char),
              strokeCount: widget.deps.strokePaths.lookup(char)?.strokeCount,
              query: _browseQuery,
            );
          }).toList();

    // Build flat list with section headers interleaved.
    final items = <_BrowseItem>[];
    int? lastLevel;
    bool headerInserted = false;
    for (final char in filtered) {
      final level = _browseJlptLevels[char];
      if (level != lastLevel) {
        final label = level != null ? 'N$level' : 'Other';
        items.add(_BrowseItem.header(label));
        lastLevel = level;
        headerInserted = true;
      }
      items.add(_BrowseItem.kanji(char));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _browseSearchController,
            decoration: InputDecoration(
              labelText: l.kanjiBrowserSearchLabel,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: _browseQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _browseSearchController.clear,
                    ),
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _browseLevelSelection == -1,
                onSelected: (_) => setState(() => _browseLevelSelection = -1),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 6),
              for (final level in [5, 4, 3, 2, 1]) ...[
                ChoiceChip(
                  label: Text('N$level'),
                  selected: _browseLevelSelection == level,
                  onSelected: (_) => setState(() => _browseLevelSelection = level),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 6),
              ],
              ChoiceChip(
                label: const Text('Other'),
                selected: _browseLevelSelection == 0,
                onSelected: (_) => setState(() => _browseLevelSelection = 0),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
        if (defaultTargetPlatform == TargetPlatform.android)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Import from AnkiDroid'),
                onPressed: _adding ? null : _importFromAnki,
              ),
            ),
          ),
        if (_browseLevelSelection != -1)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _adding
                      ? null
                      : () {
                          final count = int.tryParse(_batchCountController.text) ?? 0;
                          _addBatchFromLevel(_browseLevelSelection, count);
                        },
                  child: _adding
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add next'),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  child: TextField(
                    controller: _batchCountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('kanji in RTK order'),
              ],
            ),
          ),
        if (!headerInserted && filtered.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                l.kanjiBrowserNoMatch,
                style: TextStyle(color: context.appColors.textTertiary),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                if (item.isHeader) {
                  return Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Text(
                      item.label!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  );
                }
                final char = item.char!;
                final info = widget.deps.kanjiInfo.lookup(char);
                final strokes = widget.deps.strokePaths.lookup(char)?.strokeCount;
                final level = _browseJlptLevels[char];
                final inPool = pool.contains(char);
                final meaning = info?.meanings.isNotEmpty == true
                    ? info!.meanings.join(', ')
                    : '';
                final subtitleParts = <String>[
                  if (level != null) 'N$level',
                  if (strokes != null) '$strokes strokes',
                ];
                return ListTile(
                  dense: true,
                  leading: Text(
                    char,
                    style: const TextStyle(fontSize: 28, fontFamily: 'NotoSansJP'),
                  ),
                  title: Text(
                    meaning,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: subtitleParts.isNotEmpty
                      ? Text(subtitleParts.join(' · '))
                      : null,
                  trailing: inPool
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _removeCharacter(char),
                            ),
                          ],
                        )
                      : IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _adding ? null : () => _addSingleKanji(char),
                        ),
                );
              },
            ),
          ),
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
              Icon(Icons.info_outline, size: 16, color: context.appColors.textDisabled),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l.addRemovePoolTip,
                  style: TextStyle(fontSize: 12, color: context.appColors.textTertiary),
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
                    style: TextStyle(color: context.appColors.textTertiary),
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
      _buildBrowseTab(l),
      _buildDrawTab(l),
      _buildPoolTab(l),
    ];

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      appBar: AppBar(
        title: Text(l.addRemoveTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l.addRemoveCompositaSettings,
            onPressed: () => _openCompositaSettings(l),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            bodies[_tabIndex],
            if (_adding)
              Positioned.fill(
                child: Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) {
          setState(() => _tabIndex = i);
          SharedPreferences.getInstance().then((p) => p.setInt(_tabIndexKey, i));
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.list_alt),
            label: l.addRemoveBrowseTab,
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

/// Item in the browse tab's flat list — either a section header or a kanji row.
class _BrowseItem {
  final String? label; // non-null for headers
  final String? char; // non-null for kanji rows
  bool get isHeader => label != null;

  const _BrowseItem.header(this.label) : char = null;
  const _BrowseItem.kanji(this.char) : label = null;
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
        actions: [
          if (!_isLast)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.welcomeSkip),
            ),
        ],
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
                      composita: rankComposita(widget.deps.composita.lookup(_char)),
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
