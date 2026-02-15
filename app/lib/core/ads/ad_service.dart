import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/app_config.dart';

/// Manages AdMob ad lifecycle: rewarded videos and interstitials.
///
/// Hard rules from the BauHouse ad philosophy:
/// - No mid-puzzle ads
/// - No app-open interstitials
/// - No banners over game content
/// - All rewarded ads are player-initiated
/// - Between-puzzle sponsored card skippable after 3s, max 2× per session
class AdService {
  AdService._();
  static final instance = AdService._();

  bool _initialised = false;
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _isLoadingRewarded = false;
  bool _isLoadingInterstitial = false;

  /// Number of interstitial (sponsored card) ads shown today.
  int _sponsoredCardCount = 0;
  static const _maxSponsoredCardsPerSession = 2;

  String get _rewardedAdUnitId {
    if (Platform.isIOS) {
      return AppConfig.adMobRewardedIdIOS.isNotEmpty
          ? AppConfig.adMobRewardedIdIOS
          : 'ca-app-pub-3940256099942544/1712485313'; // Test ad unit
    }
    return AppConfig.adMobRewardedIdAndroid.isNotEmpty
        ? AppConfig.adMobRewardedIdAndroid
        : 'ca-app-pub-3940256099942544/5224354917'; // Test ad unit
  }

  String get _interstitialAdUnitId {
    if (Platform.isIOS) {
      return AppConfig.adMobInterstitialIdIOS.isNotEmpty
          ? AppConfig.adMobInterstitialIdIOS
          : 'ca-app-pub-3940256099942544/4411468910'; // Test ad unit
    }
    return AppConfig.adMobInterstitialIdAndroid.isNotEmpty
        ? AppConfig.adMobInterstitialIdAndroid
        : 'ca-app-pub-3940256099942544/1033173712'; // Test ad unit
  }

  /// Initialise the Mobile Ads SDK. Call once at app startup.
  Future<void> init() async {
    if (_initialised) return;

    try {
      await MobileAds.instance.initialize();
      _initialised = true;
      debugPrint('[AdService] Mobile Ads SDK initialised.');

      // Pre-load ads
      _loadRewardedAd();
      _loadInterstitialAd();
    } catch (e) {
      debugPrint('[AdService] Init error: $e');
    }
  }

  /// Reset the daily sponsored card counter (call at start of each day).
  void resetDailyCount() {
    _sponsoredCardCount = 0;
  }

  // ───── Rewarded Ad ─────

  /// Whether a rewarded ad is ready to show.
  bool get isRewardedAdReady => _rewardedAd != null;

  /// Load a rewarded ad. Automatically called after init and after showing.
  void _loadRewardedAd() {
    if (_isLoadingRewarded || !_initialised) return;
    _isLoadingRewarded = true;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoadingRewarded = false;
          debugPrint('[AdService] Rewarded ad loaded.');
        },
        onAdFailedToLoad: (error) {
          _isLoadingRewarded = false;
          debugPrint('[AdService] Rewarded ad failed to load: $error');
          // Retry after delay
          Future.delayed(const Duration(seconds: 30), _loadRewardedAd);
        },
      ),
    );
  }

  /// Show a rewarded ad. Returns the reward amount, or null if the ad
  /// couldn't be shown or wasn't completed.
  ///
  /// [context] is for analytics (e.g. "archive_unlock", "streak_shield", "earn_credits").
  Future<RewardItem?> showRewardedAd({String context = 'unknown'}) async {
    if (_rewardedAd == null) {
      debugPrint('[AdService] No rewarded ad available.');
      return null;
    }

    final ad = _rewardedAd!;
    _rewardedAd = null;

    RewardItem? earnedReward;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedAd(); // Pre-load next
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] Rewarded ad failed to show: $error');
        ad.dispose();
        _loadRewardedAd();
      },
    );

    await ad.show(
      onUserEarnedReward: (_, reward) {
        earnedReward = reward;
        debugPrint(
          '[AdService] User earned reward: ${reward.amount} ${reward.type} '
          '(context: $context)',
        );
      },
    );

    return earnedReward;
  }

  // ───── Interstitial Ad (between-puzzle sponsored card) ─────

  /// Whether a sponsored card (interstitial) is ready and allowed.
  bool get isSponsoredCardReady =>
      _interstitialAd != null &&
      _sponsoredCardCount < _maxSponsoredCardsPerSession;

  /// Load an interstitial ad.
  void _loadInterstitialAd() {
    if (_isLoadingInterstitial || !_initialised) return;
    _isLoadingInterstitial = true;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoadingInterstitial = false;
          debugPrint('[AdService] Interstitial ad loaded.');
        },
        onAdFailedToLoad: (error) {
          _isLoadingInterstitial = false;
          debugPrint('[AdService] Interstitial ad failed to load: $error');
          Future.delayed(const Duration(seconds: 30), _loadInterstitialAd);
        },
      ),
    );
  }

  /// Show a sponsored card (between-puzzle interstitial).
  /// Returns true if the ad was shown, false otherwise.
  Future<bool> showSponsoredCard() async {
    if (!isSponsoredCardReady) return false;

    final ad = _interstitialAd!;
    _interstitialAd = null;
    _sponsoredCardCount++;

    bool shown = true;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        shown = false;
        ad.dispose();
        _loadInterstitialAd();
      },
    );

    await ad.show();
    return shown;
  }

  /// Dispose all loaded ads. Call when the app is shutting down.
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
