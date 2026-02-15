import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../supabase/auth_service.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/plot/home_screen.dart';
import '../../features/puzzles/puzzle_screen.dart';
import '../../features/brief/brief_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/subscription/paywall_screen.dart';

/// Provides the GoRouter instance with auth-based redirects.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final auth = authState.valueOrNull;

      if (auth == null || auth.status == AuthStatus.unknown) {
        return '/';
      }

      final isOnSplash = state.matchedLocation == '/';
      final isOnOnboarding = state.matchedLocation == '/onboarding';

      if (auth.status == AuthStatus.unauthenticated && !isOnSplash) {
        return '/';
      }

      if (auth.status == AuthStatus.authenticated && !isOnOnboarding) {
        return '/onboarding';
      }

      if (auth.status == AuthStatus.onboarded &&
          (isOnSplash || isOnOnboarding)) {
        return '/home';
      }

      return null;
    },
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
      GoRoute(
        name: 'paywall',
        path: '/paywall',
        builder: (context, state) => PaywallScreen(
          triggerContext: state.uri.queryParameters['context'],
        ),
      ),
    ],
  );
});

/// Splash screen handles auth check and shows loading.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Listen for auth state changes and navigate
    ref.listen(authProvider, (previous, next) {
      final auth = next.valueOrNull;
      if (auth == null) return;

      switch (auth.status) {
        case AuthStatus.authenticated:
          context.goNamed('onboarding');
        case AuthStatus.onboarded:
          context.goNamed('home');
        case AuthStatus.unauthenticated:
        case AuthStatus.unknown:
          break;
      }
    });

    return Scaffold(
      body: Center(
        child: authState.when(
          data: (_) => const CircularProgressIndicator(),
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
        ),
      ),
    );
  }
}
