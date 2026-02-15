import 'package:flutter/material.dart';
import '../../core/theme/colours.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';
import '../../shared/models/puzzle_set.dart';

/// A narrative card displaying a Build Brief's story and progress.
///
/// Used on the home screen as a preview, and on the brief screen as
/// the full narrative header. The card follows the spec's vision:
/// project name, client name, narrative intro, and a warm construction-themed
/// visual identity.
class BuildBriefCard extends StatelessWidget {
  final PuzzleSet puzzleSet;
  final int schematicCompleted;
  final int schematicTotal;
  final int designCompleted;
  final int designTotal;
  final bool isCompact;
  final VoidCallback? onTap;

  const BuildBriefCard({
    super.key,
    required this.puzzleSet,
    this.schematicCompleted = 0,
    this.schematicTotal = 5,
    this.designCompleted = 0,
    this.designTotal = 5,
    this.isCompact = false,
    this.onTap,
  });

  bool get isFullyComplete =>
      schematicCompleted >= schematicTotal &&
      designCompleted >= designTotal;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(BauSpacing.md),
        decoration: BoxDecoration(
          color: BauColours.surface,
          borderRadius: BorderRadius.circular(BauSpacing.borderRadius),
          border: Border.all(
            color: isFullyComplete
                ? BauColours.sage.withValues(alpha: 0.5)
                : BauColours.gridLine,
          ),
          boxShadow: [
            BoxShadow(
              color: BauColours.darkText.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Week label
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: BauSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: BauColours.blueprintBlue.withValues(alpha: 0.08),
                borderRadius:
                    BorderRadius.circular(BauSpacing.borderRadiusSm),
              ),
              child: Text(
                'WEEK ${puzzleSet.weekNumber}',
                style: BauTypography.label.copyWith(
                  color: BauColours.blueprintBlue,
                  fontSize: 10,
                ),
              ),
            ),

            const SizedBox(height: BauSpacing.sm),

            // Project name
            Text(
              puzzleSet.projectName,
              style: BauTypography.headline2,
            ),

            const SizedBox(height: BauSpacing.xs),

            // Client name
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: BauColours.midGrey,
                ),
                const SizedBox(width: BauSpacing.xs),
                Text(
                  puzzleSet.clientName,
                  style: BauTypography.bodySmall,
                ),
              ],
            ),

            const SizedBox(height: BauSpacing.sm),

            // Brief intro
            Text(
              puzzleSet.briefIntro,
              style: BauTypography.body,
              maxLines: isCompact ? 2 : null,
              overflow: isCompact ? TextOverflow.ellipsis : null,
            ),

            if (!isCompact) ...[
              const SizedBox(height: BauSpacing.md),

              // Session progress
              _SessionProgress(
                label: 'Schematic Session',
                completed: schematicCompleted,
                total: schematicTotal,
                color: BauColours.blueprintBlue,
                icon: Icons.draw_outlined,
              ),

              const SizedBox(height: BauSpacing.sm),

              _SessionProgress(
                label: 'Design Session',
                completed: designCompleted,
                total: designTotal,
                color: BauColours.terracotta,
                icon: Icons.architecture_outlined,
              ),
            ],

            // Completion text
            if (isFullyComplete) ...[
              const SizedBox(height: BauSpacing.md),
              Container(
                padding: const EdgeInsets.all(BauSpacing.md),
                decoration: BoxDecoration(
                  color: BauColours.sage.withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(BauSpacing.borderRadiusSm),
                  border: Border.all(
                    color: BauColours.sage.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_stories_outlined,
                      size: 20,
                      color: BauColours.sage,
                    ),
                    const SizedBox(width: BauSpacing.sm),
                    Expanded(
                      child: Text(
                        puzzleSet.completionText,
                        style: BauTypography.body.copyWith(
                          color: BauColours.sage,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (isCompact && onTap != null) ...[
              const SizedBox(height: BauSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View Brief',
                    style: BauTypography.label.copyWith(
                      color: BauColours.blueprintBlue,
                    ),
                  ),
                  const SizedBox(width: BauSpacing.xs),
                  Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: BauColours.blueprintBlue,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A single session's progress indicator.
class _SessionProgress extends StatelessWidget {
  final String label;
  final int completed;
  final int total;
  final Color color;
  final IconData icon;

  const _SessionProgress({
    required this.label,
    required this.completed,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = completed >= total;
    final progress = total > 0 ? completed / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: BauSpacing.xs),
            Text(
              label,
              style: BauTypography.label.copyWith(color: color),
            ),
            const Spacer(),
            if (isComplete)
              Icon(Icons.check_circle, size: 16, color: BauColours.sage)
            else
              Text(
                '$completed/$total',
                style: BauTypography.bodySmall.copyWith(color: color),
              ),
          ],
        ),
        const SizedBox(height: BauSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(
              isComplete ? BauColours.sage : color,
            ),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
