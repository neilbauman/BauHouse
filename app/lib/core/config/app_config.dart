class AppConfig {
  AppConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // RevenueCat
  static const revenueCatKeyIOS =
      String.fromEnvironment('REVENUECAT_PUBLIC_KEY_IOS');
  static const revenueCatKeyAndroid =
      String.fromEnvironment('REVENUECAT_PUBLIC_KEY_ANDROID');

  // AdMob
  static const adMobAppIdIOS =
      String.fromEnvironment('ADMOB_APP_ID_IOS');
  static const adMobAppIdAndroid =
      String.fromEnvironment('ADMOB_APP_ID_ANDROID');
  static const adMobRewardedIdIOS =
      String.fromEnvironment('ADMOB_REWARDED_ID_IOS');
  static const adMobRewardedIdAndroid =
      String.fromEnvironment('ADMOB_REWARDED_ID_ANDROID');
  static const adMobInterstitialIdIOS =
      String.fromEnvironment('ADMOB_INTERSTITIAL_ID_IOS');
  static const adMobInterstitialIdAndroid =
      String.fromEnvironment('ADMOB_INTERSTITIAL_ID_ANDROID');

  // PostHog
  static const posthogApiKey =
      String.fromEnvironment('POSTHOG_API_KEY');
  static const posthogHost =
      String.fromEnvironment('POSTHOG_HOST', defaultValue: 'https://app.posthog.com');
}
