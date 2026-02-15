import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colours.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';
import '../../core/supabase/auth_service.dart';
import '../puzzles/conduit/conduit_widget.dart';
import '../plot/player_provider.dart';
import 'onboarding_provider.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(onboardingStepProvider);

    return Scaffold(
      backgroundColor: BauColours.cream,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: switch (step) {
            OnboardingStep.welcome => const _WelcomeStep(key: ValueKey('welcome')),
            OnboardingStep.puzzle => const _PuzzleStep(key: ValueKey('puzzle')),
            OnboardingStep.houseStyle => const _HouseStyleStep(key: ValueKey('style')),
            OnboardingStep.accentColour => const _AccentColourStep(key: ValueKey('colour')),
            OnboardingStep.complete => const _CompleteStep(key: ValueKey('complete')),
          },
        ),
      ),
    );
  }
}

/// Step 1: Welcome — "Your plot is ready"
class _WelcomeStep extends ConsumerWidget {
  const _WelcomeStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(BauSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Text(
            'Your plot is ready.',
            style: BauTypography.headline1.copyWith(
              color: BauColours.blueprintBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: BauSpacing.md),
          Text(
            "Let's build something.",
            style: BauTypography.body.copyWith(
              color: BauColours.midGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 3),
          // Simple vacant plot illustration
          Container(
            width: 200,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(
                color: BauColours.blueprintBlue.withValues(alpha: 0.3),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(BauSpacing.borderRadius),
            ),
            child: CustomPaint(
              painter: _VacantPlotPainter(),
            ),
          ),
          const Spacer(flex: 2),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref.read(onboardingStepProvider.notifier).state =
                    OnboardingStep.puzzle;
              },
              child: const Text('Connect your house'),
            ),
          ),
          const SizedBox(height: BauSpacing.lg),
        ],
      ),
    );
  }
}

/// Step 2: Guided CONDUIT puzzle — the plot-claim mechanic
class _PuzzleStep extends ConsumerWidget {
  const _PuzzleStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A simple 3x3 onboarding puzzle
    const onboardingPuzzle = {
      'width': 3,
      'height': 3,
      'cells': [
        {'type': 'corner', 'rotation': 180}, // scrambled from solved 90
        {'type': 'tee', 'rotation': 0}, // scrambled from solved 90
        {'type': 'corner', 'rotation': 90}, // scrambled from solved 180
        {'type': 'tee', 'rotation': 270}, // scrambled from solved 0
        {'type': 'cross', 'rotation': 0}, // cross always correct
        {'type': 'tee', 'rotation': 90}, // scrambled from solved 180
        {'type': 'corner', 'rotation': 270}, // scrambled from solved 0
        {'type': 'tee', 'rotation': 180}, // scrambled from solved 270
        {'type': 'corner', 'rotation': 0}, // scrambled from solved 270
      ],
    };

    return Padding(
      padding: const EdgeInsets.all(BauSpacing.md),
      child: Column(
        children: [
          const SizedBox(height: BauSpacing.lg),
          Text(
            'Connect the pipes',
            style: BauTypography.headline2.copyWith(
              color: BauColours.blueprintBlue,
            ),
          ),
          const SizedBox(height: BauSpacing.sm),
          Text(
            'Tap each pipe to rotate it.\nConnect them all to claim your plot.',
            style: BauTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: BauSpacing.md),
          Expanded(
            child: ConduitPuzzleWidget(
              gridData: onboardingPuzzle,
              onSolved: () {
                ref.read(onboardingStepProvider.notifier).state =
                    OnboardingStep.houseStyle;
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Step 3: House style selection
class _HouseStyleStep extends ConsumerWidget {
  const _HouseStyleStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedHouseStyleProvider);

    return Padding(
      padding: const EdgeInsets.all(BauSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Text(
            'Choose your house',
            style: BauTypography.headline2.copyWith(
              color: BauColours.blueprintBlue,
            ),
          ),
          const SizedBox(height: BauSpacing.sm),
          const Text(
            'Pick the style that feels like home.',
            style: BauTypography.bodySmall,
          ),
          const SizedBox(height: BauSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _HouseStyleCard(
                style: 'classic',
                label: 'Classic',
                icon: Icons.home_outlined,
                isSelected: selected == 'classic',
                onTap: () => ref
                    .read(selectedHouseStyleProvider.notifier)
                    .state = 'classic',
              ),
              _HouseStyleCard(
                style: 'modern',
                label: 'Modern',
                icon: Icons.apartment_outlined,
                isSelected: selected == 'modern',
                onTap: () => ref
                    .read(selectedHouseStyleProvider.notifier)
                    .state = 'modern',
              ),
              _HouseStyleCard(
                style: 'cottage',
                label: 'Cottage',
                icon: Icons.cottage_outlined,
                isSelected: selected == 'cottage',
                onTap: () => ref
                    .read(selectedHouseStyleProvider.notifier)
                    .state = 'cottage',
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selected != null
                  ? () {
                      ref.read(onboardingStepProvider.notifier).state =
                          OnboardingStep.accentColour;
                    }
                  : null,
              child: const Text('Next'),
            ),
          ),
          const SizedBox(height: BauSpacing.lg),
        ],
      ),
    );
  }
}

/// Step 4: Accent colour selection
class _AccentColourStep extends ConsumerWidget {
  const _AccentColourStep({super.key});

  static const _colours = [
    _AccentOption('Terracotta', '#C0583A', Color(0xFFC0583A)),
    _AccentOption('Blueprint', '#1B4F8A', Color(0xFF1B4F8A)),
    _AccentOption('Sage', '#5A7A5E', Color(0xFF5A7A5E)),
    _AccentOption('Ochre', '#D4A843', Color(0xFFD4A843)),
    _AccentOption('Slate', '#4A5568', Color(0xFF4A5568)),
    _AccentOption('Plum', '#7B4B8A', Color(0xFF7B4B8A)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedAccentColourProvider);

    return Padding(
      padding: const EdgeInsets.all(BauSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Text(
            'Pick your colour',
            style: BauTypography.headline2.copyWith(
              color: BauColours.blueprintBlue,
            ),
          ),
          const SizedBox(height: BauSpacing.sm),
          const Text(
            'This will accent your plot and house.',
            style: BauTypography.bodySmall,
          ),
          const SizedBox(height: BauSpacing.xl),
          Wrap(
            spacing: BauSpacing.md,
            runSpacing: BauSpacing.md,
            alignment: WrapAlignment.center,
            children: _colours
                .map((opt) => _ColourChip(
                      option: opt,
                      isSelected: selected == opt.hex,
                      onTap: () => ref
                          .read(selectedAccentColourProvider.notifier)
                          .state = opt.hex,
                    ))
                .toList(),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selected != null
                  ? () => _completeOnboarding(ref, context)
                  : null,
              child: const Text('Build my house'),
            ),
          ),
          const SizedBox(height: BauSpacing.lg),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding(WidgetRef ref, BuildContext context) async {
    final userId = ref.read(currentUserIdProvider);
    final houseStyle = ref.read(selectedHouseStyleProvider);
    final accentColour = ref.read(selectedAccentColourProvider);

    if (userId == null || houseStyle == null || accentColour == null) return;

    ref.read(onboardingStepProvider.notifier).state = OnboardingStep.complete;

    try {
      await createPlayer(
        userId: userId,
        houseStyle: houseStyle,
        accentColour: accentColour,
      );

      ref.read(authProvider.notifier).markOnboarded();
      ref.invalidate(playerProvider);

      if (context.mounted) {
        context.goNamed('home');
      }
    } catch (e) {
      // Revert to colour step on failure
      ref.read(onboardingStepProvider.notifier).state =
          OnboardingStep.accentColour;
    }
  }
}

/// Step 5: Completion — brief animation before redirect
class _CompleteStep extends StatelessWidget {
  const _CompleteStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home,
            size: 64,
            color: BauColours.blueprintBlue,
          ),
          const SizedBox(height: BauSpacing.md),
          Text(
            'Building your house...',
            style: BauTypography.headline3.copyWith(
              color: BauColours.blueprintBlue,
            ),
          ),
          const SizedBox(height: BauSpacing.lg),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }
}

// --- Helper widgets ---

class _HouseStyleCard extends StatelessWidget {
  final String style;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _HouseStyleCard({
    required this.style,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        padding: const EdgeInsets.all(BauSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? BauColours.blueprintBlue.withValues(alpha: 0.1)
              : BauColours.surface,
          borderRadius: BorderRadius.circular(BauSpacing.borderRadius),
          border: Border.all(
            color: isSelected
                ? BauColours.blueprintBlue
                : BauColours.gridLine,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: isSelected ? BauColours.blueprintBlue : BauColours.midGrey),
            const SizedBox(height: BauSpacing.sm),
            Text(
              label,
              style: BauTypography.bodySmall.copyWith(
                color: isSelected ? BauColours.blueprintBlue : BauColours.midGrey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentOption {
  final String name;
  final String hex;
  final Color color;
  const _AccentOption(this.name, this.hex, this.color);
}

class _ColourChip extends StatelessWidget {
  final _AccentOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColourChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: option.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? BauColours.darkText : Colors.transparent,
                width: 3,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : null,
          ),
          const SizedBox(height: BauSpacing.xs),
          Text(
            option.name,
            style: BauTypography.label.copyWith(
              color: isSelected ? BauColours.darkText : BauColours.midGrey,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple painter for the vacant plot illustration.
class _VacantPlotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = BauColours.blueprintBlue.withValues(alpha: 0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Dashed border effect — simple grid lines
    const spacing = 20.0;
    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Plot marker in center
    final center = Offset(size.width / 2, size.height / 2);
    final markerPaint = Paint()
      ..color = BauColours.blueprintBlue.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 15, markerPaint);
    canvas.drawLine(
      Offset(center.dx - 8, center.dy),
      Offset(center.dx + 8, center.dy),
      markerPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 8),
      Offset(center.dx, center.dy + 8),
      markerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
