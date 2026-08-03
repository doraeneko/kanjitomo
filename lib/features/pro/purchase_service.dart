import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'pro_status_repository.dart';

/// Wraps [InAppPurchase] to manage the single non-consumable "Pro Unlock"
/// product. Keeps a purchase stream subscription alive for the app's
/// lifetime so receipts are processed even when the paywall sheet isn't open.
class PurchaseService {
  static const productId = 'pro_unlock';

  InAppPurchase? _iap;
  late final ProStatusRepository _proStatus;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// Cached product details fetched from the store, or null if the store
  /// is unavailable / the product isn't configured yet.
  ProductDetails? product;
  bool _available = false;

  Future<void> init(ProStatusRepository proStatus) async {
    _proStatus = proStatus;
    try {
      final iap = InAppPurchase.instance;
      _available = await iap.isAvailable();
      if (!_available) return;
      _iap = iap;

      _subscription = iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (_) {},
      );

      final response = await iap.queryProductDetails({productId});
      if (response.productDetails.isNotEmpty) {
        product = response.productDetails.first;
      }
    } catch (_) {
      // Platform channel not available (e.g. in widget tests or on desktop).
      _available = false;
    }
  }

  Future<bool> buyPro() async {
    if (!_available || product == null || _iap == null) return false;
    final param = PurchaseParam(productDetails: product!);
    return _iap!.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    if (!_available || _iap == null) return;
    await _iap!.restorePurchases();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _proStatus.setPro(true);
          if (p.pendingCompletePurchase) {
            _iap?.completePurchase(p);
          }
        case PurchaseStatus.pending:
        case PurchaseStatus.canceled:
        case PurchaseStatus.error:
          if (p.pendingCompletePurchase) {
            _iap?.completePurchase(p);
          }
      }
    }
  }

  /// Stream for external listeners (e.g. the paywall sheet) that want to
  /// observe purchase-stream events directly. Returns an empty stream when
  /// the store is unavailable.
  Stream<List<PurchaseDetails>> get purchaseStream =>
      _iap?.purchaseStream ?? const Stream.empty();

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}
