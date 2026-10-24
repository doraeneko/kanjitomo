import 'package:flutter/material.dart';

import '../../core/db/tables.dart';
import '../../l10n/app_localizations.dart';
import '../review/review_repository.dart' show NewCardOrder, SessionInputs;

/// What the user chose in [ReviewTypeSheet].
class ReviewSessionOptions {
  final Set<CardType> cardTypes;
  final NewCardOrder newCardOrder;
  const ReviewSessionOptions({
    required this.cardTypes,
    required this.newCardOrder,
  });
}

/// Bottom sheet shown when starting a review: lets the user pick which
/// card kinds the session includes and the order new kanji are introduced
/// in. Pops with a [ReviewSessionOptions], or null when dismissed.
class ReviewTypeSheet extends StatefulWidget {
  final Set<CardType> initial;
  final NewCardOrder initialOrder;

  /// Due cards and limits for planning the session; per-kind counts and
  /// the exact session size are shown once loaded.
  final Future<SessionInputs> sessionInputs;

  const ReviewTypeSheet({
    super.key,
    required this.initial,
    this.initialOrder = NewCardOrder.rtk,
    required this.sessionInputs,
  });

  @override
  State<ReviewTypeSheet> createState() => _ReviewTypeSheetState();
}

class _ReviewTypeSheetState extends State<ReviewTypeSheet> {
  /// Display order: kanji first, then composita; recall before recognition.
  static const _displayOrder = [
    CardType.drawFromMeaning,
    CardType.kanjiRecognition,
    CardType.drawInSentence,
    CardType.readingCloze,
  ];

  late final Set<CardType> _selected = {...widget.initial};
  late NewCardOrder _order = widget.initialOrder;
  SessionInputs? _inputs;

  @override
  void initState() {
    super.initState();
    widget.sessionInputs.then((inputs) {
      if (mounted) setState(() => _inputs = inputs);
    }).ignore();
  }

  /// Cards the session will load for the current selection -- daily
  /// limits included, so it matches the session's own count.
  int? get _plannedTotal => _inputs
      ?.plan(
        cardTypes: _selected.length == CardType.values.length ? null : _selected,
      )
      .total;

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
            for (final type in _displayOrder) _buildOption(l, type),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                children: [
                  Expanded(child: Text(l.reviewNewCardOrder)),
                  SegmentedButton<NewCardOrder>(
                    key: const ValueKey('new-card-order'),
                    segments: [
                      ButtonSegment(
                        value: NewCardOrder.rtk,
                        label: Text(l.reviewNewCardOrderRtk),
                      ),
                      ButtonSegment(
                        value: NewCardOrder.random,
                        label: Text(l.reviewNewCardOrderRandom),
                      ),
                    ],
                    selected: {_order},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => setState(() => _order = s.first),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  key: const ValueKey('review-start'),
                  onPressed: _selected.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(
                            ReviewSessionOptions(
                              cardTypes: _selected,
                              newCardOrder: _order,
                            ),
                          ),
                  icon: const Icon(Icons.play_circle_filled),
                  label: Text(
                    _plannedTotal == null || _selected.isEmpty
                        ? l.reviewTypesStart
                        : l.reviewTypesStartCount(_plannedTotal!),
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
    final inputs = _inputs;
    final due = inputs?.reviews.where((c) => c.cardType == type).length;
    final fresh = inputs?.newCards.where((c) => c.cardType == type).length;
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
      subtitle: Text(
        due == null ? help : '$help\n${l.reviewTypeCounts(due, fresh!)}',
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}
