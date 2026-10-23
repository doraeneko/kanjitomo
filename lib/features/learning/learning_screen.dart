import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_dependencies.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../quiz/quiz_start_screen.dart';
import '../../core/db/tables.dart';
import '../review/review_repository.dart';
import '../review/review_session_screen.dart';
import '../review/statistics_screen.dart';
import '../review/study_scope.dart';
import 'add_remove_screen.dart';
import 'review_type_sheet.dart';
import '../../widgets/coffee_button.dart';
import '../../widgets/help_info_button.dart';

/// Learning hub. Shows pool stats, composita settings, the learning pool
/// with due-highlighting, and action buttons for Review, Add/Remove, Quiz,
/// and Statistics.
class LearningScreen extends StatefulWidget {
  final AppDependencies deps;

  const LearningScreen({super.key, required this.deps});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  static const _newCardsPerSessionKey = 'review.new_cards_per_session';
  static const _maxReviewsPerDayKey = 'review.max_reviews_per_day';
  static const _reviewCardTypesKey = 'review.card_types';
  static const _newCardOrderKey = 'review.new_card_order';

  late final ReviewRepository _reviewRepo;
  Timer? _refreshTimer;
  int? _seenCount;
  int? _dueCount;
  int? _waitingCount;
  Map<String, int>? _dueDist;

  int _newCardsPerSession = 30;
  int _maxReviewsPerDay = 200;

  @override
  void initState() {
    super.initState();
    _reviewRepo = ReviewRepository(widget.deps.database);
    widget.deps.studyScope.scope.addListener(_onScopeChanged);
    _loadCounts();
    _loadPrefs();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadCounts(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    widget.deps.studyScope.scope.removeListener(_onScopeChanged);
    super.dispose();
  }

  void _onScopeChanged() => _loadCounts();

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _newCardsPerSession = prefs.getInt(_newCardsPerSessionKey) ?? 30;
        _maxReviewsPerDay = prefs.getInt(_maxReviewsPerDayKey) ?? 200;
      });
    }
  }

  Future<void> _loadCounts() async {
    final scope = widget.deps.studyScope.scope.value;
    final results = await Future.wait([
      _reviewRepo.countSeenCharacters(scope),       // 0
      _reviewRepo.countDueCards(scope),              // 1
      _reviewRepo.countNeverReviewed(scope),         // 2
      _reviewRepo.countReviewedToday(),              // 3
      _reviewRepo.dueDateDistribution(scope),        // 4
    ]);
    final seen = results[0] as int;
    final totalDue = results[1] as int;
    final neverReviewedCount = results[2] as int;
    final reviewDue = totalDue - neverReviewedCount;
    final reviewedToday = results[3] as int;

    final dailyBudget = _maxReviewsPerDay <= 0
        ? reviewDue + neverReviewedCount
        : (_maxReviewsPerDay - reviewedToday).clamp(0, _maxReviewsPerDay);
    final cappedReviews = _maxReviewsPerDay <= 0
        ? reviewDue
        : reviewDue.clamp(0, dailyBudget);
    final remainingBudget = _maxReviewsPerDay <= 0
        ? (_newCardsPerSession <= 0 ? neverReviewedCount : _newCardsPerSession)
        : (dailyBudget - cappedReviews).clamp(0, dailyBudget);
    final newCardCap = _newCardsPerSession <= 0
        ? remainingBudget
        : remainingBudget.clamp(0, _newCardsPerSession);
    final cappedNew = neverReviewedCount.clamp(0, newCardCap);
    final effectiveDue = cappedReviews + cappedNew;
    final waiting = neverReviewedCount - cappedNew;

    final dist = results[4] as Map<String, int>;
    if (mounted) {
      setState(() {
        _seenCount = seen;
        _dueCount = effectiveDue;
        _waitingCount = waiting;
        _dueDist = dist;
      });
    }
  }

  String _dueCountText(AppLocalizations l, int? dueCount) {
    if (dueCount == null) return l.reviewStartCountingDue;
    if (dueCount == 0) return l.reviewNoCardsDue;
    return l.reviewStartDueNow(dueCount);
  }

  // ── Navigation ─────────────────────────────────────────────────────

  Future<void> _openReview(BuildContext context) async {
    final scope = widget.deps.studyScope.scope.value;
    if (scope.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_reviewCardTypesKey);
    final initial = saved == null
        ? CardType.values.toSet()
        : CardType.values.where((t) => saved.contains(t.name)).toSet();
    final savedOrder = prefs.getString(_newCardOrderKey);
    final initialOrder = NewCardOrder.values.firstWhere(
      (o) => o.name == savedOrder,
      orElse: () => NewCardOrder.rtk,
    );
    if (!context.mounted) return;

    final options = await showModalBottomSheet<ReviewSessionOptions>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => ReviewTypeSheet(
        initial: initial.isEmpty ? CardType.values.toSet() : initial,
        initialOrder: initialOrder,
        dueCounts: _loadDueCountsByType(scope),
      ),
    );
    if (options == null || options.cardTypes.isEmpty || !context.mounted) {
      return;
    }
    final selected = options.cardTypes;
    await prefs.setStringList(
      _reviewCardTypesKey,
      [for (final t in selected) t.name],
    );
    await prefs.setString(_newCardOrderKey, options.newCardOrder.name);
    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewSessionScreen(
          deps: widget.deps,
          // All kinds selected = unfiltered session.
          cardTypes: selected.length == CardType.values.length ? null : selected,
          newCardOrder: options.newCardOrder,
        ),
      ),
    ).then((_) => _loadCounts());
  }

  Future<Map<CardType, int>> _loadDueCountsByType(StudyScope scope) async {
    final counts = await Future.wait([
      for (final t in CardType.values)
        _reviewRepo.countDueCards(scope, cardTypes: {t}),
    ]);
    return {
      for (var i = 0; i < CardType.values.length; i++)
        CardType.values[i]: counts[i],
    };
  }

  void _openAddRemove(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddRemoveScreen(deps: widget.deps)),
    ).then((_) => _loadCounts());
  }

  void _openQuiz(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => QuizStartScreen(deps: widget.deps)),
    );
  }

  void _openStatistics(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StatisticsScreen(deps: widget.deps)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.learningTitle),
        actions: [
          HelpInfoButton(helpText: l.helpLearning),
          const CoffeeButton(),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<StudyScope>(
          valueListenable: widget.deps.studyScope.scope,
          builder: (context, scope, _) {
            final charCount = scope.characters.length;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Review button — prominent, top of page
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    key: const ValueKey('review'),
                    onPressed: charCount > 0 ? () => _openReview(context) : null,
                    icon: const Icon(Icons.play_circle_filled),
                    label: Text(
                      _dueCount != null && _dueCount! > 0
                          ? '${l.learningReview} (${_dueCount})'
                          : l.learningReview,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Quiz button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    key: const ValueKey('quiz'),
                    onPressed: charCount > 0 ? () => _openQuiz(context) : null,
                    icon: const Icon(Icons.quiz),
                    label: Text(
                      l.learningQuiz,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                if (charCount == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l.learningEmptyPoolHint,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.appColors.textTertiary,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    key: const ValueKey('add-remove'),
                    onPressed: () => _openAddRemove(context),
                    icon: const Icon(Icons.library_add),
                    label: Text(
                      l.learningAddRemove,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Stats card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.learningKanjiCount(charCount)),
                        if (_seenCount != null)
                          Text(l.reviewStartSeen(
                            _seenCount!,
                            charCount - _seenCount!,
                          )),
                        Text.rich(TextSpan(
                          children: [
                            TextSpan(text: _dueCountText(l, _dueCount)),
                            if (_waitingCount != null && _waitingCount! > 0)
                              TextSpan(
                                text: ' · ${l.learningWaitingCards(_waitingCount!)}',
                                style: TextStyle(
                                  color: context.appColors.textTertiary,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        )),
                        if (_dueDist != null &&
                            (_dueDist!['tomorrow']! > 0 ||
                             _dueDist!['thisWeek']! > 0 ||
                             _dueDist!['later']! > 0))
                          Text(
                            l.dueOverviewCompact(
                              _dueDist!['tomorrow']!,
                              _dueDist!['thisWeek']!,
                              _dueDist!['later']!,
                            ),
                            style: TextStyle(
                              color: context.appColors.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              l.learningNewCardsPerDay,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 64,
                              height: 40,
                              child: TextField(
                                key: const ValueKey('new-cards-per-session'),
                                controller: TextEditingController(
                                  text: _newCardsPerSession == 0
                                      ? '∞'
                                      : '$_newCardsPerSession',
                                ),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 14),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 6,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                onSubmitted: (v) async {
                                  final n = int.tryParse(v) ?? 30;
                                  final clamped = n < 0 ? 0 : n;
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setInt(
                                      _newCardsPerSessionKey, clamped);
                                  if (mounted) {
                                    setState(
                                        () => _newCardsPerSession = clamped);
                                    _loadCounts();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              l.learningMaxReviewsPerDay,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 64,
                              height: 40,
                              child: TextField(
                                key: const ValueKey('max-reviews-per-day'),
                                controller: TextEditingController(
                                  text: _maxReviewsPerDay == 0
                                      ? '∞'
                                      : '$_maxReviewsPerDay',
                                ),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 14),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 6,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                onSubmitted: (v) async {
                                  final n = int.tryParse(v) ?? 200;
                                  final clamped = n < 0 ? 0 : n;
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setInt(
                                      _maxReviewsPerDayKey, clamped);
                                  if (mounted) {
                                    setState(
                                        () => _maxReviewsPerDay = clamped);
                                    _loadCounts();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            l.learningSettingsUnlimitedHint,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.appColors.textTertiary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            key: const ValueKey('statistics'),
                            onPressed: () => _openStatistics(context),
                            icon: const Icon(Icons.bar_chart),
                            label: Text(l.learningStatistics),
                          ),
                        ),
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
