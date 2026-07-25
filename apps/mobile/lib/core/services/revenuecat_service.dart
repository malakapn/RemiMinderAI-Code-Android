import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/environment.dart';

class RevenueCatService {
  RevenueCatService._();

  static final RevenueCatService instance = RevenueCatService._();
  bool _configured = false;

  Future<void> configure() async {
    if (_configured) return;

    final apiKey = Platform.isAndroid
        ? Environment.revenueCatGoogleApiKey
        : Environment.revenueCatAppleApiKey;
    if (apiKey.isEmpty) {
      debugPrint('RevenueCat: missing API key for this platform');
      return;
    }

    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
    await Purchases.configure(PurchasesConfiguration(apiKey));
    _configured = true;
  }

  Future<CustomerInfo?> logIn(String firebaseUid) async {
    await configure();
    if (!_configured) return null;
    final result = await Purchases.logIn(firebaseUid);
    return result.customerInfo;
  }

  Future<CustomerInfo?> getCustomerInfo() async {
    await configure();
    if (!_configured) return null;
    return Purchases.getCustomerInfo();
  }

  Future<Offerings?> getOfferings() async {
    await configure();
    if (!_configured) return null;
    return Purchases.getOfferings();
  }

  Future<CustomerInfo?> purchasePackage(Package package) async {
    await configure();
    if (!_configured) return null;
    final result = await Purchases.purchase(PurchaseParams.package(package));
    return result.customerInfo;
  }

  Future<CustomerInfo?> restorePurchases() async {
    await configure();
    if (!_configured) return null;
    return Purchases.restorePurchases();
  }

  Future<void> logOut() async {
    if (!_configured) return;
    await Purchases.logOut();
  }

  bool hasPremium(CustomerInfo? info) {
    return info?.entitlements.active
            .containsKey(Environment.revenueCatPremiumEntitlement) ??
        false;
  }

  String? activeProductId(CustomerInfo? info) {
    final entitlement =
        info?.entitlements.active[Environment.revenueCatPremiumEntitlement];
    return entitlement?.productIdentifier;
  }
}
