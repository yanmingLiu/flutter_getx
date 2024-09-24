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
    if (purchaseDetailsList.isEmpty) return;

    // 根据 transactionDate 对列表进行排序，获取最新的购买记录
    purchaseDetailsList.sort((a, b) {
      // 将 transactionDate 从 String 转换为 int（时间戳），并处理 null 情况
      int dateA = int.tryParse(a.transactionDate ?? '0') ?? 0;
      int dateB = int.tryParse(b.transactionDate ?? '0') ?? 0;

      // 按时间降序排序
      return dateB.compareTo(dateA);
    });

    // 处理最新的购买记录
    PurchaseDetails latestPurchaseDetails = purchaseDetailsList.first;

    switch (latestPurchaseDetails.status) {
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        debugPrint(
            '[iap] ${latestPurchaseDetails.status == PurchaseStatus.purchased ? '新购买' : '恢复购买'}: ${latestPurchaseDetails.productID}');
        bool isProcessed = await _isPurchaseProcessed(latestPurchaseDetails.purchaseID);
        if (!isProcessed) {
          await _verifyAndCompletePurchase(latestPurchaseDetails);
        }
        break;

      case PurchaseStatus.error:
        debugPrint('[iap] Purchase failed: ${latestPurchaseDetails.error}');
        break;

      case PurchaseStatus.canceled:
        debugPrint('[iap] 取消购买: ${latestPurchaseDetails.error}');
        break;

      default:
        debugPrint('[iap] 未知的购买状态: ${latestPurchaseDetails.status}');
        break;
    }

    if (latestPurchaseDetails.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(latestPurchaseDetails);
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
