import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colours.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';
import '../../core/subscription/subscription_provider.dart';
import '../../core/ads/ad_provider.dart';
import 'streak_provider.dart';

/// Dialog shown when a player's streak is at risk.
///
/// Offers three options depending on status:
/// - Premium: use a free shield (3/month)
/// - Free + credits: spend 30 Builder's Credits
/// - Free + ad: watch a rewarded ad
/// - Upgrade to premium prompt
///
/// "The single highest-converting ad placement in the category."
class StreakShieldDialog extends ConsumerStatefulWidget {
  const StreakShieldDialog({super.key});

  @override
  ConsumerState<StreakShieldDialog> createState() =>
      _StreakShieldDialogState();

  /// Show the streak shield dialog. Returns true if shield was activated.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const StreakShieldDialog(),
    );
    return result ?? false;
  }
}

class _StreakShieldDialogState extends ConsumerState<StreakShieldDialog> {
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    final streak = ref.watch(streakProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final canShowAd = ref.watch(canShowRewardedAdProvider);

    return Dialog(
      backgroundColor: BauColours.cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BauSpacing.borderRadiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BauSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shield icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: BauColours.warning.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_outlined,
                size: 32,
                color: BauColours.warning,
              ),
            ),
            const SizedBox(height: BauSpacing.md),

            // Title
            Text(
              'Streak at Risk',
              style: BauTypography.headline2.copyWith(
                color: BauColours.warning,
              ),
            ),
            const SizedBox(height: BauSpacing.sm),

            // Streak info
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: BauTypography.body,
                children: [
                  const TextSpan(text: 'Your '),
                  TextSpan(
                    text: '${streak.currentStreak}-day streak',
                    style: BauTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(
                    text: ' is about to break.\nUse a shield to protect it.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: BauSpacing.lg),

            // Shield options
            if (_processing)
              const Padding(
                padding: EdgeInsets.all(BauSpacing.md),
                child: CircularProgressIndicator(),
              )
            else ...[
              // Premium shield option
              if (isPremium) ...[
                _shieldOption(
                  icon: Icons.shield,
                  label: 'Use Free Shield',
                  subtitle:
                      '${StreakState.premiumShieldsPerMonth - streak.shieldsUsedThisMonth} remaining this month',
                  enabled: streak.shieldsUsedThisMonth <
                      StreakState.premiumShieldsPerMonth,
                  onTap: _usePremiumShield,
                ),
                const SizedBox(height: BauSpacing.sm),
              ] else ...[
                // Credits option
                _shieldOption(
                  icon: Icons.toll_outlined,
                  label: 'Spend ${StreakState.shieldCreditCost} Credits',
                  subtitle:
                      'You have ${streak.builderCredits} credits',
                  enabled: streak.builderCredits >=
                      StreakState.shieldCreditCost,
                  onTap: _useCreditsShield,
                ),
                const SizedBox(height: BauSpacing.sm),

                // Rewarded ad option
                _shieldOption(
                  icon: Icons.play_circle_outline,
                  label: 'Watch a Short Video',
                  subtitle: 'Earn your shield',
                  enabled: canShowAd,
                  onTap: _useAdShield,
                ),
                const SizedBox(height: BauSpacing.sm),

                // Upgrade prompt
                _shieldOption(
                  icon: Icons.home_work_outlined,
                  label: 'Become a Full Resident',
                  subtitle: 'Get 3 free shields every month',
                  enabled: true,
                  onTap: () {
                    Navigator.of(context).pop(false);
                    // Navigate to paywall
                    Navigator.of(context).pushNamed('/paywall?context=streak_shield');
                  },
                  accent: true,
                ),
                const SizedBox(height: BauSpacing.sm),
              ],
            ],

            const SizedBox(height: BauSpacing.sm),

            // Dismiss option (lose streak)
            TextButton(
              onPressed: _processing
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: Text(
                'Let streak reset',
                style: BauTypography.bodySmall.copyWith(
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shieldOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool enabled,
    required VoidCallback onTap,
    bool accent = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          foregroundColor:
              accent ? BauColours.blueprintBlue : BauColours.darkText,
          side: BorderSide(
            color: enabled
                ? (accent ? BauColours.blueprintBlue : BauColours.gridLine)
                : BauColours.gridLine.withValues(alpha: 0.5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BauSpacing.borderRadius),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: BauSpacing.sm,
            horizontal: BauSpacing.md,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: BauSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: BauTypography.headline3),
                  Text(
                    subtitle,
                    style: BauTypography.bodySmall.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _usePremiumShield() async {
    setState(() => _processing = true);
    final success =
        await ref.read(streakProvider.notifier).usePremiumShield();
    if (mounted) {
      Navigator.of(context).pop(success);
    }
  }

  Future<void> _useCreditsShield() async {
    setState(() => _processing = true);
    final success =
        await ref.read(streakProvider.notifier).useShieldWithCredits();
    if (mounted) {
      Navigator.of(context).pop(success);
    }
  }

  Future<void> _useAdShield() async {
    setState(() => _processing = true);

    // Show the rewarded ad first
    final reward = await ref
        .read(adProvider.notifier)
        .showRewardedAd(context: 'streak_shield');

    if (reward != null) {
      final success =
          await ref.read(streakProvider.notifier).useShieldWithAd();
      if (mounted) {
        Navigator.of(context).pop(success);
      }
    } else {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }
}
