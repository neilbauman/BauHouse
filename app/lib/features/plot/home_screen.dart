import 'package:flutter/material.dart';
import '../../core/theme/colours.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BauColours.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BauSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BauHouse',
                style: BauTypography.headline1.copyWith(
                  color: BauColours.blueprintBlue,
                ),
              ),
              const SizedBox(height: BauSpacing.xs),
              const Text(
                'Elmfield',
                style: BauTypography.label,
              ),
              const SizedBox(height: BauSpacing.lg),
              // Placeholder for plot view
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: BauColours.surface,
                    borderRadius:
                        BorderRadius.circular(BauSpacing.borderRadius),
                    border: Border.all(color: BauColours.gridLine),
                  ),
                  child: const Center(
                    child: Text(
                      'Your plot',
                      style: BauTypography.bodySmall,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: BauSpacing.md),
              // Session entry points placeholder
              Row(
                children: [
                  Expanded(
                    child: _SessionCard(
                      title: 'Schematic',
                      subtitle: 'Session',
                      color: BauColours.blueprintBlue,
                    ),
                  ),
                  const SizedBox(width: BauSpacing.md),
                  Expanded(
                    child: _SessionCard(
                      title: 'Design',
                      subtitle: 'Session',
                      color: BauColours.terracotta,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;

  const _SessionCard({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BauSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BauSpacing.borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: BauTypography.headline3.copyWith(color: color),
          ),
          const SizedBox(height: BauSpacing.xs),
          Text(
            subtitle,
            style: BauTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}
