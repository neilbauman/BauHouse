import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colours.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';
import '../../core/subscription/subscription_provider.dart';
import '../../core/ads/ad_provider.dart';
import '../../core/ads/rewarded_ad_button.dart';
import '../streak/streak_provider.dart';
import 'archive_provider.dart';

/// Archive screen — browse and unlock past Build Briefs.
///
/// "You're visiting Birch Street as it was being built in Week 4.
/// The puzzles are identical. The narrative is intact. You're an
/// archaeologist exploring recent history, not a student doing
/// makeup homework."
class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archiveAsync = ref.watch(archiveListProvider);

    return Scaffold(
      backgroundColor: BauColours.cream,
      appBar: AppBar(
        title: const Text('Archive', style: BauTypography.headline3),
        backgroundColor: BauColours.cream,
        elevation: 0,
      ),
      body: archiveAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error loading archive: $e', style: BauTypography.body),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(BauSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      size: 48,
                      color: BauColours.midGrey.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: BauSpacing.md),
                    Text(
                      'No archived Build Briefs yet.',
                      style: BauTypography.body.copyWith(
                        color: BauColours.midGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: BauSpacing.sm),
                    Text(
                      'Past days will appear here as history.',
                      style: BauTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(BauSpacing.md),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: BauSpacing.sm),
                child: _ArchiveCard(entry: entries[index]),
              );
            },
          );
        },
      ),
    );
  }
}

class _ArchiveCard extends ConsumerWidget {
  final ArchiveEntry entry;
  const _ArchiveCard({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final set = entry.puzzleSet;

    return Container(
      decoration: BoxDecoration(
        color: BauColours.surface,
        borderRadius: BorderRadius.circular(BauSpacing.borderRadius),
        border: Border.all(
          color: entry.isComplete
              ? BauColours.sage.withValues(alpha: 0.5)
              : BauColours.gridLine,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(BauSpacing.borderRadius),
          onTap: entry.isUnlocked || isPremium
              ? () => _openBrief(context, set.scheduledDate)
              : () => _showUnlockOptions(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(BauSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        set.projectName,
                        style: BauTypography.headline3,
                      ),
                    ),
                    _StatusBadge(entry: entry, isPremium: isPremium),
                  ],
                ),
                const SizedBox(height: BauSpacing.xs),

                // Client and date
                Text(
                  '${set.clientName} · ${_formatDate(set.scheduledDate)}',
                  style: BauTypography.bodySmall,
                ),
                const SizedBox(height: BauSpacing.sm),

                // Brief intro
                Text(
                  set.briefIntro,
                  style: BauTypography.body.copyWith(
                    color: (entry.isUnlocked || isPremium)
                        ? BauColours.darkText
                        : BauColours.midGrey.withValues(alpha: 0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Progress bar if unlocked and partially complete
                if (entry.isUnlocked && !entry.isComplete) ...[
                  const SizedBox(height: BauSpacing.sm),
                  _ProgressBar(progress: entry.progress),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openBrief(BuildContext context, DateTime date) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    context.pushNamed('brief', pathParameters: {'date': dateStr});
  }

  void _showUnlockOptions(BuildContext context, WidgetRef ref) {
    final credits = ref.read(streakProvider).builderCredits;
    const unlockCost = 20;

    showModalBottomSheet(
      context: context,
      backgroundColor: BauColours.cream,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(BauSpacing.borderRadiusLg)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(BauSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: BauColours.gridLine,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: BauSpacing.lg),

            Text(
              'Unlock Archive',
              style: BauTypography.headline2,
            ),
            const SizedBox(height: BauSpacing.sm),
            Text(
              'Revisit ${entry.puzzleSet.projectName} as it was being built.',
              style: BauTypography.body.copyWith(color: BauColours.midGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BauSpacing.lg),

            // Credits option
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: credits >= unlockCost
                    ? () {
                        Navigator.of(ctx).pop();
                        _unlockWithCredits(context, ref);
                      }
                    : null,
                icon: const Icon(Icons.toll_outlined, size: 20),
                label: Text('Spend $unlockCost Credits ($credits available)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BauColours.sage,
                  side: BorderSide(
                    color: credits >= unlockCost
                        ? BauColours.sage
                        : BauColours.gridLine,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(BauSpacing.borderRadius),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: BauSpacing.sm + 2,
                    horizontal: BauSpacing.md,
                  ),
                  textStyle: BauTypography.headline3,
                ),
              ),
            ),
            const SizedBox(height: BauSpacing.sm),

            // Rewarded ad option
            RewardedAdButton(
              label: 'Watch Video to Unlock',
              adContext: 'archive_unlock',
              onRewarded: () {
                Navigator.of(ctx).pop();
                _unlockWithAd(context, ref);
              },
            ),
            const SizedBox(height: BauSpacing.lg),
          ],
        ),
      ),
    );
  }

  Future<void> _unlockWithCredits(BuildContext context, WidgetRef ref) async {
    try {
      await SupabaseClientManager.client.functions.invoke(
        'unlock-archive',
        body: {
          'puzzle_set_id': entry.puzzleSet.id,
          'unlock_method': 'credits',
        },
      );
      ref.invalidate(archiveListProvider);
      ref.invalidate(streakProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unlock failed: $e')),
        );
      }
    }
  }

  Future<void> _unlockWithAd(BuildContext context, WidgetRef ref) async {
    try {
      await SupabaseClientManager.client.functions.invoke(
        'unlock-archive',
        body: {
          'puzzle_set_id': entry.puzzleSet.id,
          'unlock_method': 'rewarded_ad',
        },
      );
      ref.invalidate(archiveListProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unlock failed: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  final ArchiveEntry entry;
  final bool isPremium;

  const _StatusBadge({required this.entry, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    if (entry.isComplete) {
      return _badge('Complete', BauColours.sage);
    }
    if (entry.isUnlocked || isPremium) {
      return _badge('Unlocked', BauColours.blueprintBlue);
    }
    return _badge('Locked', BauColours.midGrey);
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BauSpacing.sm,
        vertical: BauSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BauSpacing.borderRadiusSm),
      ),
      child: Text(
        label,
        style: BauTypography.label.copyWith(
          color: color,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: BauColours.gridLine,
            valueColor:
                const AlwaysStoppedAnimation(BauColours.blueprintBlue),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: BauSpacing.xs),
        Text(
          '${(progress * 100).round()}% complete',
          style: BauTypography.label.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}
