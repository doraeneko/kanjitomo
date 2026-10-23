import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../app_dependencies.dart';
import '../../core/db/tables.dart';
import '../../core/theme/app_colors.dart';
import '../../data/composita_repository.dart';
import '../../l10n/app_localizations.dart';
import '../kanji_browser/kanji_detail_screen.dart';
import 'review_repository.dart';
import 'sentence_selection.dart';
import 'study_scope.dart';
import '../../widgets/help_info_button.dart';

/// Known/unknown breakdown per card type -- "both directions" (reading via
/// kanjiRecognition, writing via drawFromMeaning) -- plus a separate C+D
/// (composita/sentence) coverage row, all scoped to whatever StudyScope is
/// current when this screen opens (the Learning section's JLPT/Custom
/// Statistics button, per plan.md) rather than the whole ~2,140-kanji
/// Jōyō deck. Also offers a button to wipe all review progress and start
/// over.
class StatisticsScreen extends StatefulWidget {
  final AppDependencies deps;

  const StatisticsScreen({super.key, required this.deps});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late final ReviewRepository _reviewRepo;
  Map<CardType, CardTypeStats>? _stats;
  CompositaCoverage? _compositaCoverage;
  Map<String, int>? _dueDist;
  Map<String, KanjiProgress>? _progress;
  Map<String, Set<String>>? _wordsByCharacter;
  // Per-character composita dot: 0=grey, 1=orange, 2=green.
  Map<String, int> _compositaDotScore = {};
  List<_JlptLevelStats>? _jlptStats;

  @override
  void initState() {
    super.initState();
    _reviewRepo = ReviewRepository(widget.deps.database);
    _load();
  }

  Set<String> _scopeCharacters(StudyScope scope) {
    return scope.characters;
  }

  Future<void> _load() async {
    await widget.deps.ensureComposita();
    final scope = widget.deps.studyScope.scope.value;
    final characters = _scopeCharacters(scope);

    final stats = <CardType, CardTypeStats>{};
    for (final cardType in CardType.values) {
      stats[cardType] = await _reviewRepo.statsFor(cardType, characters);
    }

    // Words the review session will test for each character. A custom
    // selection (auto-picked on add, manual picks, Anki import) always
    // counts -- the session tests it regardless of the composita ceiling,
    // and a null ceiling ("Off") means "no limit" there, not "disabled".
    // Without a custom selection, fall back to ceiling filtering only when
    // a ceiling is set; with no ceiling that fallback would be every
    // bundled word, none of which the session actually tests.
    final wordsByCharacter = <String, Set<String>>{};
    final customComposita =
        await _reviewRepo.customCompositaForCharacters(characters);
    final userComposita = await _reviewRepo.allUserCompositaByChar();
    for (final char in characters) {
      final custom = customComposita[char] ?? const <String>{};
      if (custom.isEmpty && !compositaEnabled(scope)) continue;
      final bundled = widget.deps.composita.lookup(char);
      final merged = _mergeComposita(bundled, userComposita[char]);
      final eligible = eligibleComposita(
        merged,
        scope,
        custom,
        charJlptLevel: widget.deps.jlptLevels.levelOf(char),
      );
      if (eligible.isNotEmpty) {
        wordsByCharacter[char] = eligible.map((c) => c.word).toSet();
      }
    }
    final compositaCoverage = await _reviewRepo.compositaProgressFor(
      wordsByCharacter,
    );

    final dueDist = await _reviewRepo.dueDateDistribution(scope);

    final progress = await _reviewRepo.overallProgress();

    // Pre-compute per-character composita dot status for sorting.
    final compositaDots = <String, int>{};
    if (wordsByCharacter.isNotEmpty) {
      final charSet = wordsByCharacter.keys.toSet();
      final testedReading = await _reviewRepo.testedCompositaWordsFor(
        charSet, CompositaDirection.reading);
      final testedWriting = await _reviewRepo.testedCompositaWordsFor(
        charSet, CompositaDirection.writing);
      for (final entry in wordsByCharacter.entries) {
        final char = entry.key;
        final words = entry.value;
        final rDone = words.where(
          (testedReading[char] ?? const {}).contains).length;
        final wDone = words.where(
          (testedWriting[char] ?? const {}).contains).length;
        if (rDone >= words.length && wDone >= words.length) {
          compositaDots[char] = 2; // green
        } else if (rDone > 0 || wDone > 0) {
          compositaDots[char] = 1; // orange
        } else {
          compositaDots[char] = 0; // grey
        }
      }
    }

    // Compute per-JLPT-level breakdown.
    final jlptRepo = widget.deps.jlptLevels;
    final jlptStats = <int, _JlptLevelStats>{};
    for (final level in [5, 4, 3, 2, 1]) {
      jlptStats[level] = _JlptLevelStats(level: level);
    }
    // Level 0 = no JLPT tag.
    jlptStats[0] = _JlptLevelStats(level: 0);
    for (final char in characters) {
      final level = jlptRepo.levelOf(char) ?? 0;
      final ls = jlptStats[level]!;
      final dot = _mainDot(progress[char]);
      // "Learnt" = the kanji itself (A+B known); "complete" additionally
      // needs every testable composita covered. null = no testable
      // composita → nothing left to complete.
      final cDot = compositaDots[char];
      final isLearnt = dot == 2;
      final isLearning = !isLearnt && (dot >= 1 || (cDot != null && cDot >= 1));
      if (isLearnt) {
        ls.learnt++;
        if (cDot == null || cDot == 2) ls.complete++;
      } else if (isLearning) {
        ls.learning++;
      } else {
        ls.newCount++;
      }
    }
    // Count not-selected kanji per level (all kanji in that level minus
    // those in the study pool).
    for (final level in [5, 4, 3, 2, 1]) {
      final allInLevel = jlptRepo.charsInLevels({level});
      final selectedInLevel =
          allInLevel.where((c) => characters.contains(c)).length;
      jlptStats[level]!.notSelected = allInLevel.length - selectedInLevel;
      jlptStats[level]!.total = allInLevel.length;
    }
    // Level 0 has no fixed "all kanji" count — total is just selected.
    final l0 = jlptStats[0]!;
    l0.total = l0.newCount + l0.learning + l0.learnt;
    final jlptStatsList = [
      for (final level in [5, 4, 3, 2, 1]) jlptStats[level]!,
      if (l0.hasAny) l0,
    ];

    if (!mounted) return;
    setState(() {
      _stats = stats;
      _compositaCoverage = compositaCoverage;
      _dueDist = dueDist;
      _progress = progress;
      _wordsByCharacter = wordsByCharacter;
      _compositaDotScore = compositaDots;
      _jlptStats = jlptStatsList;
    });
  }

  Future<void> _confirmReset() async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.statisticsResetDialogTitle),
        content: Text(l.statisticsResetDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.dialogCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.statisticsResetConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _reviewRepo.resetAllProgress();
      await _load();
    }
  }

  static List<Composita> _mergeComposita(
    List<Composita> bundled,
    List<Composita>? userAdded,
  ) {
    if (userAdded == null || userAdded.isEmpty) return bundled;
    final seen = bundled.map((c) => c.word).toSet();
    final merged = [...bundled];
    for (final c in userAdded) {
      if (seen.add(c.word)) merged.add(c);
    }
    return merged;
  }

  String _label(AppLocalizations l, CardType cardType) => switch (cardType) {
    CardType.kanjiRecognition => l.statisticsKanjiRecognition,
    CardType.drawFromMeaning => l.statisticsDrawFromMeaning,
    CardType.readingCloze => l.statisticsReadingCloze,
    CardType.drawInSentence => l.statisticsDrawInSentence,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final stats = _stats;
    final composita = _compositaCoverage;
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.statisticsTitle),
        actions: [HelpInfoButton(helpText: l.helpStatistics)],
      ),
      body: stats == null || composita == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_progress != null)
                      _buildSummaryPie(l, colors),
                    if (_jlptStats != null)
                      _buildJlptOverview(l, colors),
                    if (_dueDist != null) _buildDueOverview(l, _dueDist!, colors),
                    for (final cardType in CardType.values)
                      _buildRow(l, _label(l, cardType), stats[cardType]!, colors),
                    _buildCompositaRow(l, composita, colors),
                    if (_progress != null)
                      _buildKanjiGrid(l, colors),
                    const SizedBox(height: 24),
                    Center(
                      child: OutlinedButton(
                        onPressed: _confirmReset,
                        child: Text(l.statisticsResetButton),
                      ),
                    ),
                  ],
                ),
              ),
              ),
            ),
    );
  }

  // Main dot color: 0=grey, 1=orange, 2=green.
  static int _mainDot(KanjiProgress? p) {
    if (p != null &&
        p.reading == CardProgress.known &&
        p.writing == CardProgress.known) return 2;
    if (p != null &&
        (p.reading != CardProgress.none ||
         p.writing != CardProgress.none)) return 1;
    return 0;
  }

  /// The kanji itself is learnt: recognition and drawing (A+B) both known.
  bool _isKanjiLearnt(String c) => _mainDot(_progress?[c]) == 2;

  /// Learnt and every testable composita covered in both directions
  /// (characters without testable composita count as complete).
  bool _isComplete(String c) =>
      _isKanjiLearnt(c) &&
      (!_compositaDotScore.containsKey(c) || _compositaDotScore[c] == 2);

  Widget _buildSummaryPie(AppLocalizations l, AppColors colors) {
    final scope = widget.deps.studyScope.scope.value;
    final chars = _scopeCharacters(scope);
    final learnt = chars.where(_isKanjiLearnt).length;
    final complete = chars.where(_isComplete).length;
    final remaining = chars.length - learnt;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _PieChart(
            values: [
              complete.toDouble(),
              (learnt - complete).toDouble(),
              remaining.toDouble(),
            ],
            colors: [
              colors.statusGreen,
              colors.statusGreen.withValues(alpha: 0.4),
              colors.statusGreyLight,
            ],
            size: 100,
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.statisticsLearnt(learnt, chars.length),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                l.statisticsComplete(complete, chars.length),
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJlptOverview(AppLocalizations l, AppColors colors) {
    final stats = _jlptStats!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.statisticsJlptOverview,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Table(
            columnWidths: const {
              0: FixedColumnWidth(36),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
              3: FlexColumnWidth(),
              4: FlexColumnWidth(),
              5: FlexColumnWidth(),
              6: FlexColumnWidth(),
            },
            children: [
              TableRow(
                children: [
                  const SizedBox.shrink(),
                  _headerCell('#', colors),
                  _headerCell(l.statisticsJlptNotSelected, colors),
                  _headerCell(l.statisticsJlptNew, colors),
                  _headerCell(l.statisticsJlptLearning, colors),
                  _headerCell(l.statisticsJlptLearnt, colors),
                  _headerCell(l.statisticsJlptComplete, colors),
                ],
              ),
              for (final s in stats)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        s.level == 0 ? '—' : 'N${s.level}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    _dataCell(s.total, colors.textTertiary),
                    _dataCell(s.notSelected, colors.statusGreyLight),
                    _dataCell(s.newCount, colors.statusGreyLight),
                    _dataCell(s.learning, colors.statusOrange),
                    _dataCell(s.learnt, colors.statusGreen),
                    _dataCell(s.complete, colors.statusGreen),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors.textTertiary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _dataCell(int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '$value',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: value == 0 ? color : null,
        ),
      ),
    );
  }

  Widget _buildDueOverview(AppLocalizations l, Map<String, int> dist, AppColors colors) {
    final buckets = [
      (l.dueOverviewOverdue, dist['overdue']!, colors.statusRed),
      (l.dueOverviewToday, dist['today']!, colors.statusOrange),
      (l.dueOverviewTomorrow, dist['tomorrow']!, colors.statusBlue),
      (l.dueOverviewThisWeek, dist['thisWeek']!, colors.statusIndigo),
      (l.dueOverviewLater, dist['later']!, colors.statusGrey),
      (l.dueOverviewNotStarted, dist['notStarted']!, colors.statusGreyLight),
    ];
    final maxValue = buckets.fold<int>(0, (m, b) => b.$2 > m ? b.$2 : m);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.dueOverviewTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          for (final (label, value, color) in buckets)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(label, style: const TextStyle(fontSize: 13)),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '$value',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (maxValue > 0 && value > 0)
                    Container(
                      height: 14,
                      width: 120 * (value / maxValue),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(AppLocalizations l, String label, CardTypeStats s, AppColors colors) {
    final total = s.known + s.missed + s.notStarted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _PieChart(
                values: [
                  s.known.toDouble(),
                  s.missed.toDouble(),
                  s.notStarted.toDouble(),
                ],
                colors: [colors.statusGreen, colors.statusOrange, colors.statusGreyLight],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendRow(l, l.statisticsKnown, s.known, colors.statusGreen, total),
                    _legendRow(l, l.statisticsMissed, s.missed, colors.statusOrange, total),
                    _legendRow(
                      l,
                      l.statisticsNotStarted,
                      s.notStarted,
                      colors.statusGreyLight,
                      total,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendRow(AppLocalizations l, String label, int value, Color color, int total) {
    final pct = total == 0 ? 0 : (value / total * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(l.legendValuePercent(label, value, pct)),
        ],
      ),
    );
  }

  /// C+D coverage never gates green (see ReviewRepository.overallProgress)
  /// -- shown as its own "how much have I tested" row, split by direction,
  /// against however many composita words are actually testable under the
  /// current scope (a JLPT ceiling, or the custom set's hand-picked words).
  Widget _buildCompositaRow(AppLocalizations l, CompositaCoverage c, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.statisticsCompositaTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            l.statisticsTestableWords(c.testable),
            style: TextStyle(color: colors.textTertiary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _compositaPie(
                  l,
                  l.statisticsReadingTested,
                  c.testedReading,
                  c.testable,
                  colors,
                ),
              ),
              Expanded(
                child: _compositaPie(
                  l,
                  l.statisticsWritingTested,
                  c.testedWriting,
                  c.testable,
                  colors,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKanjiGrid(AppLocalizations l, AppColors colors) {
    final scope = widget.deps.studyScope.scope.value;
    final chars = _scopeCharacters(scope).toList();
    // Sort by visual dot colors: grey(0) < orange(1) < green(2).
    // Characters with no composita get score 2 (done).
    chars.sort((a, b) {
      final cA = _compositaDotScore.containsKey(a) ? _compositaDotScore[a]! : 2;
      final cB = _compositaDotScore.containsKey(b) ? _compositaDotScore[b]! : 2;
      final sa = _mainDot(_progress?[a]) * 3 + cA;
      final sb = _mainDot(_progress?[b]) * 3 + cB;
      return sa.compareTo(sb);
    });

    final learntCount = chars.where(_isKanjiLearnt).length;
    final completeCount = chars.where(_isComplete).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.statisticsInspectAllKanji,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            '${l.statisticsLearnt(learntCount, chars.length)} · '
            '${l.statisticsComplete(completeCount, chars.length)}',
            style: TextStyle(color: colors.textTertiary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 2,
            runSpacing: 2,
            children: chars.map((char) {
              final dotColor = switch (_mainDot(_progress?[char])) {
                2 => colors.statusGreen,
                1 => colors.statusOrange,
                _ => colors.statusGreyLight,
              };

              // Second dot: composita progress per character.
              final eligibleWords = _wordsByCharacter?[char];
              final bool hasComposita = eligibleWords != null && eligibleWords.isNotEmpty;

              return GestureDetector(
                onTap: () => _showProgressDialog(char),
                onLongPress: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => KanjiDetailScreen(
                        character: char,
                        deps: widget.deps,
                      ),
                    ),
                  );
                },
                child: SizedBox(
                  width: 36,
                  height: hasComposita ? 50 : 44,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        char,
                        style: const TextStyle(fontSize: 20),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dotColor,
                            ),
                          ),
                          if (hasComposita) ...[
                            const SizedBox(width: 2),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: switch (_compositaDotScore[char] ?? 0) {
                                  2 => colors.statusGreen,
                                  1 => colors.statusOrange,
                                  _ => colors.statusGrey,
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _showProgressDialog(String char) async {
    final eligibleWords = _wordsByCharacter?[char] ?? {};
    final detail = await _reviewRepo.detailedProgressFor(
      char,
      eligibleWords: eligibleWords,
    );
    final info = widget.deps.kanjiInfo.lookup(char);
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    final meaning = info?.meanings.join(', ') ?? '';
    final colors = context.appColors;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Text(char, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                meaning,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _progressRow(
              l.progressDetailRecognition,
              detail.recognitionStarted,
              detail.recognitionReps,
              KanjiProgressDetail.knownThreshold,
              l,
              colors,
            ),
            const SizedBox(height: 8),
            _progressRow(
              l.progressDetailDrawing,
              detail.drawingStarted,
              detail.drawingReps,
              KanjiProgressDetail.knownThreshold,
              l,
              colors,
            ),
            if (detail.compositaTestable > 0) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 4),
              _compositaProgressRow(
                l.progressDetailComposita,
                detail.compositaReadingTested,
                detail.compositaWritingTested,
                detail.compositaTestable,
                l,
                colors,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => KanjiDetailScreen(
                    character: char,
                    deps: widget.deps,
                  ),
                ),
              );
            },
            child: Text(l.progressDetailViewFull),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.dialogCancel),
          ),
        ],
      ),
    );
  }

  Widget _progressRow(
    String label,
    bool started,
    int reps,
    int threshold,
    AppLocalizations l,
    AppColors colors,
  ) {
    final Icon icon;
    final String status;
    if (!started) {
      icon = Icon(Icons.circle_outlined, color: colors.statusGreyLight, size: 18);
      status = l.progressDetailNotStarted;
    } else if (reps >= threshold) {
      icon = Icon(Icons.check_circle, color: colors.statusGreen, size: 18);
      status = l.progressDetailStatus(reps, threshold);
    } else {
      icon = Icon(Icons.timelapse, color: colors.statusOrange, size: 18);
      status = l.progressDetailStatus(reps, threshold);
    }
    return Row(
      children: [
        icon,
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(status, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _compositaProgressRow(
    String label,
    int readingTested,
    int writingTested,
    int testable,
    AppLocalizations l,
    AppColors colors,
  ) {
    final allDone =
        readingTested >= testable && writingTested >= testable;
    final anyStarted = readingTested > 0 || writingTested > 0;
    final Icon icon;
    if (allDone) {
      icon = Icon(Icons.check_circle, color: colors.statusGreen, size: 18);
    } else if (anyStarted) {
      icon = Icon(Icons.timelapse, color: colors.statusOrange, size: 18);
    } else {
      icon = Icon(Icons.circle_outlined, color: colors.statusGreyLight, size: 18);
    }
    return Row(
      children: [
        icon,
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(
          '${l.statisticsReadingTested}: $readingTested/$testable\n'
          '${l.statisticsWritingTested}: $writingTested/$testable',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  Widget _compositaPie(AppLocalizations l, String label, int tested, int testable, AppColors colors) {
    final remaining = (testable - tested).clamp(0, testable);
    return Column(
      children: [
        _PieChart(
          values: [tested.toDouble(), remaining.toDouble()],
          colors: [colors.statusGreen, colors.statusGreyLight],
          size: 56,
        ),
        const SizedBox(height: 6),
        Text(l.compositaPieLabel(label, tested, testable)),
      ],
    );
  }
}

/// A minimal pie chart -- hand-rolled via [CustomPainter] rather than a
/// charting package, since a handful of proportional slices is simple
/// geometry and this app otherwise has zero UI dependencies (see
/// pubspec.yaml). Renders a flat grey circle for an all-zero [values] (e.g.
/// a brand-new scope with nothing reviewed yet) rather than an empty canvas,
/// so the chart always reads as "a whole" even before any slice exists.
class _PieChart extends StatelessWidget {
  final List<double> values;
  final List<Color> colors;
  final double size;

  const _PieChart({
    required this.values,
    required this.colors,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    final total = values.fold<double>(0, (a, b) => a + b);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: total <= 0
            ? _PieChartPainter(
                values: const [1],
                colors: [context.appColors.statusGreyLight],
              )
            : _PieChartPainter(values: values, colors: colors),
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  const _PieChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;
    final rect = Offset.zero & size;
    var start = -pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * 2 * pi;
      if (values[i] > 0) {
        canvas.drawArc(rect, start, sweep, true, Paint()..color = colors[i]);
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.colors != colors;
}

class _JlptLevelStats {
  final int level; // 1–5, or 0 for "no JLPT"
  int total = 0; // all kanji in this JLPT level
  int notSelected = 0;
  int newCount = 0; // selected but not started
  int learning = 0;
  int learnt = 0; // kanji itself learnt (A+B), composita aside
  int complete = 0; // learnt and all testable composita covered (⊆ learnt)

  _JlptLevelStats({required this.level});

  bool get hasAny =>
      notSelected > 0 || newCount > 0 || learning > 0 || learnt > 0;
}

