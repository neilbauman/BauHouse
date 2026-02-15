import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase/supabase_client.dart';

/// Response from the complete-puzzle edge function.
class CompletionResult {
  final bool success;
  final int creditsAwarded;
  final bool streakUpdated;
  final int newStreak;
  final bool dailyComplete;
  final bool schematicComplete;
  final bool alreadyCompleted;
  final String? error;

  const CompletionResult({
    required this.success,
    this.creditsAwarded = 0,
    this.streakUpdated = false,
    this.newStreak = 0,
    this.dailyComplete = false,
    this.schematicComplete = false,
    this.alreadyCompleted = false,
    this.error,
  });

  factory CompletionResult.fromJson(Map<String, dynamic> json) {
    return CompletionResult(
      success: json['success'] as bool? ?? false,
      creditsAwarded: json['credits_awarded'] as int? ?? 0,
      streakUpdated: json['streak_updated'] as bool? ?? false,
      newStreak: json['new_streak'] as int? ?? 0,
      dailyComplete: json['daily_complete'] as bool? ?? false,
      schematicComplete: json['schematic_complete'] as bool? ?? false,
      alreadyCompleted: json['already_completed'] as bool? ?? false,
      error: json['error'] as String?,
    );
  }
}

/// Service for submitting puzzle completions to the edge function.
class PuzzleCompletionService {
  /// Submit a puzzle completion for server-side validation.
  static Future<CompletionResult> completePuzzle({
    required String puzzleId,
    required Map<String, dynamic> solutionAttempt,
    required String difficultyPlayed,
    required int solveSeconds,
  }) async {
    try {
      final response = await SupabaseClientManager.client.functions.invoke(
        'complete-puzzle',
        body: {
          'puzzle_id': puzzleId,
          'solution_attempt': solutionAttempt,
          'difficulty_played': difficultyPlayed,
          'solve_seconds': solveSeconds,
        },
      );

      if (response.data != null) {
        return CompletionResult.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      return const CompletionResult(
        success: false,
        error: 'Empty response from server',
      );
    } catch (e) {
      return CompletionResult(
        success: false,
        error: e.toString(),
      );
    }
  }
}

/// Provider for easy access to the completion service.
final puzzleCompletionServiceProvider = Provider<PuzzleCompletionService>(
  (ref) => PuzzleCompletionService(),
);
