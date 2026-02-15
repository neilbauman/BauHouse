import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/supabase/auth_service.dart';
import '../../core/subscription/subscription_provider.dart';

/// State representing the player's streak and shield status.
class StreakState {
  final int currentStreak;
  final int longestStreak;
  final int builderCredits;
  final bool streakAtRisk;
  final bool shieldAvailable;
  final int shieldsUsedThisMonth;
  final DateTime? lastActiveDate;
  final bool isLoading;
  final String? error;

  const StreakState({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.builderCredits = 0,
    this.streakAtRisk = false,
    this.shieldAvailable = false,
    this.shieldsUsedThisMonth = 0,
    this.lastActiveDate,
    this.isLoading = false,
    this.error,
  });

  StreakState copyWith({
    int? currentStreak,
    int? longestStreak,
    int? builderCredits,
    bool? streakAtRisk,
    bool? shieldAvailable,
    int? shieldsUsedThisMonth,
    DateTime? lastActiveDate,
    bool? isLoading,
    String? error,
  }) {
    return StreakState(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      builderCredits: builderCredits ?? this.builderCredits,
      streakAtRisk: streakAtRisk ?? this.streakAtRisk,
      shieldAvailable: shieldAvailable ?? this.shieldAvailable,
      shieldsUsedThisMonth:
          shieldsUsedThisMonth ?? this.shieldsUsedThisMonth,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Cost to use a streak shield with Builder's Credits.
  static const shieldCreditCost = 30;

  /// Monthly shields included for premium users.
  static const premiumShieldsPerMonth = 3;
}

/// Manages streak state, shield activation, and credit spending.
class StreakNotifier extends Notifier<StreakState> {
  @override
  StreakState build() {
    _loadStreak();
    return const StreakState(isLoading: true);
  }

  Future<void> _loadStreak() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      state = const StreakState();
      return;
    }

    try {
      final data = await SupabaseClientManager.client
          .from('players')
          .select(
              'current_streak, longest_streak, builder_credits, last_active_date, is_premium')
          .eq('id', userId)
          .single();

      final currentStreak = data['current_streak'] as int? ?? 0;
      final longestStreak = data['longest_streak'] as int? ?? 0;
      final credits = data['builder_credits'] as int? ?? 0;
      final lastActiveStr = data['last_active_date'] as String?;
      final isPremium = data['is_premium'] as bool? ?? false;

      DateTime? lastActive;
      if (lastActiveStr != null) {
        lastActive = DateTime.tryParse(lastActiveStr);
      }

      // Check if streak is at risk (missed yesterday)
      final today = DateTime.now().toUtc();
      final todayDate =
          DateTime.utc(today.year, today.month, today.day);
      final yesterdayDate = todayDate.subtract(const Duration(days: 1));

      bool atRisk = false;
      if (lastActive != null && currentStreak > 0) {
        final lastDate = DateTime.utc(
            lastActive.year, lastActive.month, lastActive.day);
        // At risk if last active was before yesterday
        atRisk = lastDate.isBefore(yesterdayDate);
      }

      // Count shields used this month
      final shieldsUsed = await _countShieldsThisMonth(userId);

      // Shield is available if streak is at risk and player can afford it
      final canAffordCredits = credits >= StreakState.shieldCreditCost;
      final premiumShieldsLeft = isPremium
          ? (StreakState.premiumShieldsPerMonth - shieldsUsed)
          : 0;

      final shieldAvailable =
          atRisk && (canAffordCredits || premiumShieldsLeft > 0);

      state = StreakState(
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        builderCredits: credits,
        streakAtRisk: atRisk,
        shieldAvailable: shieldAvailable,
        shieldsUsedThisMonth: shieldsUsed,
        lastActiveDate: lastActive,
      );
    } catch (e) {
      state = StreakState(error: e.toString());
    }
  }

  Future<int> _countShieldsThisMonth(String userId) async {
    try {
      final now = DateTime.now().toUtc();
      final monthStart = DateTime.utc(now.year, now.month, 1);

      final response = await SupabaseClientManager.client
          .from('credit_transactions')
          .select('id')
          .eq('player_id', userId)
          .eq('reason', 'streak_shield')
          .gte('created_at', monthStart.toIso8601String());

      return (response as List).length;
    } catch (_) {
      return 0;
    }
  }

  /// Activate a streak shield using Builder's Credits.
  ///
  /// Deducts [StreakState.shieldCreditCost] credits and preserves the streak.
  Future<bool> useShieldWithCredits() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return false;

    if (state.builderCredits < StreakState.shieldCreditCost) return false;

    state = state.copyWith(isLoading: true);

    try {
      // Update last_active_date to yesterday to bridge the gap
      final yesterday = DateTime.now()
          .toUtc()
          .subtract(const Duration(days: 1));
      final yesterdayStr =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      // Deduct credits and update last_active_date
      await SupabaseClientManager.client.from('players').update({
        'builder_credits': state.builderCredits - StreakState.shieldCreditCost,
        'last_active_date': yesterdayStr,
      }).eq('id', userId);

      // Record the transaction
      await SupabaseClientManager.client.from('credit_transactions').insert({
        'player_id': userId,
        'amount': -StreakState.shieldCreditCost,
        'reason': 'streak_shield',
      });

      state = state.copyWith(
        builderCredits:
            state.builderCredits - StreakState.shieldCreditCost,
        streakAtRisk: false,
        shieldAvailable: false,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Activate a streak shield for premium users (free shield).
  Future<bool> usePremiumShield() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return false;

    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) return false;

    final remaining = StreakState.premiumShieldsPerMonth -
        state.shieldsUsedThisMonth;
    if (remaining <= 0) return false;

    state = state.copyWith(isLoading: true);

    try {
      final yesterday = DateTime.now()
          .toUtc()
          .subtract(const Duration(days: 1));
      final yesterdayStr =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      await SupabaseClientManager.client.from('players').update({
        'last_active_date': yesterdayStr,
      }).eq('id', userId);

      // Record the shield usage (no credit cost for premium)
      await SupabaseClientManager.client.from('credit_transactions').insert({
        'player_id': userId,
        'amount': 0,
        'reason': 'streak_shield',
      });

      state = state.copyWith(
        streakAtRisk: false,
        shieldAvailable: false,
        shieldsUsedThisMonth: state.shieldsUsedThisMonth + 1,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Activate a streak shield after watching a rewarded ad (free users).
  Future<bool> useShieldWithAd() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return false;

    state = state.copyWith(isLoading: true);

    try {
      final yesterday = DateTime.now()
          .toUtc()
          .subtract(const Duration(days: 1));
      final yesterdayStr =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      await SupabaseClientManager.client.from('players').update({
        'last_active_date': yesterdayStr,
      }).eq('id', userId);

      // Record as rewarded_ad funded shield
      await SupabaseClientManager.client.from('credit_transactions').insert({
        'player_id': userId,
        'amount': 0,
        'reason': 'streak_shield',
        'reference_id': null,
      });

      state = state.copyWith(
        streakAtRisk: false,
        shieldAvailable: false,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Refresh streak data from the database.
  Future<void> refresh() async {
    await _loadStreak();
  }
}

/// Provider for streak state.
final streakProvider =
    NotifierProvider<StreakNotifier, StreakState>(StreakNotifier.new);

/// Convenience: whether the streak is at risk.
final streakAtRiskProvider = Provider<bool>((ref) {
  return ref.watch(streakProvider).streakAtRisk;
});
