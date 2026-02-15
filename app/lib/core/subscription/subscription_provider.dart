import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../supabase/auth_service.dart';
import 'subscription_service.dart';

/// The current premium/subscription state of the player.
class SubscriptionState {
  final bool isPremium;
  final bool isLoading;
  final Offerings? offerings;
  final String? error;

  const SubscriptionState({
    this.isPremium = false,
    this.isLoading = false,
    this.offerings,
    this.error,
  });

  SubscriptionState copyWith({
    bool? isPremium,
    bool? isLoading,
    Offerings? offerings,
    String? error,
  }) {
    return SubscriptionState(
      isPremium: isPremium ?? this.isPremium,
      isLoading: isLoading ?? this.isLoading,
      offerings: offerings ?? this.offerings,
      error: error,
    );
  }
}

/// Manages subscription state through RevenueCat.
class SubscriptionNotifier extends Notifier<SubscriptionState> {
  @override
  SubscriptionState build() {
    _init();
    return const SubscriptionState(isLoading: true);
  }

  Future<void> _init() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      state = const SubscriptionState();
      return;
    }

    try {
      await SubscriptionService.instance.init(userId: userId);
      final premium = await SubscriptionService.instance.isPremium();
      final offerings = await SubscriptionService.instance.getOfferings();

      state = SubscriptionState(
        isPremium: premium,
        offerings: offerings,
      );
    } catch (e) {
      state = SubscriptionState(error: e.toString());
    }
  }

  /// Refresh premium status (e.g. after returning from background).
  Future<void> refresh() async {
    final premium = await SubscriptionService.instance.isPremium();
    state = state.copyWith(isPremium: premium);
  }

  /// Purchase a subscription package.
  Future<bool> purchase(Package package) async {
    state = state.copyWith(isLoading: true, error: null);

    final success = await SubscriptionService.instance.purchasePackage(package);

    state = state.copyWith(
      isPremium: success,
      isLoading: false,
      error: success ? null : 'Purchase could not be completed.',
    );

    return success;
  }

  /// Restore previous purchases.
  Future<bool> restore() async {
    state = state.copyWith(isLoading: true, error: null);

    final success = await SubscriptionService.instance.restorePurchases();

    state = state.copyWith(
      isPremium: success,
      isLoading: false,
      error: success ? null : 'No previous purchases found.',
    );

    return success;
  }

  /// Fetch the latest offerings.
  Future<void> loadOfferings() async {
    final offerings = await SubscriptionService.instance.getOfferings();
    state = state.copyWith(offerings: offerings);
  }
}

/// Provider for subscription/premium state.
final subscriptionProvider =
    NotifierProvider<SubscriptionNotifier, SubscriptionState>(
        SubscriptionNotifier.new);

/// Convenience provider for premium check.
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider).isPremium;
});
