import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_dependencies.dart';
import '../../core/db/tables.dart';
import '../../l10n/app_localizations.dart';
import '../pro/pro_paywall_sheet.dart';
import 'review_focus.dart';
import 'review_repository.dart';
import 'review_session_screen.dart';
import 'sentence_selection.dart';
import 'study_scope.dart';

/// Shown before entering a review session: summarizes the current
/// [StudyScope] (however it was set -- JLPT or custom, edited elsewhere in
/// the Learning section, see jlpt_edit_screen.dart/custom_edit_screen.dart)
/// and lets the user pick which learning axes to quiz this session ("kanji
/// only", "composita", or "both") before starting. Scope editing itself
/// no longer happens here -- this screen is shared by both JLPT and Custom
/// (it just reads whatever StudyScope currently is), so per-mode controls
/// live in their own dedicated edit screens instead.
class ReviewStartScreen extends StatefulWidget {
  final AppDependencies deps;

  const ReviewStartScreen({super.key, required this.deps});

  @override
  State<ReviewStartScreen> createState() => _ReviewStartScreenState();
}

class _ReviewStartScreenState extends State<ReviewStartScreen> {
  static const _dailyNewCapKey = 'review.daily_new_cap';
  static const _defaultDailyNewCap = 10;

  late final List<String> _allCharacters = widget.deps.kanjiInfo.characters;
  late final ReviewRepository _reviewRepo;
  ReviewFocus _focus = ReviewFocus.both;
  int _dailyNewCap = _defaultDailyNewCap;
  int? _dueCount;
  int? _seenCount;
  List<String>? _dueCharacters;
  List<String>? _newCharacters;

  @override
  void initState() {
    super.initState();
    _reviewRepo = ReviewRepository(widget.deps.database);
    _loadDailyNewCap();
    _loadDueCount();
    _loadSeenCount();
  }

  Future<void> _loadDailyNewCap() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_dailyNewCapKey);
    if (stored != null && mounted) {
      setState(() => _dailyNewCap = stored);
    }
  }

  Future<void> _loadDueCount() async {
    final scope = widget.deps.studyScope.scope.value;
    final types = cardTypesForFocus(_focus);
    final count = await _reviewRepo.countDueCards(
      scope,
      cardTypes: types,
    );
    final chars = await _reviewRepo.dueCharacters(
      scope,
      cardTypes: types,
    );
    // When nothing is due, preview which new kanji would be introduced.
    // drawFromMeaning (A) is the entry-point card type -- B/C/D require
    // passing earlier stages first, so preview always shows A candidates.
    List<String>? newChars;
    if (count == 0) {
      newChars = await _reviewRepo.previewIntroducible(
        scope,
        CardType.drawFromMeaning,
        limit: _dailyNewCap,
      );
    }
    if (mounted) {
      setState(() {
        _dueCount = count;
        _dueCharacters = chars;
        _newCharacters = newChars;
      });
    }
  }

  Future<void> _loadSeenCount() async {
    final scope = widget.deps.studyScope.scope.value;
    final seen = await _reviewRepo.countSeenCharacters(scope);
    if (mounted) setState(() => _seenCount = seen);
  }

  static const _proGatedJlptLevels = {1, 2, 3};

  bool get _isPro => widget.deps.proStatus.isProUnlocked.value;

  bool _scopeNeedsPro(StudyScope scope) {
    if (_isPro) return false;
    if (scope.mode == StudyScopeMode.jlpt &&
        scope.jlptLevels.any(_proGatedJlptLevels.contains)) {
      return true;
    }
    return false;
  }

  void _setFocus(ReviewFocus focus) {
    if (!_isPro && focus != ReviewFocus.core) {
      showProPaywallSheet(context, widget.deps.purchaseService);
      return;
    }
    setState(() {
      _focus = focus;
      _dueCount = null; // stale until the recount lands
      _dueCharacters = null;
      _newCharacters = null;
    });
    _loadDueCount();
  }

  List<String> _scopeCharacters(StudyScope scope) {
    return _allCharacters.where((char) {
      final jlptLevel = widget.deps.jlptLevels.levelOf(char);
      final rtkIndex = widget.deps.rtkIndex.indexOf(char);
      final levelRank = widget.deps.kanjiLevelRank.rankOf(char);
      return scope.matches(
        character: char,
        jlptLevel: jlptLevel,
        rtkIndex: rtkIndex,
        levelRank: levelRank,
      );
    }).toList();
  }

  String _dueCountText(AppLocalizations l, int? dueCount) {
    if (dueCount == null) return l.reviewStartCountingDue;
    return l.reviewStartDueNow(dueCount);
  }

  String _describeScope(AppLocalizations l, StudyScope scope) {
    switch (scope.mode) {
      case StudyScopeMode.custom:
        return scope.customCharacters.isEmpty
            ? l.reviewStartCustomSetEmpty
            : l.reviewStartCustomSet;
      case StudyScopeMode.rtk:
        return l.reviewStartRtk(scope.rtkMaxIndex);
      case StudyScopeMode.jlpt:
        if (scope.isEmpty) return l.reviewStartNothingSelected;
        final levels = scope.jlptLevels.toList()..sort();
        return 'N${levels.join(', N')}';
    }
  }

  void _startReview() async {
    final scope = widget.deps.studyScope.scope.value;
    if (_scopeNeedsPro(scope)) {
      showProPaywallSheet(context, widget.deps.purchaseService);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewSessionScreen(
          deps: widget.deps,
          focus: _focus,
        ),
      ),
    );
    // Refresh counts when coming back from a completed session.
    if (mounted) {
      _loadDueCount();
      _loadSeenCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.reviewStartTitle)),
      body: SafeArea(
        child: ValueListenableBuilder<StudyScope>(
          valueListenable: widget.deps.studyScope.scope,
          builder: (context, scope, _) {
            final characters = _scopeCharacters(scope);
            final compositaOff =
                _focus != ReviewFocus.core && !compositaEnabled(scope);
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
                          Text(_describeScope(l, scope)),
                          const SizedBox(height: 4),
                          Text(l.reviewStartKanjiInScope(characters.length)),
                          if (_seenCount != null)
                            Text(l.reviewStartSeen(
                              _seenCount!,
                              characters.length - _seenCount!,
                            )),
                          Text(_dueCountText(l, _dueCount)),
                          if (_dueCharacters != null &&
                              _dueCharacters!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _dueCharacters!
                                  .map(
                                    (char) => Text(
                                      char,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                          if (_newCharacters != null &&
                              _newCharacters!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _newCharacters!
                                  .map(
                                    (char) => Text(
                                      char,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l.reviewStartWhatToQuiz,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<ReviewFocus>(
                    segments: [
                      ButtonSegment(
                        value: ReviewFocus.core,
                        label: Text(l.reviewStartKanjiOnly),
                      ),
                      ButtonSegment(
                        value: ReviewFocus.composita,
                        label: Text(l.reviewStartComposita),
                      ),
                      ButtonSegment(
                        value: ReviewFocus.both,
                        label: Text(l.reviewStartBoth),
                      ),
                    ],
                    selected: {_focus},
                    onSelectionChanged: (s) => _setFocus(s.first),
                  ),
                  if (compositaOff) ...[
                    const SizedBox(height: 8),
                    Text(
                      l.reviewStartCompositaOff,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Center(
                    child: ElevatedButton(
                      onPressed: scope.isEmpty ? null : _startReview,
                      child: Text(
                        _dueCount != null && _dueCount == 0
                            ? l.reviewStartLearnNew(_dailyNewCap)
                            : _dueCount != null && _dueCount! > 0
                                ? l.reviewContinueButton
                                : l.reviewStartButton,
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
}
