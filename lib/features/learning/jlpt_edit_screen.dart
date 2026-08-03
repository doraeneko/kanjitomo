import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, LengthLimitingTextInputFormatter;
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_dependencies.dart';
import '../../l10n/app_localizations.dart';
import '../pro/pro_paywall_sheet.dart';
import '../review/study_scope.dart';

/// Edits a JLPT-mode [StudyScope]: which level(s) are in scope and the
/// composita/sentence ceiling (how hard a composita word is allowed to be
/// before it's excluded from C+D testing, independent of which kanji
/// levels are selected -- see StudyScope.compositaCeiling). Assumes the
/// caller (LearningScreen) has already put the scope into jlpt mode; RTK
/// isn't offered here at all, per the "hide RTK from new UI" decision.
class JlptEditScreen extends StatefulWidget {
  final AppDependencies deps;

  const JlptEditScreen({super.key, required this.deps});

  @override
  State<JlptEditScreen> createState() => _JlptEditScreenState();
}

class _JlptEditScreenState extends State<JlptEditScreen> {
  static const _dailyNewCapKey = 'review.daily_new_cap';
  static const _defaultDailyNewCap = 10;
  static const _minDailyNewCap = 1;
  static const _maxDailyNewCap = 999;

  late final List<String> _allCharacters = widget.deps.kanjiInfo.characters;
  late final TextEditingController _dailyNewCapController;

  @override
  void initState() {
    super.initState();
    _dailyNewCapController = TextEditingController(text: '$_defaultDailyNewCap');
    _loadDailyNewCap();
  }

  @override
  void dispose() {
    _dailyNewCapController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyNewCap() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_dailyNewCapKey);
    if (stored != null && mounted) {
      _dailyNewCapController.text = '$stored';
    }
  }

  void _onDailyNewCapChanged(String text) async {
    final parsed = int.tryParse(text);
    if (parsed == null || parsed < _minDailyNewCap || parsed > _maxDailyNewCap) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyNewCapKey, parsed);
  }

  void _updateScope(StudyScope Function(StudyScope) transform) {
    final scope = widget.deps.studyScope.scope.value;
    widget.deps.studyScope.update(transform(scope));
  }

  static const _proGatedLevels = {1, 2, 3};

  void _toggleLevel(BuildContext context, StudyScope scope, int level) {
    if (_proGatedLevels.contains(level) &&
        !widget.deps.proStatus.isProUnlocked.value) {
      showProPaywallSheet(context, widget.deps.purchaseService);
      return;
    }
    final levels = Set<int>.from(scope.jlptLevels);
    if (!levels.add(level)) levels.remove(level);
    _updateScope(
      (s) => s.copyWith(jlptLevels: levels),
    );
  }

  void _setCompositaCeiling(BuildContext context, StudyScope scope, int? ceiling) {
    if (!widget.deps.proStatus.isProUnlocked.value) {
      showProPaywallSheet(context, widget.deps.purchaseService);
      return;
    }
    _updateScope(
      (s) => s.copyWith(
        compositaCeiling: ceiling,
        clearCompositaCeiling: ceiling == null,
      ),
    );
  }

  int _scopeCharacterCount(StudyScope scope) {
    return _allCharacters.where((char) {
      final jlptLevel = widget.deps.jlptLevels.levelOf(char);
      return scope.matches(
        character: char,
        jlptLevel: jlptLevel,
        rtkIndex: null,
      );
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.jlptEditTitle)),
      body: SafeArea(
        child: ValueListenableBuilder<StudyScope>(
          valueListenable: widget.deps.studyScope.scope,
          builder: (context, scope, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.jlptEditLevels,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (var level = 1; level <= 5; level++)
                        FilterChip(
                          label: Text('N$level'),
                          selected: scope.jlptLevels.contains(level),
                          onSelected: (_) => _toggleLevel(context, scope, level),
                        ),
                    ],
                  ),
                  Text(l.jlptEditKanjiInScope(_scopeCharacterCount(scope))),
                  const SizedBox(height: 24),
                  Text(
                    l.jlptEditCompositaCeiling,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.jlptEditCompositaCeilingDescription,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      ChoiceChip(
                        label: Text(l.jlptEditCeilingOff),
                        selected: scope.compositaCeiling == null,
                        onSelected: (_) => _setCompositaCeiling(context, scope, null),
                      ),
                      for (var level = 1; level <= 5; level++)
                        ChoiceChip(
                          label: Text('N$level'),
                          selected: scope.compositaCeiling == level,
                          onSelected: (_) =>
                              _setCompositaCeiling(context, scope, level),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(l.reviewStartNewKanjiPerDay),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: _dailyNewCapController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[1-9][0-9]*')),
                            LengthLimitingTextInputFormatter(3),
                          ],
                          onChanged: _onDailyNewCapChanged,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
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
