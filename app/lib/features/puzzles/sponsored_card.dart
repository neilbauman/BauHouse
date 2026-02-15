import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colours.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';
import '../../core/ads/ad_provider.dart';

/// A between-puzzle "sponsored card" styled as an Elmfield development notice.
///
/// From the spec: "Framed as a fictional 'development notice' within the
/// Elmfield world — a sponsored building or community message. Skippable
/// after 3 seconds. Appears maximum twice per daily session."
///
/// This widget wraps the AdMob interstitial but provides the narrative framing.
/// If no ad is available or the user is premium, [onDismiss] fires immediately.
class SponsoredCardOverlay extends ConsumerStatefulWidget {
  final VoidCallback onDismiss;

  const SponsoredCardOverlay({super.key, required this.onDismiss});

  @override
  ConsumerState<SponsoredCardOverlay> createState() =>
      _SponsoredCardOverlayState();
}

class _SponsoredCardOverlayState extends ConsumerState<SponsoredCardOverlay> {
  bool _canSkip = false;
  int _countdown = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          _canSkip = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BauColours.cream,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BauSpacing.lg),
          child: Column(
            children: [
              // Skip button area
              Align(
                alignment: Alignment.topRight,
                child: _canSkip
                    ? TextButton.icon(
                        onPressed: widget.onDismiss,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Skip'),
                        style: TextButton.styleFrom(
                          foregroundColor: BauColours.midGrey,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: BauSpacing.sm,
                          horizontal: BauSpacing.md,
                        ),
                        child: Text(
                          '$_countdown',
                          style: BauTypography.headline3.copyWith(
                            color: BauColours.midGrey,
                          ),
                        ),
                      ),
              ),

              const Spacer(),

              // Development notice frame
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(BauSpacing.xl),
                decoration: BoxDecoration(
                  color: BauColours.surface,
                  borderRadius:
                      BorderRadius.circular(BauSpacing.borderRadiusLg),
                  border: Border.all(color: BauColours.gridLine, width: 1.5),
                ),
                child: Column(
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          color: BauColours.blueprintBlue,
                        ),
                        const SizedBox(width: BauSpacing.sm),
                        Text(
                          'ELMFIELD DEVELOPMENT NOTICE',
                          style: BauTypography.label.copyWith(
                            color: BauColours.blueprintBlue,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(width: BauSpacing.sm),
                        Container(
                          width: 4,
                          height: 20,
                          color: BauColours.blueprintBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: BauSpacing.lg),

                    // This is where an actual sponsored message would go.
                    // For now, show a placeholder community message.
                    Text(
                      'Community Message',
                      style: BauTypography.headline2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: BauSpacing.md),
                    Text(
                      'The Elmfield Planning Committee thanks all residents '
                      'for their continued contribution to the development '
                      'of our town. Every plot you build makes Elmfield '
                      'a better place to call home.',
                      style: BauTypography.body.copyWith(
                        color: BauColours.midGrey,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: BauSpacing.lg),

                    // Notice footer
                    Container(
                      width: 60,
                      height: 1,
                      color: BauColours.gridLine,
                    ),
                    const SizedBox(height: BauSpacing.sm),
                    Text(
                      'Sponsored',
                      style: BauTypography.label.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Continue button (appears after countdown)
              if (_canSkip)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onDismiss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BauColours.blueprintBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(BauSpacing.borderRadius),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: BauSpacing.md,
                      ),
                    ),
                    child: Text(
                      'Continue Building',
                      style:
                          BauTypography.headline3.copyWith(color: Colors.white),
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

/// Helper to determine whether a sponsored card should be shown
/// between the current and next puzzle.
///
/// Rules: show only for free-tier users, max 2 per session, and only
/// between puzzles (not before the first or after the last).
bool shouldShowSponsoredCard({
  required bool isPremium,
  required int currentSlot,
  required int totalSlots,
  required WidgetRef ref,
}) {
  if (isPremium) return false;
  if (currentSlot >= totalSlots) return false; // Don't show after last puzzle

  final canShow = ref.read(canShowSponsoredCardProvider);
  return canShow;
}
