import 'package:flutter/material.dart';
import '../../core/theme/colours.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BauColours.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BauSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Your plot is ready.',
                style: BauTypography.headline1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: BauSpacing.sm),
              Text(
                "Let's build something.",
                style: BauTypography.body.copyWith(
                  color: BauColours.midGrey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: BauSpacing.xxl),
              // Placeholder for the guided CONDUIT puzzle
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: BauColours.surface,
                  borderRadius: BorderRadius.circular(BauSpacing.borderRadius),
                  border: Border.all(color: BauColours.gridLine),
                ),
                child: const Center(
                  child: Text(
                    'Guided puzzle will appear here',
                    style: BauTypography.bodySmall,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
