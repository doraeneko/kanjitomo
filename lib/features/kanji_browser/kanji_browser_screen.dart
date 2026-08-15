import 'package:flutter/material.dart';

import '../../app_dependencies.dart';
import '../../data/kanji_info_repository.dart';
import '../../l10n/app_localizations.dart';
import '../review/review_repository.dart';
import '../review/study_scope.dart';
import 'kanji_detail_screen.dart';
import 'kanji_search.dart';
import '../../widgets/coffee_button.dart';

/// A general "browse every Jōyō kanji" table, reachable from the main
/// lookup screen. Scope-based filtering (JLPT/RTK/Custom) and custom-set
/// editing used to live here, but both moved to the Learning section (see
/// jlpt_edit_screen.dart/custom_edit_screen.dart) -- this screen is now
/// just a flat utility for inspecting/editing any kanji's story field,
/// with a search box (see kanji_search.dart's matchesKanjiSearch) to find
/// one by reading, meaning, or stroke count instead of scrolling the whole
/// ~2,140-kanji list. Each row shows up to two small progress dots
/// (green = known, orange = missed) from ReviewRepository.overallProgress()
/// -- one for reading, one for writing -- shown independently since a
/// character can be solid in one direction and untouched in the other.
///
/// A table (kanji/meaning/keyword/readings/strokes columns) rather than the
/// grid this screen used to be -- a grid of bare characters was fine for
/// "spot one I recognize" but told you nothing about a kanji without
/// tapping into its detail screen; a table surfaces the meaning/readings/
/// stroke count you're usually actually scanning for right in the list.
/// Built as a plain ListView.builder with two Rows of flex-matched cells
/// (a fixed header + lazy data rows) rather than Flutter's DataTable/Table
/// widgets -- both of those build every row eagerly, which doesn't scale
/// to ~2,140 rows the way a lazy list does.
enum _SortColumn { none, strokes, keyword }

class KanjiBrowserScreen extends StatefulWidget {
  final AppDependencies deps;

  const KanjiBrowserScreen({super.key, required this.deps});

  @override
  State<KanjiBrowserScreen> createState() => _KanjiBrowserScreenState();
}

class _KanjiBrowserScreenState extends State<KanjiBrowserScreen> {
  // Flex ratios shared between the header row and every data row so
  // columns line up.
  static const _kanjiFlex = 3;
  static const _meaningFlex = 4;
  static const _keywordFlex = 4;
  static const _readingsFlex = 4;
  static const _strokesFlex = 4;

  late final List<String> _allCharacters = widget.deps.kanjiInfo.characters;
  late final ReviewRepository _reviewRepo;
  final TextEditingController _searchController = TextEditingController();
  Map<String, KanjiProgress> _progress = const {};
  Map<String, String> _keywords = const {};
  String _query = '';
  _SortColumn _sortColumn = _SortColumn.none;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _reviewRepo = ReviewRepository(widget.deps.database);
    _loadProgress();
    _loadKeywords();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim());
    });
    widget.deps.studyScope.scope.addListener(_onScopeChanged);
  }

  @override
  void dispose() {
    widget.deps.studyScope.scope.removeListener(_onScopeChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onScopeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadProgress() async {
    final progress = await _reviewRepo.overallProgress();
    if (mounted) setState(() => _progress = progress);
  }

  Future<void> _loadKeywords() async {
    final keywords = await _reviewRepo.allStoryKeywords();
    if (mounted) setState(() => _keywords = keywords);
  }

  Future<void> _openDetail(String char) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => KanjiDetailScreen(character: char, deps: widget.deps),
      ),
    );
    _loadProgress(); // refresh in case review progress changed meanwhile
    _loadKeywords(); // ditto for a keyword edited on the detail screen
  }

  void _onSortTap(_SortColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  /// Missing values (no stroke-count entry, no keyword set) always sort to
  /// the end regardless of direction -- an ascending keyword sort putting
  /// every keyword-less kanji first would bury the very thing you're
  /// sorting to find, and putting them first on descending too would be
  /// inconsistent with that.
  int _compareNullsLast(Comparable? a, Comparable? b, bool ascending) {
    final aMissing = a == null || a == '';
    final bMissing = b == null || b == '';
    if (aMissing && bMissing) return 0;
    if (aMissing) return 1;
    if (bMissing) return -1;
    final cmp = a.compareTo(b);
    return ascending ? cmp : -cmp;
  }

  List<String> get _filtered {
    final base = _query.isEmpty
        ? _allCharacters
        : _allCharacters.where((char) {
            return matchesKanjiSearch(
              character: char,
              info: widget.deps.kanjiInfo.lookup(char),
              strokeCount: widget.deps.strokePaths.lookup(char)?.strokeCount,
              query: _query,
            );
          }).toList();
    if (_sortColumn == _SortColumn.none) return base;
    final sorted = [...base];
    sorted.sort((a, b) {
      switch (_sortColumn) {
        case _SortColumn.strokes:
          return _compareNullsLast(
            widget.deps.strokePaths.lookup(a)?.strokeCount,
            widget.deps.strokePaths.lookup(b)?.strokeCount,
            _sortAscending,
          );
        case _SortColumn.keyword:
          return _compareNullsLast(_keywords[a], _keywords[b], _sortAscending);
        case _SortColumn.none:
          return 0;
      }
    });
    return sorted;
  }

  String _readingsText(KanjiInfo? info) {
    if (info == null) return '';
    final on = info.on.join('、'); // 、
    final kun = info.kun.join('、');
    if (on.isEmpty) return kun;
    if (kun.isEmpty) return on;
    return '$on / $kun';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final filtered = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.kanjiBrowserTitle),
        actions: const [CoffeeButton()],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: l.kanjiBrowserSearchLabel,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _searchController.clear,
                        ),
                ),
              ),
            ),
            _buildHeaderRow(context),
            const Divider(height: 1),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text(l.kanjiBrowserNoMatch))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final char = filtered[index];
                        return _buildDataRow(char);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final style = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(flex: _kanjiFlex, child: Text(l.kanjiBrowserColumnKanji, style: style)),
          Expanded(flex: _meaningFlex, child: Text(l.kanjiBrowserColumnMeaning, style: style)),
          Expanded(
            flex: _keywordFlex,
            child: _sortableHeader(l.kanjiBrowserColumnKeyword, _SortColumn.keyword, style),
          ),
          Expanded(
            flex: _readingsFlex,
            child: Text(l.kanjiBrowserColumnReadings, style: style),
          ),
          Expanded(
            flex: _strokesFlex,
            child: _sortableHeader(
              l.kanjiBrowserColumnStrokes,
              _SortColumn.strokes,
              style,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortableHeader(
    String label,
    _SortColumn column,
    TextStyle? style, {
    bool alignEnd = false,
  }) {
    final active = _sortColumn == column;
    final arrow = Icon(
      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
      size: 14,
      color: style?.color,
    );
    final children = [
      if (alignEnd && active) ...[arrow, const SizedBox(width: 2)],
      Flexible(
        child: Text(label, style: style, overflow: TextOverflow.ellipsis),
      ),
      if (!alignEnd && active) ...[const SizedBox(width: 2), arrow],
    ];
    return InkWell(
      onTap: () => _onSortTap(column),
      child: Row(
        mainAxisAlignment: alignEnd
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDataRow(String char) {
    final info = widget.deps.kanjiInfo.lookup(char);
    final strokeCount = widget.deps.strokePaths.lookup(char)?.strokeCount;
    final progress = _progress[char];
    final keyword = _keywords[char];
    final inPool = widget.deps.studyScope.scope.value.characters.contains(char);
    return InkWell(
      key: ValueKey(char),
      onTap: () => _openDetail(char),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: _kanjiFlex,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    char,
                    style: TextStyle(
                      fontSize: 22,
                      color: inPool ? Colors.indigo : null,
                      fontWeight: inPool ? FontWeight.bold : null,
                    ),
                  ),
                  if (progress != null &&
                      (progress.reading != CardProgress.none ||
                          progress.writing != CardProgress.none)) ...[
                    const SizedBox(width: 6),
                    if (progress.reading != CardProgress.none)
                      _progressDot(progress.reading),
                    if (progress.reading != CardProgress.none &&
                        progress.writing != CardProgress.none)
                      const SizedBox(width: 3),
                    if (progress.writing != CardProgress.none)
                      _progressDot(progress.writing),
                  ],
                ],
              ),
            ),
            Expanded(
              flex: _meaningFlex,
              child: Text(
                info?.meanings.join(', ') ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: _keywordFlex,
              child: Text(
                keyword ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            Expanded(
              flex: _readingsFlex,
              child: Text(
                _readingsText(info),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: _strokesFlex,
              child: Text(
                strokeCount == null ? '' : '$strokeCount',
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressDot(CardProgress progress) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: progress == CardProgress.known ? Colors.green : Colors.orange,
    ),
  );
}
