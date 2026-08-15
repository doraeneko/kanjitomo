import 'package:flutter/material.dart';

import '../../app_dependencies.dart';
import '../../l10n/app_localizations.dart';
import 'review_repository.dart';
import 'review_session_screen.dart';
import 'study_scope.dart';
import '../../widgets/help_info_button.dart';

/// Pre-review summary: shows scope stats (kanji count, seen/unseen, due
/// count, due character preview) and a Start button. No daily cap logic,
/// no "Add new kanji?" dialog -- kanji are added explicitly via the
/// Add/Remove screen, and cards are created at add-time.
class ReviewStartScreen extends StatefulWidget {
  final AppDependencies deps;

  const ReviewStartScreen({super.key, required this.deps});

  @override
  State<ReviewStartScreen> createState() => _ReviewStartScreenState();
}

class _ReviewStartScreenState extends State<ReviewStartScreen> {
  late final ReviewRepository _reviewRepo;

  int? _dueCount;
  int? _seenCount;
  List<String>? _dueCharacters;
  Map<String, int>? _dueDist;
  Map<String, DateTime> _addedDates = {};

  @override
  void initState() {
    super.initState();
    _reviewRepo = ReviewRepository(widget.deps.database);
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final scope = widget.deps.studyScope.scope.value;
    final count = await _reviewRepo.countDueCards(scope);
    final chars = await _reviewRepo.dueCharacters(scope);
    final dist = await _reviewRepo.dueDateDistribution(scope);
    final seen = await _reviewRepo.countSeenCharacters(scope);
    final added = await _reviewRepo.addedDates();
    if (mounted) {
      setState(() {
        _dueCount = count;
        _dueCharacters = chars;
        _dueDist = dist;
        _seenCount = seen;
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

  void _startReview() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewSessionScreen(deps: widget.deps),
      ),
    );
    if (mounted) _loadCounts();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.reviewStartTitle),
        actions: [HelpInfoButton(helpText: l.helpReviewStart)],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<StudyScope>(
          valueListenable: widget.deps.studyScope.scope,
          builder: (context, scope, _) {
            final charCount = scope.characters.length;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.reviewStartCurrentSelection,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(l.reviewStartKanjiInScope(charCount)),
                          if (_seenCount != null)
                            Text(l.reviewStartSeen(
                              _seenCount!,
                              charCount - _seenCount!,
                            )),
                          Text(_dueCountText(l, _dueCount)),
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: ElevatedButton(
                      onPressed: scope.isEmpty ? null : _startReview,
                      child: Text(l.reviewStartButton),
                    ),
                  ),
                  if (charCount > 0) ...[
                    const SizedBox(height: 32),
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
              ),
            );
          },
        ),
      ),
    );
  }
}
