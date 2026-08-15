import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, LengthLimitingTextInputFormatter;
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_dependencies.dart';
import '../../data/composita_repository.dart';
import '../../l10n/app_localizations.dart';
import '../kanji_browser/kanji_detail_content.dart';
import '../review/review_repository.dart';
import '../review/study_scope.dart';
import 'composita_picker.dart';
import 'custom_add_screen.dart';
import '../../widgets/help_info_button.dart';

/// Edits the custom-mode [StudyScope]: review settings (focus, daily cap),
/// kanji grid (tap to edit composita, long-press to remove), clear button,
/// and an "Add elements" button that navigates to [CustomAddScreen].
class CustomEditScreen extends StatefulWidget {
  final AppDependencies deps;

  const CustomEditScreen({super.key, required this.deps});

  @override
  State<CustomEditScreen> createState() => _CustomEditScreenState();
}

class _CustomEditScreenState extends State<CustomEditScreen> {
  static const _dailyNewCapKey = 'review.daily_new_cap';
  static const _defaultDailyNewCap = 10;
  static const _minDailyNewCap = 1;
  static const _maxDailyNewCap = 999;
  static const _freeCustomLimit = 56;

  bool get _isPro => widget.deps.proStatus.isProUnlocked.value;

  static const _maxBacklogKey = 'review.max_backlog';

  late final ReviewRepository _reviewRepo;
  late final TextEditingController _dailyNewCapController;
  late final TextEditingController _maxBacklogController;
  Map<String, Set<String>> _customComposita = {};

  @override
  void initState() {
    super.initState();
    _reviewRepo = ReviewRepository(widget.deps.database);
    _dailyNewCapController = TextEditingController(text: '$_defaultDailyNewCap');
    _maxBacklogController = TextEditingController(text: '0');
    _loadDailyNewCap();
    _loadMaxBacklog();
    _loadCustomComposita(widget.deps.studyScope.scope.value);
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

  void _onDailyNewCapChanged(String text) async {
    final parsed = int.tryParse(text);
    if (parsed == null || parsed < _minDailyNewCap || parsed > _maxDailyNewCap) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyNewCapKey, parsed);
  }

  Future<void> _loadCustomComposita(StudyScope scope) async {
    final loaded = await _reviewRepo.customCompositaForCharacters(
      scope.customCharacters,
    );
    if (mounted) setState(() => _customComposita = loaded);
  }

  Future<void> _confirmRemoveCharacter(StudyScope scope, String char) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.customEditRemoveDialogTitle(char)),
        content: Text(l.customEditRemoveDialogContent(char)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.dialogCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.dialogRemove),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final chars = Set<String>.from(scope.customCharacters)..remove(char);
      widget.deps.studyScope.update(scope.copyWith(customCharacters: chars));
    }
  }

  Future<void> _confirmClear(StudyScope scope) async {
    final count = scope.customCharacters.length;
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.customEditClearDialogTitle),
        content: Text(l.customEditClearDialogContent(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.dialogCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.dialogClear),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      widget.deps.studyScope.update(scope.copyWith(customCharacters: {}));
    }
  }

  Future<void> _openKanjiDialog(StudyScope scope, String char) async {
    final all = rankComposita(widget.deps.composita.lookup(char));
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CompositaPicker(
                    character: char,
                    composita: all,
                    reviewRepo: _reviewRepo,
                    wordIndex: widget.deps.wordIndex,
                    recognizer: widget.deps.recognizer,
                  ),
                  const Divider(height: 32),
                  KanjiDetailContent(
                    character: char,
                    deps: widget.deps,
                    scrollable: false,
                    compact: true,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    _loadCustomComposita(widget.deps.studyScope.scope.value);
  }

  Future<void> _openAddScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomAddScreen(deps: widget.deps),
      ),
    );
    // Refresh composita counts after returning from the add screen.
    _loadCustomComposita(widget.deps.studyScope.scope.value);
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.customEditTitle),
        actions: [
          HelpInfoButton(helpText: l.helpCustomEdit),
          ValueListenableBuilder<StudyScope>(
            valueListenable: widget.deps.studyScope.scope,
            builder: (context, scope, _) => TextButton(
              onPressed: scope.customCharacters.isEmpty
                  ? null
                  : () => _confirmClear(scope),
              child: Text(l.customEditClear),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<StudyScope>(
          valueListenable: widget.deps.studyScope.scope,
          builder: (context, scope, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── "Add elements" button ─────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openAddScreen,
                      icon: const Icon(Icons.add),
                      label: Text(l.customEditAddElements),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ── Daily new cap ─────────────────────────
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
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[1-9][0-9]*'),
                            ),
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
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9]+'),
                            ),
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
                  // ── Kanji grid ────────────────────────────
                  const SizedBox(height: 8),
                  const Divider(),
                  Text(
                    scope.customCharacters.isEmpty
                        ? l.customEditSetEmpty
                        : l.customEditSetInstruction,
                  ),
                  if (scope.customCharacters.isNotEmpty)
                    Text(
                      _isPro
                          ? l.customEditKanjiCountPro(scope.customCharacters.length)
                          : l.customEditKanjiCount(scope.customCharacters.length, _freeCustomLimit),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: scope.customCharacters.map((char) {
                      final compositaCount =
                          _customComposita[char]?.length ?? 0;
                      return InkWell(
                        key: ValueKey('remove-$char'),
                        onTap: () => _openKanjiDialog(scope, char),
                        onLongPress: () =>
                            _confirmRemoveCharacter(scope, char),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade400,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(
                                char,
                                style: const TextStyle(fontSize: 20),
                              ),
                              if (compositaCount > 0)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo,
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$compositaCount',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
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
          },
        ),
      ),
    );
  }
}
