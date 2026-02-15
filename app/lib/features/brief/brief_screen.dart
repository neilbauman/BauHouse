import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colours.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';
import '../../shared/models/puzzle.dart';
import 'build_brief_card.dart';
import 'puzzle_set_provider.dart';

/// Full-screen view of a Build Brief for a given date.
///
/// Shows the narrative card with full intro text, followed by the
/// puzzle task list for each session. Players can tap a task to
/// jump directly to that puzzle.
class BriefScreen extends ConsumerWidget {
  final String date;

  const BriefScreen({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefAsync = ref.watch(briefByDateProvider(date));

    return Scaffold(
      backgroundColor: BauColours.cream,
      appBar: AppBar(
        title: const Text('Build Brief', style: BauTypography.headline3),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: briefAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: BauColours.midGrey),
                const SizedBox(height: BauSpacing.md),
                Text('Could not load brief', style: BauTypography.body),
                const SizedBox(height: BauSpacing.sm),
                Text('$e', style: BauTypography.bodySmall),
              ],
            ),
          ),
          data: (brief) {
            if (brief == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 48, color: BauColours.midGrey),
                    const SizedBox(height: BauSpacing.md),
                    Text(
                      'No Build Brief for $date',
                      style: BauTypography.body,
                    ),
                    const SizedBox(height: BauSpacing.sm),
                    const Text(
                      'Check back tomorrow for a new project.',
                      style: BauTypography.bodySmall,
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(BauSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full narrative card
                  BuildBriefCard(
                    puzzleSet: brief.puzzleSet,
                    schematicCompleted: 0, // TODO: wire up from completions
                    designCompleted: 0,
                  ),

                  const SizedBox(height: BauSpacing.lg),

                  // Schematic Session task list
                  _SectionHeader(
                    title: 'Schematic Session',
                    subtitle: '${brief.schematicPuzzles.length} puzzles',
                    color: BauColours.blueprintBlue,
                    icon: Icons.draw_outlined,
                  ),
                  const SizedBox(height: BauSpacing.sm),

                  ...brief.schematicPuzzles.map((puzzle) =>
                      _PuzzleTaskTile(
                        puzzle: puzzle,
                        onTap: () => context.goNamed(
                          'puzzle',
                          pathParameters: {'id': puzzle.id},
                        ),
                      )),

                  const SizedBox(height: BauSpacing.lg),

                  // Design Session task list
                  _SectionHeader(
                    title: 'Design Session',
                    subtitle: '${brief.designPuzzles.length} puzzles',
                    color: BauColours.terracotta,
                    icon: Icons.architecture_outlined,
                  ),
                  const SizedBox(height: BauSpacing.sm),

                  ...brief.designPuzzles.map((puzzle) =>
                      _PuzzleTaskTile(
                        puzzle: puzzle,
                        onTap: () => context.goNamed(
                          'puzzle',
                          pathParameters: {'id': puzzle.id},
                        ),
                      )),

                  const SizedBox(height: BauSpacing.xl),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(BauSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius:
                BorderRadius.circular(BauSpacing.borderRadiusSm),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: BauSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: BauTypography.headline3.copyWith(color: color),
            ),
            Text(
              subtitle,
              style: BauTypography.label.copyWith(color: color),
            ),
          ],
        ),
      ],
    );
  }
}

class _PuzzleTaskTile extends StatelessWidget {
  final Puzzle puzzle;
  final VoidCallback? onTap;

  const _PuzzleTaskTile({
    required this.puzzle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final puzzleTypeLabel = _puzzleTypeLabel(puzzle.puzzleType);
    final slotColor = puzzle.isSchematic
        ? BauColours.blueprintBlue
        : BauColours.terracotta;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: BauSpacing.sm),
        padding: const EdgeInsets.all(BauSpacing.md),
        decoration: BoxDecoration(
          color: BauColours.surface,
          borderRadius: BorderRadius.circular(BauSpacing.borderRadiusSm),
          border: Border.all(color: BauColours.gridLine),
        ),
        child: Row(
          children: [
            // Slot number
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: slotColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${puzzle.slotNumber}',
                style: BauTypography.label.copyWith(
                  color: slotColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: BauSpacing.md),

            // Task info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    puzzle.taskDescription,
                    style: BauTypography.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    puzzleTypeLabel,
                    style: BauTypography.label,
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.chevron_right,
              size: 20,
              color: BauColours.midGrey,
            ),
          ],
        ),
      ),
    );
  }

  String _puzzleTypeLabel(String type) {
    switch (type) {
      case 'parcel':
        return 'PARCEL — Land Division';
      case 'setback':
        return 'SETBACK — Placement';
      case 'draft':
        return 'DRAFT — Blueprint';
      case 'conduit':
        return 'CONDUIT — Services';
      case 'lamp':
        return 'LAMP — Illumination';
      default:
        return type.toUpperCase();
    }
  }
}
