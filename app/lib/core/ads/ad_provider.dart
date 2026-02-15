import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../subscription/subscription_provider.dart';
import 'ad_service.dart';

/// Ad state exposed to the UI layer.
class AdState {
  final bool isRewardedAdReady;
  final bool isSponsoredCardReady;
  final bool adsEnabled;

  const AdState({
    this.isRewardedAdReady = false,
    this.isSponsoredCardReady = false,
    this.adsEnabled = true,
  });

  AdState copyWith({
    bool? isRewardedAdReady,
    bool? isSponsoredCardReady,
    bool? adsEnabled,
  }) {
    return AdState(
      isRewardedAdReady: isRewardedAdReady ?? this.isRewardedAdReady,
      isSponsoredCardReady:
          isSponsoredCardReady ?? this.isSponsoredCardReady,
      adsEnabled: adsEnabled ?? this.adsEnabled,
    );
  }
}

/// Manages ad state and coordinates with premium status.
///
/// Premium users (Full Residents) see no ads at all.
class AdNotifier extends Notifier<AdState> {
  @override
  AdState build() {
    final isPremium = ref.watch(isPremiumProvider);

    if (isPremium) {
      return const AdState(adsEnabled: false);
    }

    _init();
    return const AdState();
  }

  Future<void> _init() async {
    await AdService.instance.init();
    _refreshAvailability();
  }

  /// Refresh ad availability flags.
  void _refreshAvailability() {
    state = state.copyWith(
      isRewardedAdReady: AdService.instance.isRewardedAdReady,
      isSponsoredCardReady: AdService.instance.isSponsoredCardReady,
    );
  }

  /// Show a rewarded ad and return the reward, or null if not completed.
  ///
  /// Common contexts: "archive_unlock", "streak_shield", "earn_credits".
  Future<RewardItem?> showRewardedAd({String context = 'unknown'}) async {
    if (!state.adsEnabled) return null;

    final reward = await AdService.instance.showRewardedAd(context: context);
    _refreshAvailability();
    return reward;
  }

  /// Show a between-puzzle sponsored card. Returns true if shown.
  Future<bool> showSponsoredCard() async {
    if (!state.adsEnabled) return false;

    final shown = await AdService.instance.showSponsoredCard();
    _refreshAvailability();
    return shown;
  }

  /// Reset daily ad counters (call at start of each day's session).
  void resetDaily() {
    AdService.instance.resetDailyCount();
    _refreshAvailability();
  }
}

/// Provider for ad state.
final adProvider = NotifierProvider<AdNotifier, AdState>(AdNotifier.new);

/// Convenience: whether rewarded ads can be shown right now.
final canShowRewardedAdProvider = Provider<bool>((ref) {
  final adState = ref.watch(adProvider);
  return adState.adsEnabled && adState.isRewardedAdReady;
});

/// Convenience: whether sponsored card can be shown right now.
final canShowSponsoredCardProvider = Provider<bool>((ref) {
  final adState = ref.watch(adProvider);
  return adState.adsEnabled && adState.isSponsoredCardReady;
});
