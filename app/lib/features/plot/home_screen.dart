import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colours.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';
import '../brief/build_brief_card.dart';
import '../brief/puzzle_set_provider.dart';
import 'player_provider.dart';
import 'plot_painter.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(playerProvider);
    final briefAsync = ref.watch(todaysBriefProvider);

    return Scaffold(
      backgroundColor: BauColours.cream,
      body: SafeArea(
        child: playerAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (player) {
            if (player == null) {
              return const Center(child: Text('No player data'));
            }

            final accentColor = _parseColor(player.accentColour);

            return Padding(
              padding: const EdgeInsets.all(BauSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BauHouse',
                            style: BauTypography.headline1.copyWith(
                              color: BauColours.blueprintBlue,
                            ),
                          ),
                          const Text(
                            'ELMFIELD',
                            style: BauTypography.label,
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => context.goNamed('settings'),
                        icon: const Icon(Icons.settings_outlined),
                        color: BauColours.midGrey,
                      ),
                    ],
                  ),

                  const SizedBox(height: BauSpacing.md),

                  // Stats row
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.local_fire_department_outlined,
                        value: '${player.currentStreak}',
                        label: 'streak',
                        color: BauColours.terracotta,
                      ),
                      const SizedBox(width: BauSpacing.md),
                      _StatChip(
                        icon: Icons.toll_outlined,
                        value: '${player.builderCredits}',
                        label: 'credits',
                        color: BauColours.blueprintBlue,
                      ),
                    ],
                  ),

                  const SizedBox(height: BauSpacing.md),

                  // Plot view
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: BauColours.surface,
                        borderRadius:
                            BorderRadius.circular(BauSpacing.borderRadius),
                        border: Border.all(color: BauColours.gridLine),
                      ),
                      child: CustomPaint(
                        painter: PlotPainter(
                          houseStyle: player.houseStyle,
                          accentColour: accentColor,
                          streak: player.currentStreak,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: BauSpacing.md),

                  // Build Brief preview card
                  briefAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (brief) {
                      if (brief == null) {
                        return Container(
                          padding: const EdgeInsets.all(BauSpacing.md),
                          decoration: BoxDecoration(
                            color: BauColours.surface,
                            borderRadius:
                                BorderRadius.circular(BauSpacing.borderRadius),
                            border: Border.all(color: BauColours.gridLine),
                          ),
                          child: const Text(
                            'No Build Brief for today. Check back tomorrow.',
                            style: BauTypography.bodySmall,
                          ),
                        );
                      }

                      final today = DateTime.now()
                          .toUtc()
                          .toIso8601String()
                          .substring(0, 10);

                      return BuildBriefCard(
                        puzzleSet: brief.puzzleSet,
                        isCompact: true,
                        onTap: () => context.goNamed(
                          'brief',
                          pathParameters: {'date': today},
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: BauSpacing.md),

                  // Session entry points
                  Row(
                    children: [
                      Expanded(
                        child: _SessionButton(
                          title: 'Schematic',
                          subtitle: 'Session',
                          color: BauColours.blueprintBlue,
                          icon: Icons.draw_outlined,
                          onTap: () {
                            final brief = ref.read(todaysBriefProvider).valueOrNull;
                            if (brief != null &&
                                brief.schematicPuzzles.isNotEmpty) {
                              context.goNamed(
                                'puzzle',
                                pathParameters: {
                                  'id': brief.schematicPuzzles.first.id,
                                },
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: BauSpacing.md),
                      Expanded(
                        child: _SessionButton(
                          title: 'Design',
                          subtitle: 'Session',
                          color: BauColours.terracotta,
                          icon: Icons.architecture_outlined,
                          onTap: () {
                            final brief = ref.read(todaysBriefProvider).valueOrNull;
                            if (brief != null &&
                                brief.designPuzzles.isNotEmpty) {
                              context.goNamed(
                                'puzzle',
                                pathParameters: {
                                  'id': brief.designPuzzles.first.id,
                                },
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BauSpacing.md,
        vertical: BauSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(BauSpacing.borderRadiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: BauSpacing.sm),
          Text(
            value,
            style: BauTypography.headline3.copyWith(color: color),
          ),
          const SizedBox(width: BauSpacing.xs),
          Text(
            label,
            style: BauTypography.label.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _SessionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _SessionButton({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(BauSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(BauSpacing.borderRadius),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
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
        ),
      ),
    );
  }
}
