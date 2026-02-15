import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

/// Authentication states for the app.
enum AuthStatus {
  unknown, // Initial state, checking auth
  unauthenticated, // No session
  authenticated, // Has session, may or may not have player record
  onboarded, // Has session and completed onboarding (player record exists)
}

/// Auth state held by the provider.
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

/// Manages anonymous authentication and auth state.
class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    // Check for existing session
    final session = SupabaseClientManager.client.auth.currentSession;
    if (session != null) {
      // Check if player record exists (has completed onboarding)
      final hasPlayer = await _checkPlayerExists(session.user.id);
      return AuthState(
        status: hasPlayer ? AuthStatus.onboarded : AuthStatus.authenticated,
        user: session.user,
      );
    }

    // No session — try anonymous sign-in
    return await _signInAnonymously();
  }

  /// Sign in anonymously. Creates a Supabase anonymous auth user.
  Future<AuthState> _signInAnonymously() async {
    try {
      final response =
          await SupabaseClientManager.client.auth.signInAnonymously();
      if (response.user != null) {
        return AuthState(
          status: AuthStatus.authenticated,
          user: response.user,
        );
      }
      return const AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Anonymous sign-in returned no user',
      );
    } catch (e) {
      return AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  /// Check if a player record exists for the given user ID.
  Future<bool> _checkPlayerExists(String userId) async {
    try {
      final response = await SupabaseClientManager.client
          .from('players')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      return response != null;
    } catch (_) {
      return false;
    }
  }

  /// Called after onboarding is complete to update auth status.
  void markOnboarded() {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(status: AuthStatus.onboarded));
    }
  }

  /// Sign out (mainly for testing/debug).
  Future<void> signOut() async {
    await SupabaseClientManager.client.auth.signOut();
    state = const AsyncData(AuthState(status: AuthStatus.unauthenticated));
  }
}

/// Provider for authentication state.
final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Convenience provider for the current user ID.
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.valueOrNull?.user?.id;
});
