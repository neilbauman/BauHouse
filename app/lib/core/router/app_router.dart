import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/plot/home_screen.dart';
import '../../features/puzzles/puzzle_screen.dart';
import '../../features/brief/brief_screen.dart';
import '../../features/settings/settings_screen.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        name: 'splash',
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        name: 'onboarding',
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        name: 'home',
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        name: 'brief',
        path: '/brief/:date',
        builder: (context, state) => BriefScreen(
          date: state.pathParameters['date']!,
        ),
      ),
      GoRoute(
        name: 'puzzle',
        path: '/puzzle/:id',
        builder: (context, state) => PuzzleScreen(
          puzzleId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        name: 'settings',
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}

/// Splash screen handles auth check and routing
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
