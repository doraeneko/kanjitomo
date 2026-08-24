import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../app_dependencies.dart';
import '../../core/db/tables.dart';
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
    final scope = widget.deps.studyScope.scope.value;
    final characters = _scopeCharacters(scope);

    final stats = <CardType, CardTypeStats>{};
    for (final cardType in CardType.values) {
      stats[cardType] = await _reviewRepo.statsFor(cardType, characters);
    }

    // Same "not opted in yet" gate as the review session (see
    // sentence_selection.dart's compositaEnabled) -- JLPT mode with no
    // compositaCeiling chosen has nothing testable, not "everything".
    final wordsByCharacter = <String, Set<String>>{};
    if (compositaEnabled(scope)) {
      final customComposita = await _reviewRepo.customCompositaForCharacters(characters);
      final userComposita = await _reviewRepo.allUserCompositaByChar();
      for (final char in characters) {
        final bundled = widget.deps.composita.lookup(char);
        final userAdded = userComposita[char];
        final merged = _mergeComposita(bundled, userAdded);
        final eligible = eligibleComposita(
          merged,
          scope,
          customComposita[char] ?? const {},
          charJlptLevel: widget.deps.jlptLevels.levelOf(char),
        );
        if (eligible.isNotEmpty) {
          wordsByCharacter[char] = eligible.map((c) => c.word).toSet();
        }
      }
    }
    final compositaCoverage = await _reviewRepo.compositaProgressFor(
      wordsByCharacter,
    );

    final dueDist = await _reviewRepo.dueDateDistribution(scope);

    final progress = await _reviewRepo.overallProgress();

    if (!mounted) return;
    setState(() {
      _stats = stats;
      _compositaCoverage = compositaCoverage;
      _dueDist = dueDist;
      _progress = progress;
      _wordsByCharacter = wordsByCharacter;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(l.statisticsTitle),
        actions: [HelpInfoButton(helpText: l.helpStatistics)],
      ),
      body: stats == null || composita == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_dueDist != null) _buildDueOverview(l, _dueDist!),
                    for (final cardType in CardType.values)
                      _buildRow(l, _label(l, cardType), stats[cardType]!),
                    _buildCompositaRow(l, composita),
                    if (_progress != null)
                      _buildKanjiGrid(l),
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
    );
  }

  Widget _buildDueOverview(AppLocalizations l, Map<String, int> dist) {
    final buckets = [
      (l.dueOverviewOverdue, dist['overdue']!, Colors.red),
      (l.dueOverviewToday, dist['today']!, Colors.orange),
      (l.dueOverviewTomorrow, dist['tomorrow']!, Colors.blue),
      (l.dueOverviewThisWeek, dist['thisWeek']!, Colors.indigo),
      (l.dueOverviewLater, dist['later']!, Colors.grey),
      (l.dueOverviewNotStarted, dist['notStarted']!, Colors.grey.shade400),
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

  Widget _buildRow(AppLocalizations l, String label, CardTypeStats s) {
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
                colors: [Colors.green, Colors.orange, Colors.grey.shade400],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendRow(l, l.statisticsKnown, s.known, Colors.green, total),
                    _legendRow(l, l.statisticsMissed, s.missed, Colors.orange, total),
                    _legendRow(
                      l,
                      l.statisticsNotStarted,
                      s.notStarted,
                      Colors.grey.shade400,
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
  Widget _buildCompositaRow(AppLocalizations l, CompositaCoverage c) {
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
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
                ),
              ),
              Expanded(
                child: _compositaPie(
                  l,
                  l.statisticsWritingTested,
                  c.testedWriting,
                  c.testable,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKanjiGrid(AppLocalizations l) {
    final scope = widget.deps.studyScope.scope.value;
    final chars = _scopeCharacters(scope).toList();
    // Sort by RTK index (same order used for introduction).
    chars.sort((a, b) {
      final ai = widget.deps.rtkIndex.indexOf(a) ?? 99999;
      final bi = widget.deps.rtkIndex.indexOf(b) ?? 99999;
      return ai.compareTo(bi);
    });

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.statisticsInspectAllKanji,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 2,
            runSpacing: 2,
            children: chars.map((char) {
              final progress = _progress?[char];
              final Color dotColor;
              if (progress != null &&
                  progress.reading == CardProgress.known &&
                  progress.writing == CardProgress.known) {
                dotColor = Colors.green;
              } else if (progress != null &&
                  (progress.reading != CardProgress.none ||
                   progress.writing != CardProgress.none)) {
                dotColor = Colors.orange;
              } else {
                dotColor = Colors.grey.shade300;
              }

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
                            _CompositaDot(
                              character: char,
                              eligibleWords: eligibleWords,
                              reviewRepo: _reviewRepo,
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
            ),
            const SizedBox(height: 8),
            _progressRow(
              l.progressDetailDrawing,
              detail.drawingStarted,
              detail.drawingReps,
              KanjiProgressDetail.knownThreshold,
              l,
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
  ) {
    final Icon icon;
    final String status;
    if (!started) {
      icon = Icon(Icons.circle_outlined, color: Colors.grey.shade400, size: 18);
      status = l.progressDetailNotStarted;
    } else if (reps >= threshold) {
      icon = const Icon(Icons.check_circle, color: Colors.green, size: 18);
      status = l.progressDetailStatus(reps, threshold);
    } else {
      icon = const Icon(Icons.timelapse, color: Colors.orange, size: 18);
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
  ) {
    final allDone =
        readingTested >= testable && writingTested >= testable;
    final anyStarted = readingTested > 0 || writingTested > 0;
    final Icon icon;
    if (allDone) {
      icon = const Icon(Icons.check_circle, color: Colors.green, size: 18);
    } else if (anyStarted) {
      icon = const Icon(Icons.timelapse, color: Colors.orange, size: 18);
    } else {
      icon = Icon(Icons.circle_outlined, color: Colors.grey.shade400, size: 18);
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

  Widget _compositaPie(AppLocalizations l, String label, int tested, int testable) {
    final remaining = (testable - tested).clamp(0, testable);
    return Column(
      children: [
        _PieChart(
          values: [tested.toDouble(), remaining.toDouble()],
          colors: [Colors.green, Colors.grey.shade300],
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
                colors: [Colors.grey.shade300],
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

/// Async-loaded composita dot for the kanji grid. Queries composita progress
/// for a single character and renders a colored dot: green if all eligible
/// words tested in both directions, orange if at least one tested, grey
/// otherwise.
class _CompositaDot extends StatefulWidget {
  final String character;
  final Set<String> eligibleWords;
  final ReviewRepository reviewRepo;

  const _CompositaDot({
    required this.character,
    required this.eligibleWords,
    required this.reviewRepo,
  });

  @override
  State<_CompositaDot> createState() => _CompositaDotState();
}

class _CompositaDotState extends State<_CompositaDot> {
  Color _color = Colors.grey;

  @override
  void initState() {
    super.initState();
    _loadColor();
  }

  Future<void> _loadColor() async {
    final coverage = await widget.reviewRepo.compositaProgressFor({
      widget.character: widget.eligibleWords,
    });
    if (!mounted) return;
    final Color color;
    if (coverage.testedReading >= coverage.testable &&
        coverage.testedWriting >= coverage.testable &&
        coverage.testable > 0) {
      color = Colors.green;
    } else if (coverage.testedReading > 0 || coverage.testedWriting > 0) {
      color = Colors.orange;
    } else {
      color = Colors.grey;
    }
    setState(() => _color = color);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _color,
      ),
    );
  }
}
