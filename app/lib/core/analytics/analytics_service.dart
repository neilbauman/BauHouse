import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import '../config/app_config.dart';

/// Singleton analytics service wrapping PostHog.
///
/// All events are defined as constants — never pass raw strings to PostHog.
/// Initialise once at app startup via [init].
class AnalyticsService {
  AnalyticsService._();
  static final instance = AnalyticsService._();

  bool _initialised = false;

  /// Initialise PostHog. Must be called once during app startup.
  Future<void> init() async {
    if (_initialised) return;

    if (AppConfig.posthogApiKey.isEmpty) {
      debugPrint('[Analytics] No PostHog API key configured — '
          'analytics disabled.');
      return;
    }

    // PostHog Flutter SDK is configured via PostHogConfig in main.dart
    // or AndroidManifest.xml / Info.plist. This service wraps the API calls.
    _initialised = true;
    debugPrint('[Analytics] PostHog initialised.');
  }

  /// Identify the user (after auth).
  Future<void> identify(String userId,
      {Map<String, dynamic>? properties}) async {
    if (!_initialised) return;

    try {
      await Posthog().identify(
        userId: userId,
        userProperties: properties,
      );
    } catch (e) {
      debugPrint('[Analytics] Identify error: $e');
    }
  }

  /// Track a named event with optional properties.
  Future<void> track(String event,
      {Map<String, dynamic>? properties}) async {
    if (!_initialised) {
      debugPrint('[Analytics] (disabled) $event: $properties');
      return;
    }

    try {
      await Posthog().capture(
        eventName: event,
        properties: properties,
      );
    } catch (e) {
      debugPrint('[Analytics] Track error: $e');
    }
  }

  /// Reset analytics on sign-out.
  Future<void> reset() async {
    if (!_initialised) return;

    try {
      await Posthog().reset();
    } catch (e) {
      debugPrint('[Analytics] Reset error: $e');
    }
  }

  // ══════════════════════════════════════════════════════
  //  Core Events (from tech spec Section 7.1)
  // ══════════════════════════════════════════════════════

  // --- Onboarding ---

  Future<void> onboardingStarted({
    required String platform,
    required String appVersion,
  }) =>
      track(Events.onboardingStarted, properties: {
        'platform': platform,
        'app_version': appVersion,
      });

  Future<void> onboardingCompleted({
    required String houseStyle,
    required String accentColour,
    required int durationSeconds,
  }) =>
      track(Events.onboardingCompleted, properties: {
        'house_style': houseStyle,
        'accent_colour': accentColour,
        'duration_seconds': durationSeconds,
      });

  // --- Puzzles ---

  Future<void> puzzleStarted({
    required String puzzleId,
    required String puzzleType,
    required String difficulty,
    required String session,
  }) =>
      track(Events.puzzleStarted, properties: {
        'puzzle_id': puzzleId,
        'puzzle_type': puzzleType,
        'difficulty': difficulty,
        'session': session,
      });

  Future<void> puzzleCompleted({
    required String puzzleId,
    required String puzzleType,
    required int solveSeconds,
    required int hintsUsed,
    required String difficulty,
  }) =>
      track(Events.puzzleCompleted, properties: {
        'puzzle_id': puzzleId,
        'puzzle_type': puzzleType,
        'solve_seconds': solveSeconds,
        'hints_used': hintsUsed,
        'difficulty': difficulty,
      });

  Future<void> sessionCompleted({
    required String session,
    required String puzzleSetId,
    required int totalTime,
  }) =>
      track(Events.sessionCompleted, properties: {
        'session': session,
        'puzzle_set_id': puzzleSetId,
        'total_time': totalTime,
      });

  Future<void> dailyComplete({
    required String puzzleSetId,
    required int totalTime,
  }) =>
      track(Events.dailyComplete, properties: {
        'puzzle_set_id': puzzleSetId,
        'total_time': totalTime,
      });

  // --- Streaks ---

  Future<void> streakUpdated({
    required int newStreak,
    required int prevStreak,
    required bool isNewRecord,
  }) =>
      track(Events.streakUpdated, properties: {
        'new_streak': newStreak,
        'prev_streak': prevStreak,
        'is_new_record': isNewRecord,
      });

  // --- Monetisation ---

  Future<void> premiumConversionPrompt({
    required String triggerContext,
    required int currentStreak,
  }) =>
      track(Events.premiumConversionPrompt, properties: {
        'trigger_context': triggerContext,
        'current_streak': currentStreak,
      });

  Future<void> premiumSubscribed({
    required String productId,
    required String planType,
  }) =>
      track(Events.premiumSubscribed, properties: {
        'product_id': productId,
        'plan_type': planType,
      });

  Future<void> rewardedAdWatched({
    required String adContext,
    required int creditsAwarded,
  }) =>
      track(Events.rewardedAdWatched, properties: {
        'ad_context': adContext,
        'credits_awarded': creditsAwarded,
      });

  // --- Archive ---

  Future<void> archiveUnlocked({
    required String puzzleSetId,
    required String unlockMethod,
    required int daysAgo,
  }) =>
      track(Events.archiveUnlocked, properties: {
        'puzzle_set_id': puzzleSetId,
        'unlock_method': unlockMethod,
        'days_ago': daysAgo,
      });

  // --- Civic ---

  Future<void> civicCompleted({
    required String civicId,
    required int weekNumber,
    required int solveSeconds,
  }) =>
      track(Events.civicCompleted, properties: {
        'civic_id': civicId,
        'week_number': weekNumber,
        'solve_seconds': solveSeconds,
      });

  // --- App lifecycle ---

  Future<void> appOpened({
    required int currentStreak,
    required bool isPremium,
  }) =>
      track(Events.appOpened, properties: {
        'current_streak': currentStreak,
        'is_premium': isPremium,
      });

  Future<void> streakShieldUsed({
    required String method,
    required int streakPreserved,
  }) =>
      track(Events.streakShieldUsed, properties: {
        'method': method,
        'streak_preserved': streakPreserved,
      });
}

/// Event name constants. Never pass raw strings to PostHog.
class Events {
  Events._();

  static const onboardingStarted = 'onboarding_started';
  static const onboardingCompleted = 'onboarding_completed';
  static const puzzleStarted = 'puzzle_started';
  static const puzzleCompleted = 'puzzle_completed';
  static const sessionCompleted = 'session_completed';
  static const dailyComplete = 'daily_complete';
  static const streakUpdated = 'streak_updated';
  static const premiumConversionPrompt = 'premium_conversion_prompt';
  static const premiumSubscribed = 'premium_subscribed';
  static const rewardedAdWatched = 'rewarded_ad_watched';
  static const archiveUnlocked = 'archive_unlocked';
  static const civicCompleted = 'civic_completed';
  static const appOpened = 'app_opened';
  static const streakShieldUsed = 'streak_shield_used';
}
