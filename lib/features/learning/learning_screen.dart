import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_dependencies.dart';
import '../../l10n/app_localizations.dart';
import '../quiz/quiz_start_screen.dart';
import '../review/review_repository.dart';
import '../review/review_session_screen.dart';
import '../review/statistics_screen.dart';
import '../review/study_scope.dart';
import 'add_remove_screen.dart';
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

  late final ReviewRepository _reviewRepo;
  Timer? _refreshTimer;
  int? _seenCount;
  int? _dueCount;
  int? _waitingCount;
  List<String>? _dueCharacters;
  Map<String, int>? _dueDist;
  Map<String, DateTime> _addedDates = {};

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
    final seen = await _reviewRepo.countSeenCharacters(scope);
    final totalDue = await _reviewRepo.countDueCards(scope);
    final neverReviewed = await _reviewRepo.cardsNeverReviewed(scope);
    final neverReviewedCount = neverReviewed.length;
    final reviewDue = totalDue - neverReviewedCount; // already-reviewed due

    // Subtract cards already reviewed today from the daily budget.
    final reviewedToday = await _reviewRepo.countReviewedToday();
    final dailyBudget = _maxReviewsPerDay <= 0
        ? reviewDue + neverReviewedCount
        : (_maxReviewsPerDay - reviewedToday).clamp(0, _maxReviewsPerDay);
    final cappedReviews = _maxReviewsPerDay <= 0
        ? reviewDue
        : reviewDue.clamp(0, dailyBudget);
    // New cards fill remaining capacity after reviews.
    final remainingBudget = _maxReviewsPerDay <= 0
        ? (_newCardsPerSession <= 0 ? neverReviewedCount : _newCardsPerSession)
        : (dailyBudget - cappedReviews).clamp(0, dailyBudget);
    final newCardCap = _newCardsPerSession <= 0
        ? remainingBudget
        : remainingBudget.clamp(0, _newCardsPerSession);
    final cappedNew = neverReviewedCount.clamp(0, newCardCap);
    final effectiveDue = cappedReviews + cappedNew;
    final waiting = neverReviewedCount - cappedNew;

    final chars = await _reviewRepo.dueCharacters(scope);
    final dist = await _reviewRepo.dueDateDistribution(scope);
    final added = await _reviewRepo.addedDates();
    if (mounted) {
      setState(() {
        _seenCount = seen;
        _dueCount = effectiveDue;
        _waitingCount = waiting;
        _dueCharacters = chars;
        _dueDist = dist;
        _addedDates = added;
      });
    }
  }

  List<String> _sortedPool(StudyScope scope) {
    final pool = scope.characters.toList();
    pool.sort((a, b) {
      final da = _addedDates[a];
      final db = _addedDates[b];
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db); // oldest first
    });
    return pool;
  }

  String _dueCountText(AppLocalizations l, int? dueCount) {
    if (dueCount == null) return l.reviewStartCountingDue;
    if (dueCount == 0) return l.reviewNoCardsDue;
    return l.reviewStartDueNow(dueCount);
  }

  void _updateCompositaCeiling(int? ceiling) {
    final scope = widget.deps.studyScope.scope.value;
    widget.deps.studyScope.update(
      scope.copyWith(
        compositaCeiling: ceiling,
        clearCompositaCeiling: ceiling == null,
      ),
    );
    setState(() {});
  }

  void _updateMaxComposita(int max) {
    final scope = widget.deps.studyScope.scope.value;
    widget.deps.studyScope.update(
      scope.copyWith(maxCompositaPerKanji: max),
    );
    setState(() {});
  }

  // ── Navigation ─────────────────────────────────────────────────────

  void _openReview(BuildContext context) {
    final scope = widget.deps.studyScope.scope.value;
    if (scope.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReviewSessionScreen(deps: widget.deps)),
    ).then((_) => _loadCounts());
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
                    onPressed: () => _openReview(context),
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
                    onPressed: () => _openQuiz(context),
                    icon: const Icon(Icons.quiz),
                    label: Text(
                      l.learningQuiz,
                      style: const TextStyle(fontSize: 18),
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
                                  color: Colors.grey.shade600,
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
                              color: Colors.grey.shade600,
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
                              width: 56,
                              height: 32,
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
                              width: 56,
                              height: 32,
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
                        const SizedBox(height: 12),
                        const Divider(),
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
                if (charCount > 0) ...[
                  const SizedBox(height: 24),
                  Text(
                    l.reviewStartPoolHeading(charCount),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: _sortedPool(scope).map((char) {
                      final isDue = _dueCharacters?.contains(char) ?? false;
                      return Text(
                        char,
                        style: TextStyle(
                          fontSize: 22,
                          color: isDue ? null : Colors.grey.shade400,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

}
