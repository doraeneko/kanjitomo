import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, LengthLimitingTextInputFormatter;
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_dependencies.dart';
import '../../l10n/app_localizations.dart';
import '../pro/pro_paywall_sheet.dart';
import '../review/study_scope.dart';
import '../../widgets/help_info_button.dart';

/// SharedPreferences key for how many composita words to introduce per kanji.
const maxCompositaPerKanjiKey = 'review.max_composita_per_kanji';

/// Default value for [maxCompositaPerKanjiKey] when not yet configured.
const defaultMaxCompositaPerKanji = 4;

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
  static const _compositaCounts = [2, 3, 4, 5];
  static const _maxBacklogKey = 'review.max_backlog';

  late final List<String> _allCharacters = widget.deps.kanjiInfo.characters;
  late final TextEditingController _dailyNewCapController;
  late final TextEditingController _maxBacklogController;
  int _maxCompositaPerKanji = defaultMaxCompositaPerKanji;

  @override
  void initState() {
    super.initState();
    _dailyNewCapController = TextEditingController(text: '$_defaultDailyNewCap');
    _maxBacklogController = TextEditingController(text: '0');
    _loadDailyNewCap();
    _loadMaxComposita();
    _loadMaxBacklog();
  }

  @override
  void dispose() {
    _dailyNewCapController.dispose();
    _maxBacklogController.dispose();
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

  Future<void> _loadMaxComposita() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(maxCompositaPerKanjiKey);
    if (stored != null && mounted) {
      setState(() => _maxCompositaPerKanji = stored);
    }
  }

  Future<void> _setMaxComposita(int value) async {
    setState(() => _maxCompositaPerKanji = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(maxCompositaPerKanjiKey, value);
  }

  Future<void> _loadMaxBacklog() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_maxBacklogKey);
    if (stored != null && mounted) {
      _maxBacklogController.text = '$stored';
    }
  }

  void _onMaxBacklogChanged(String text) async {
    final parsed = int.tryParse(text);
    if (parsed == null || parsed < 0) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxBacklogKey, parsed);
  }

  void _updateScope(StudyScope Function(StudyScope) transform) {
    final scope = widget.deps.studyScope.scope.value;
    widget.deps.studyScope.update(transform(scope));
  }

  static const _proGatedLevels = {1, 2, 3};

  void _toggleLevel(BuildContext context, StudyScope scope, int level) {
    final alreadySelected = scope.jlptLevels.contains(level);
    // Gate only adding Pro-only levels; removing is always allowed so users
    // with pre-existing N1-N3 selections can deselect them.
    if (!alreadySelected &&
        _proGatedLevels.contains(level) &&
        !widget.deps.proStatus.isProUnlocked.value) {
      showProPaywallSheet(context, widget.deps.purchaseService);
      return;
    }
    final levels = Set<int>.from(scope.jlptLevels);
    if (alreadySelected) {
      levels.remove(level);
    } else {
      levels.add(level);
    }
    _updateScope(
      (s) => s.copyWith(jlptLevels: levels),
    );
  }

  void _setCompositaCeiling(BuildContext context, StudyScope scope, int? ceiling) {
    // Gate only Pro-level ceilings (N1-N3); "Off" and N4/N5 are free.
    if (ceiling != null &&
        _proGatedLevels.contains(ceiling) &&
        !widget.deps.proStatus.isProUnlocked.value) {
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

  List<String> _scopeCharacters(StudyScope scope) {
    return _allCharacters.where((char) {
      final jlptLevel = widget.deps.jlptLevels.levelOf(char);
      return scope.matches(
        character: char,
        jlptLevel: jlptLevel,
        rtkIndex: null,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.jlptEditTitle),
        actions: [HelpInfoButton(helpText: l.helpJlptEdit)],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<StudyScope>(
          valueListenable: widget.deps.studyScope.scope,
          builder: (context, scope, _) {
            final characters = _scopeCharacters(scope);
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
                  Text(l.jlptEditKanjiInScope(characters.length)),
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
                  Text(
                    l.jlptEditCompositaPerKanji,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: _compositaCounts.map((count) {
                      return ChoiceChip(
                        label: Text('$count'),
                        selected: _maxCompositaPerKanji == count,
                        onSelected: (_) => _setMaxComposita(count),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Text(l.reviewStartNewKanjiPerDay)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 72,
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Text(l.reviewMaxBacklog)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 72,
                        child: TextField(
                          controller: _maxBacklogController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]+')),
                            LengthLimitingTextInputFormatter(4),
                          ],
                          onChanged: _onMaxBacklogChanged,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    l.reviewMaxBacklogHint,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  if (characters.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: characters
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
            );
          },
        ),
      ),
    );
  }
}
