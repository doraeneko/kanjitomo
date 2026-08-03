import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../app_dependencies.dart';
import '../../core/db/tables.dart';
import '../../data/composita_repository.dart';
import '../../l10n/app_localizations.dart';
import 'review_repository.dart';
import 'sentence_selection.dart';
import 'study_scope.dart';

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

  @override
  void initState() {
    super.initState();
    _reviewRepo = ReviewRepository(widget.deps.database);
    _load();
  }

  Set<String> _scopeCharacters(StudyScope scope) {
    return widget.deps.kanjiInfo.characters.where((char) {
      final jlptLevel = widget.deps.jlptLevels.levelOf(char);
      final rtkIndex = widget.deps.rtkIndex.indexOf(char);
      final levelRank = widget.deps.kanjiLevelRank.rankOf(char);
      return scope.matches(
        character: char,
        jlptLevel: jlptLevel,
        rtkIndex: rtkIndex,
        levelRank: levelRank,
      );
    }).toSet();
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
      final customComposita = scope.mode == StudyScopeMode.custom
          ? await _reviewRepo.customCompositaForCharacters(characters)
          : const <String, Set<String>>{};
      final userComposita = await _reviewRepo.allUserCompositaByChar();
      for (final char in characters) {
        final bundled = widget.deps.composita.lookup(char);
        final userAdded = userComposita[char];
        final merged = _mergeComposita(bundled, userAdded);
        final eligible = eligibleComposita(
          merged,
          scope,
          customComposita[char] ?? const {},
        );
        if (eligible.isNotEmpty) {
          wordsByCharacter[char] = eligible.map((c) => c.word).toSet();
        }
      }
    }
    final compositaCoverage = await _reviewRepo.compositaProgressFor(
      wordsByCharacter,
    );

    if (!mounted) return;
    setState(() {
      _stats = stats;
      _compositaCoverage = compositaCoverage;
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
      appBar: AppBar(title: Text(l.statisticsTitle)),
      body: stats == null || composita == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final cardType in CardType.values)
                      _buildRow(l, _label(l, cardType), stats[cardType]!),
                    _buildCompositaRow(l, composita),
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
                colors: [Colors.green, Colors.red, Colors.grey.shade400],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendRow(l, l.statisticsKnown, s.known, Colors.green, total),
                    _legendRow(l, l.statisticsMissed, s.missed, Colors.red, total),
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
