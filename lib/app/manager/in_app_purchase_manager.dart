import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class InAppPurchaseManager {
  // Singleton instance
  static final InAppPurchaseManager _instance = InAppPurchaseManager._internal();
  factory InAppPurchaseManager() => _instance;
  InAppPurchaseManager._internal() {
    listenToPurchaseUpdates();
  }

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  final Set<String> _consumableIds = {'160Gems', '720Gems', '3300Gems', '6500Gems'};
  final Set<String> _subscriptionIds = {'weekly', 'monthly', 'yearly', 'yearlyhalf'};

  List<ProductDetails>? _consumableList;
  List<ProductDetails>? _subscriptionList;

  // Get consumable product details
  List<ProductDetails>? get consumableList => _consumableList;

  // Get subscription product details
  List<ProductDetails>? get subscriptionList => _subscriptionList;

  // Query product details
  Future<void> queryProductDetails() async {
    // Check if product details are already cached
    if (_consumableList != null && _subscriptionList != null) {
      debugPrint('[iap] Using cached product details');
      return;
    }

    final response = await _inAppPurchase.queryProductDetails(_consumableIds.union(_subscriptionIds));
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('[iap] Products not found: ${response.notFoundIDs}');
    }
    _consumableList = response.productDetails.where((pd) => _consumableIds.contains(pd.id)).toList()
      ..sort(
        (a, b) => a.rawPrice > b.rawPrice ? 1 : -1,
      );
    _subscriptionList = response.productDetails.where((pd) => _subscriptionIds.contains(pd.id)).toList()
      ..sort(
        (a, b) => a.rawPrice > b.rawPrice ? 1 : -1,
      );
  }

  // Purchase a product
  Future<void> purchaseProduct(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    if (_consumableIds.contains(productDetails.id)) {
      await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
    } else {
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  // Listen to purchase updates
  void listenToPurchaseUpdates() {
    _subscription = _inAppPurchase.purchaseStream.listen((purchaseDetailsList) {
      _processPurchaseDetails(purchaseDetailsList);
    }, onError: (error) {
      debugPrint('[iap] Error in purchase stream: $error');
    });
  }

  // Process purchase details
  Future<void> _processPurchaseDetails(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        debugPrint('[iap] 新购买: ${purchaseDetails.productID}');
        bool isProcessed = await _isPurchaseProcessed(purchaseDetails.purchaseID);
        if (!isProcessed) {
          await _verifyAndCompletePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.restored) {
        // 处理恢复的购买
        debugPrint('[iap] 恢复购买: ${purchaseDetails.productID}');
        bool isProcessed = await _isPurchaseProcessed(purchaseDetails.purchaseID);
        if (!isProcessed) {
          await _markPurchaseAsProcessed(purchaseDetails.purchaseID);
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint('[iap] Purchase failed: ${purchaseDetails.error}');
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        debugPrint('[iap] 取消购买: ${purchaseDetails.error}');
      }
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  // Verify purchase and complete
  Future<void> _verifyAndCompletePurchase(PurchaseDetails purchaseDetails) async {
    bool isValid = await verifyPurchaseWithServer(purchaseDetails);
    if (isValid) {
      await _markPurchaseAsProcessed(purchaseDetails.purchaseID);
    } else {
      debugPrint('[iap] Purchase verification failed for product: ${purchaseDetails.productID}');
    }
  }

  // Verify purchase with server (mock implementation)
  Future<bool> verifyPurchaseWithServer(PurchaseDetails purchaseDetails) async {
    debugPrint('[iap] Verifying purchase with server for ${purchaseDetails.productID}');
    return true; // Implement actual server-side verification logic here
  }

  // Mark purchase as processed
  Future<void> _markPurchaseAsProcessed(String? purchaseID) async {
    if (purchaseID != null) {
      await _storage.write(key: purchaseID, value: 'processed');
    }
  }

  // Check if purchase is already processed
  Future<bool> _isPurchaseProcessed(String? purchaseID) async {
    if (purchaseID == null) return false;
    String? value = await _storage.read(key: purchaseID);
    return value == 'processed';
  }

  // Dispose method to clean up resources
  void dispose() {
    _subscription?.cancel();
  }
}
