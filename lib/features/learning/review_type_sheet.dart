import 'package:flutter/material.dart';

import '../../core/db/tables.dart';
import '../../l10n/app_localizations.dart';

/// Bottom sheet shown when starting a review: lets the user pick which
/// card kinds the session includes. Pops with the selected set, or null
/// when dismissed.
class ReviewTypeSheet extends StatefulWidget {
  final Set<CardType> initial;

  /// Due cards per kind (raw count, before the daily caps the session
  /// applies). Shown next to each option once loaded.
  final Future<Map<CardType, int>> dueCounts;

  const ReviewTypeSheet({
    super.key,
    required this.initial,
    required this.dueCounts,
  });

  @override
  State<ReviewTypeSheet> createState() => _ReviewTypeSheetState();
}

class _ReviewTypeSheetState extends State<ReviewTypeSheet> {
  /// Display order: kanji first, then composita; recall before recognition.
  static const _order = [
    CardType.drawFromMeaning,
    CardType.kanjiRecognition,
    CardType.drawInSentence,
    CardType.readingCloze,
  ];

  late final Set<CardType> _selected = {...widget.initial};
  Map<CardType, int>? _dueCounts;

  @override
  void initState() {
    super.initState();
    widget.dueCounts.then((counts) {
      if (mounted) setState(() => _dueCounts = counts);
    }).ignore();
  }

  (String, String) _labels(AppLocalizations l, CardType type) {
    switch (type) {
      case CardType.drawFromMeaning:
        return (l.reviewTypeKanjiRecall, l.reviewTypeKanjiRecallHelp);
      case CardType.kanjiRecognition:
        return (l.reviewTypeKanjiRecognition, l.reviewTypeKanjiRecognitionHelp);
      case CardType.drawInSentence:
        return (l.reviewTypeCompositaRecall, l.reviewTypeCompositaRecallHelp);
      case CardType.readingCloze:
        return (
          l.reviewTypeCompositaRecognition,
          l.reviewTypeCompositaRecognitionHelp,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(l.reviewTypesTitle, style: theme.textTheme.titleMedium),
            ),
            for (final type in _order) _buildOption(l, type),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  key: const ValueKey('review-start'),
                  onPressed: _selected.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(_selected),
                  icon: const Icon(Icons.play_circle_filled),
                  label: Text(
                    l.reviewTypesStart,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(AppLocalizations l, CardType type) {
    final (title, help) = _labels(l, type);
    final due = _dueCounts?[type];
    return CheckboxListTile(
      key: ValueKey('review-type-${type.name}'),
      value: _selected.contains(type),
      onChanged: (on) => setState(() {
        if (on ?? false) {
          _selected.add(type);
        } else {
          _selected.remove(type);
        }
      }),
      title: Text(title),
      subtitle: Text(due == null ? help : '$help · ${l.reviewTypeDue(due)}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}
