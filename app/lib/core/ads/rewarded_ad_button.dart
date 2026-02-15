import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colours.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import 'ad_provider.dart';

/// A styled button that shows a rewarded ad when tapped.
///
/// Displays a play icon and label. Disabled when no ad is available.
/// Calls [onRewarded] when the user successfully watches the ad.
class RewardedAdButton extends ConsumerWidget {
  final String label;
  final String adContext;
  final VoidCallback onRewarded;
  final IconData icon;

  const RewardedAdButton({
    super.key,
    required this.label,
    required this.adContext,
    required this.onRewarded,
    this.icon = Icons.play_circle_outline,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canShow = ref.watch(canShowRewardedAdProvider);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: canShow
            ? () => _handleTap(context, ref)
            : null,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: BauColours.blueprintBlue,
          side: BorderSide(
            color: canShow
                ? BauColours.blueprintBlue
                : BauColours.gridLine,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BauSpacing.borderRadius),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: BauSpacing.sm + 2,
            horizontal: BauSpacing.md,
          ),
          textStyle: BauTypography.headline3,
        ),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    final reward =
        await ref.read(adProvider.notifier).showRewardedAd(context: adContext);

    if (reward != null) {
      onRewarded();
    }
  }
}
