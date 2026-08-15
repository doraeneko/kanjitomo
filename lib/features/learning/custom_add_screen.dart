import 'package:flutter/material.dart';

import '../../app_dependencies.dart';
import '../../core/kanji_recognizer.dart';
import '../../data/composita_repository.dart';
import '../../l10n/app_localizations.dart';
import '../kanji_browser/kanji_detail_content.dart';
import '../pro/pro_paywall_sheet.dart';
import '../review/draw_and_pick.dart';
import '../review/review_repository.dart';
import '../review/study_scope.dart';
import 'composita_picker.dart';

/// Dedicated screen for adding kanji to the custom set.
///
/// Flow: draw a kanji → pick from top-3 → kanji is added → composita
/// dialog opens automatically. The drawing canvas stays outside any
/// scrollable ancestor to avoid gesture conflicts.
class CustomAddScreen extends StatefulWidget {
  final AppDependencies deps;

  const CustomAddScreen({super.key, required this.deps});

  @override
  State<CustomAddScreen> createState() => _CustomAddScreenState();
}

class _CustomAddScreenState extends State<CustomAddScreen> {
  static const _freeCustomLimit = 56;

  bool get _isPro => widget.deps.proStatus.isProUnlocked.value;

  late final ReviewRepository _reviewRepo;
  int _drawKeyCounter = 0;
  Map<String, Set<String>> _customComposita = {};

  @override
  void initState() {
    super.initState();
    _reviewRepo = ReviewRepository(widget.deps.database);
    _loadCustomComposita(widget.deps.studyScope.scope.value);
  }

  Future<void> _loadCustomComposita(StudyScope scope) async {
    final loaded = await _reviewRepo.customCompositaForCharacters(
      scope.customCharacters,
    );
    if (mounted) setState(() => _customComposita = loaded);
  }

  static bool _isKana(String char) {
    if (char.isEmpty) return false;
    final c = char.codeUnitAt(0);
    return (c >= 0x3040 && c <= 0x309F) || (c >= 0x30A0 && c <= 0x30FF);
  }

  void _addDrawnCharacter(StudyScope scope, String char) {
    setState(() => _drawKeyCounter++);
    final l = AppLocalizations.of(context)!;
    if (_isKana(char)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.customEditIsKana(char))),
      );
      return;
    }
    if (scope.customCharacters.contains(char)) {
      // Already in set — still open the composita dialog so the user
      // can edit composita for it.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.customEditAlreadyInSet(char))),
      );
      _openCompositaDialog(scope, char);
      return;
    }
    if (!_isPro && scope.customCharacters.length >= _freeCustomLimit) {
      showProPaywallSheet(context, widget.deps.purchaseService);
      return;
    }
    final chars = Set<String>.from(scope.customCharacters)..add(char);
    widget.deps.studyScope.update(scope.copyWith(customCharacters: chars));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.customEditAdded(char))));
    _openCompositaDialog(scope, char);
  }

  Future<void> _openCompositaDialog(StudyScope scope, String char) async {
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

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.customEditAddElements)),
      body: SafeArea(
        child: ValueListenableBuilder<StudyScope>(
          valueListenable: widget.deps.studyScope.scope,
          builder: (context, scope, _) {
            return Column(
              children: [
                // ── Fixed: instruction + canvas ───────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    children: [
                      Text(
                        l.customEditDrawInstruction,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      DrawAndPickWidget(
                        key: ValueKey(_drawKeyCounter),
                        recognizer: widget.deps.recognizer,
                        onPicked: (List<Prediction> top3, String pick) =>
                            _addDrawnCharacter(scope, pick),
                      ),
                    ],
                  ),
                ),
                // ── Scrollable: kanji grid ────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        Text(
                          scope.customCharacters.isEmpty
                              ? l.customEditSetEmpty
                              : l.customEditSetInstruction,
                        ),
                        if (scope.customCharacters.isNotEmpty)
                          Text(
                            _isPro
                                ? l.customEditKanjiCountPro(
                                    scope.customCharacters.length)
                                : l.customEditKanjiCount(
                                    scope.customCharacters.length,
                                    _freeCustomLimit),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: scope.customCharacters.map((char) {
                            final compositaCount =
                                _customComposita[char]?.length ?? 0;
                            return InkWell(
                              key: ValueKey('grid-$char'),
                              onTap: () =>
                                  _openCompositaDialog(scope, char),
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
