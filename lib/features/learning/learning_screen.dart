import 'package:flutter/material.dart';

import '../../app_dependencies.dart';
import '../../l10n/app_localizations.dart';
import '../pro/pro_paywall_sheet.dart';
import '../review/review_start_screen.dart';
import '../review/statistics_screen.dart';
import '../review/study_scope.dart';
import 'custom_edit_screen.dart';
import 'jlpt_edit_screen.dart';

/// Entry point for the two study workflows -- JLPT (level-based) and
/// Custom (hand-picked) -- each offering Review / Edit / Statistics. RTK
/// isn't offered here at all (hidden from every new/reworked screen per
/// the "hide RTK, keep the code" decision; its data and card-scheduling
/// code still exist, just unreachable from this screen). Review/Edit both
/// first put [StudyScope] into the matching mode before navigating, since
/// [ReviewStartScreen]/[JlptEditScreen]/[CustomEditScreen] all just read
/// whatever the current scope is rather than taking a mode parameter.
class LearningScreen extends StatelessWidget {
  static const _proGatedJlptLevels = {1, 2, 3};

  final AppDependencies deps;

  const LearningScreen({super.key, required this.deps});

  bool _jlptScopeNeedsPro() {
    final scope = deps.studyScope.scope.value;
    return scope.jlptLevels.any(_proGatedJlptLevels.contains);
  }

  bool _needsProGate(StudyScopeMode mode, {bool forStatistics = false}) {
    if (deps.proStatus.isProUnlocked.value) return false;
    if (mode == StudyScopeMode.jlpt && _jlptScopeNeedsPro()) return true;
    if (forStatistics) return true;
    return false;
  }

  Future<void> _ensureMode(StudyScopeMode mode) async {
    final current = deps.studyScope.scope.value;
    if (current.mode != mode) {
      await deps.studyScope.update(current.copyWith(mode: mode));
    }
  }

  Future<void> _openReview(BuildContext context, StudyScopeMode mode) async {
    if (_needsProGate(mode)) {
      showProPaywallSheet(context, deps.purchaseService);
      return;
    }
    await _ensureMode(mode);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReviewStartScreen(deps: deps)),
    );
  }

  Future<void> _openEdit(BuildContext context, StudyScopeMode mode) async {
    if (mode == StudyScopeMode.jlpt && _needsProGate(mode)) {
      showProPaywallSheet(context, deps.purchaseService);
      return;
    }
    await _ensureMode(mode);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => mode == StudyScopeMode.jlpt
            ? JlptEditScreen(deps: deps)
            : CustomEditScreen(deps: deps),
      ),
    );
  }

  Future<void> _openStatistics(BuildContext context, StudyScopeMode mode) async {
    if (_needsProGate(mode, forStatistics: true)) {
      showProPaywallSheet(context, deps.purchaseService);
      return;
    }
    await _ensureMode(mode);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StatisticsScreen(deps: deps)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.learningTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section(context, l, title: l.learningCustom, mode: StudyScopeMode.custom),
            const SizedBox(height: 16),
            _section(context, l, title: l.learningJlpt, mode: StudyScopeMode.jlpt),
          ],
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context,
    AppLocalizations l, {
    required String title,
    required StudyScopeMode mode,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    key: ValueKey('$title-review'),
                    onPressed: () => _openReview(context, mode),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l.learningReview),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  key: ValueKey('$title-edit'),
                  onPressed: () => _openEdit(context, mode),
                  icon: const Icon(Icons.tune),
                  tooltip: l.learningSelect,
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  key: ValueKey('$title-statistics'),
                  onPressed: () => _openStatistics(context, mode),
                  icon: const Icon(Icons.bar_chart),
                  tooltip: l.learningStatistics,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
