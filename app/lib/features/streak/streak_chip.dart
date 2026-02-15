import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colours.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';
import 'streak_provider.dart';

/// Compact streak display chip for the home screen.
///
/// Shows the current streak count with a flame icon.
/// Turns amber when the streak is at risk.
class StreakChip extends ConsumerWidget {
  const StreakChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);

    final color = streak.streakAtRisk
        ? BauColours.warning
        : (streak.currentStreak > 0 ? BauColours.terracotta : BauColours.midGrey);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BauSpacing.sm + 2,
        vertical: BauSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BauSpacing.borderRadiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            streak.streakAtRisk ? Icons.warning_amber_rounded : Icons.local_fire_department,
            size: 16,
            color: color,
          ),
          const SizedBox(width: BauSpacing.xs),
          Text(
            '${streak.currentStreak}',
            style: BauTypography.headline3.copyWith(
              color: color,
              fontSize: 15,
            ),
          ),
          if (streak.streakAtRisk) ...[
            const SizedBox(width: BauSpacing.xs),
            Icon(
              Icons.shield_outlined,
              size: 14,
              color: color,
            ),
          ],
        ],
      ),
    );
  }
}

/// Builder's Credit display chip.
class CreditChip extends ConsumerWidget {
  const CreditChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credits = ref.watch(streakProvider).builderCredits;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BauSpacing.sm + 2,
        vertical: BauSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: BauColours.sage.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BauSpacing.borderRadiusSm),
        border: Border.all(color: BauColours.sage.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.toll_outlined,
            size: 16,
            color: BauColours.sage,
          ),
          const SizedBox(width: BauSpacing.xs),
          Text(
            '$credits',
            style: BauTypography.headline3.copyWith(
              color: BauColours.sage,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
