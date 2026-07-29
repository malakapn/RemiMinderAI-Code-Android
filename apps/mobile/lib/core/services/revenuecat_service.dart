import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../config/environment.dart';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._();
  factory RevenueCatService() => _instance;
  RevenueCatService._();

  bool _initialized = false;
  bool _isPremium = false;

  bool get isPremium => _isPremium;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final apiKey = Environment.revenueCatApiKey;
      if (apiKey.isEmpty) {
        if (kDebugMode) print('⚠️ RevenueCat: No API key, skipping init');
        return;
      }
      final config = PurchasesConfiguration(apiKey);
      await Purchases.configure(config);
      _initialized = true;
      if (kDebugMode) print('✅ RevenueCat initialized');
    } catch (e) {
      if (kDebugMode) print('❌ RevenueCat init failed: $e');
    }
  }

  Future<void> login(String firebaseUid) async {
    if (!_initialized) return;
    try {
      await Purchases.logIn(firebaseUid);
      await refreshPremiumStatus();
      if (kDebugMode) print('✅ RevenueCat login: $firebaseUid');
    } catch (e) {
      if (kDebugMode) print('❌ RevenueCat login failed: $e');
    }
  }

  Future<void> logout() async {
    if (!_initialized) return;
    try {
      await Purchases.logOut();
      _isPremium = false;
    } catch (e) {
      if (kDebugMode) print('❌ RevenueCat logout failed: $e');
    }
  }

  Future<void> refreshPremiumStatus() async {
    if (!_initialized) return;
    try {
      final info = await Purchases.getCustomerInfo();
      _isPremium = info.entitlements.active.containsKey('Premium');
      if (kDebugMode) print('🔑 Premium status: $_isPremium');
    } catch (e) {
      if (kDebugMode) print('❌ RevenueCat status check failed: $e');
    }
  }

  Future<List<Package>> getOfferings() async {
    if (!_initialized) return [];
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        return offerings.current!.availablePackages;
      }
    } catch (e) {
      if (kDebugMode) print('❌ RevenueCat offerings failed: $e');
    }
    return [];
  }

  Future<bool> purchase(Package package) async {
    if (!_initialized) return false;
    try {
      final result = await Purchases.purchasePackage(package);
      _isPremium = result.customerInfo.entitlements.active.containsKey('Premium');
      return _isPremium;
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        if (kDebugMode) print('Purchase cancelled');
      } else {
        if (kDebugMode) print('❌ Purchase failed: $e');
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('❌ Purchase failed: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (!_initialized) return;
    try {
      final info = await Purchases.restorePurchases();
      _isPremium = info.entitlements.active.containsKey('Premium');
    } catch (e) {
      if (kDebugMode) print('❌ Restore failed: $e');
    }
  }
}
