import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../l10n/app_localizations.dart';
import 'purchase_service.dart';

/// Shows a modal bottom sheet listing Pro features with a purchase button.
/// Returns `true` if Pro was unlocked during this sheet's lifetime.
Future<bool> showProPaywallSheet(
  BuildContext context,
  PurchaseService purchaseService,
) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _ProPaywallContent(purchaseService: purchaseService),
  );
  return result ?? false;
}

class _ProPaywallContent extends StatefulWidget {
  final PurchaseService purchaseService;

  const _ProPaywallContent({required this.purchaseService});

  @override
  State<_ProPaywallContent> createState() => _ProPaywallContentState();
}

enum _PaywallState { idle, purchasing, restoring, error, restored, restoredNothing }

class _ProPaywallContentState extends State<_ProPaywallContent> {
  _PaywallState _state = _PaywallState.idle;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.purchaseService.purchaseStream.listen(_onPurchaseUpdate);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      if (!mounted) return;
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          Navigator.of(context).pop(true);
          return;
        case PurchaseStatus.error:
          setState(() => _state = _PaywallState.error);
        case PurchaseStatus.canceled:
          setState(() => _state = _PaywallState.idle);
        case PurchaseStatus.pending:
          break;
      }
    }
  }

  void _buy() {
    setState(() => _state = _PaywallState.purchasing);
    widget.purchaseService.buyPro().then((started) {
      if (!started && mounted) {
        setState(() => _state = _PaywallState.error);
      }
    });
  }

  void _restore() {
    setState(() => _state = _PaywallState.restoring);
    widget.purchaseService.restorePurchases().then((_) {
      // If the stream doesn't fire a restored event within a reasonable
      // window, assume nothing was found. The stream listener handles the
      // success case.
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _state == _PaywallState.restoring) {
          setState(() => _state = _PaywallState.restoredNothing);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final product = widget.purchaseService.product;
    final price = product?.price ?? '—';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.proPaywallTitle,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(l.proPaywallDescription),
          const SizedBox(height: 16),
          _featureRow(Icons.school, l.proPaywallFeatureJlpt),
          _featureRow(Icons.edit_note, l.proPaywallFeatureCustom),
          _featureRow(Icons.extension, l.proPaywallFeatureComposita),
          _featureRow(Icons.bar_chart, l.proPaywallFeatureStats),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _state == _PaywallState.purchasing ? null : _buy,
            child: _state == _PaywallState.purchasing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.proPaywallBuyButton(price)),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _state == _PaywallState.restoring ? null : _restore,
              child: Text(
                _state == _PaywallState.restoring
                    ? l.proPaywallRestoring
                    : l.proPaywallRestore,
              ),
            ),
          ),
          if (_state == _PaywallState.error)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l.proPaywallError,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          if (_state == _PaywallState.restored)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l.proPaywallRestoreSuccess,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                textAlign: TextAlign.center,
              ),
            ),
          if (_state == _PaywallState.restoredNothing)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l.proPaywallRestoreNothing,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _featureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
