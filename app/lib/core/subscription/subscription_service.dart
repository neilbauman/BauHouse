import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../config/app_config.dart';

/// Wraps RevenueCat (purchases_flutter) for subscription management.
///
/// Initialise once during app startup via [init]. Then use
/// [isPremium], [getOfferings], and [purchasePackage] for subscription logic.
class SubscriptionService {
  SubscriptionService._();
  static final instance = SubscriptionService._();

  bool _initialised = false;

  /// Initialise RevenueCat with the platform-specific public key.
  /// Must be called once at app startup (after auth).
  Future<void> init({required String userId}) async {
    if (_initialised) return;

    final apiKey = Platform.isIOS
        ? AppConfig.revenueCatKeyIOS
        : AppConfig.revenueCatKeyAndroid;

    if (apiKey.isEmpty) {
      debugPrint('[SubscriptionService] No RevenueCat key configured — '
          'subscription features disabled.');
      return;
    }

    final configuration = PurchasesConfiguration(apiKey)
      ..appUserID = userId;

    await Purchases.configure(configuration);
    _initialised = true;
    debugPrint('[SubscriptionService] RevenueCat initialised for $userId');
  }

  /// Whether the current user has an active premium entitlement.
  Future<bool> isPremium() async {
    if (!_initialised) return false;

    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey('full_resident');
    } catch (e) {
      debugPrint('[SubscriptionService] Error checking premium: $e');
      return false;
    }
  }

  /// Get available subscription offerings (monthly / annual packages).
  Future<Offerings?> getOfferings() async {
    if (!_initialised) return null;

    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('[SubscriptionService] Error fetching offerings: $e');
      return null;
    }
  }

  /// Purchase a subscription package. Returns true on success.
  Future<bool> purchasePackage(Package package) async {
    if (!_initialised) return false;

    try {
      final result = await Purchases.purchasePackage(package);
      return result.entitlements.active.containsKey('full_resident');
    } catch (e) {
      debugPrint('[SubscriptionService] Purchase error: $e');
      return false;
    }
  }

  /// Restore previous purchases (e.g. after reinstall).
  Future<bool> restorePurchases() async {
    if (!_initialised) return false;

    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.containsKey('full_resident');
    } catch (e) {
      debugPrint('[SubscriptionService] Restore error: $e');
      return false;
    }
  }

  /// Log out the current RevenueCat user.
  Future<void> logOut() async {
    if (!_initialised) return;

    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('[SubscriptionService] Logout error: $e');
    }
  }
}
