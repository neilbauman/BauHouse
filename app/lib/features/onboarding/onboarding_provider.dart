import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Steps in the onboarding flow.
enum OnboardingStep {
  welcome,
  puzzle,
  houseStyle,
  accentColour,
  complete,
}

/// Current step in onboarding.
final onboardingStepProvider = StateProvider<OnboardingStep>(
  (ref) => OnboardingStep.welcome,
);

/// Selected house style during onboarding.
final selectedHouseStyleProvider = StateProvider<String?>(
  (ref) => null,
);

/// Selected accent colour during onboarding.
final selectedAccentColourProvider = StateProvider<String?>(
  (ref) => null,
);
