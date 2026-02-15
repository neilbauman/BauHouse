import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/supabase/auth_service.dart';
import '../../shared/models/puzzle_set.dart';

/// An archive entry: a past puzzle set with unlock status.
class ArchiveEntry {
  final PuzzleSet puzzleSet;
  final bool isUnlocked;
  final int completedCount;
  final int totalPuzzles;

  const ArchiveEntry({
    required this.puzzleSet,
    required this.isUnlocked,
    required this.completedCount,
    this.totalPuzzles = 10,
  });

  /// Percentage of puzzles completed (0.0 to 1.0).
  double get progress =>
      totalPuzzles > 0 ? completedCount / totalPuzzles : 0.0;

  /// Whether all puzzles are completed.
  bool get isComplete => completedCount >= totalPuzzles;

  /// How many days ago this set was scheduled.
  int get daysAgo {
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    return today.difference(puzzleSet.scheduledDate).inDays;
  }
}

/// Fetches the archive list of past puzzle sets with unlock status.
final archiveListProvider =
    FutureProvider<List<ArchiveEntry>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final today =
      DateTime.now().toUtc().toIso8601String().substring(0, 10);

  // Fetch all past puzzle sets (before today)
  final setsData = await SupabaseClientManager.client
      .from('puzzle_sets')
      .select()
      .lt('scheduled_date', today)
      .order('scheduled_date', ascending: false)
      .limit(60);

  if ((setsData as List).isEmpty) return [];

  final sets =
      setsData.map((d) => PuzzleSet.fromJson(d)).toList();

  // Fetch all completions for this player
  final completionsData = await SupabaseClientManager.client
      .from('player_completions')
      .select('puzzle_id')
      .eq('player_id', userId);

  final completedPuzzleIds =
      (completionsData as List).map((d) => d['puzzle_id'] as String).toSet();

  // Fetch all unlocked archives for this player
  final unlocksData = await SupabaseClientManager.client
      .from('archive_unlocks')
      .select('puzzle_set_id')
      .eq('player_id', userId);

  final unlockedSetIds =
      (unlocksData as List).map((d) => d['puzzle_set_id'] as String).toSet();

  // Fetch puzzles for each set to count completions
  final setIds = sets.map((s) => s.id).toList();
  final puzzlesData = await SupabaseClientManager.client
      .from('puzzles_client')
      .select('id, puzzle_set_id')
      .inFilter('puzzle_set_id', setIds);

  // Group puzzles by set
  final puzzlesBySet = <String, List<String>>{};
  for (final p in puzzlesData as List) {
    final setId = p['puzzle_set_id'] as String;
    puzzlesBySet.putIfAbsent(setId, () => []);
    puzzlesBySet[setId]!.add(p['id'] as String);
  }

  return sets.map((set) {
    final puzzleIds = puzzlesBySet[set.id] ?? [];
    final completed =
        puzzleIds.where((id) => completedPuzzleIds.contains(id)).length;

    // A set is "unlocked" if: it has completions, or it was explicitly unlocked
    final isUnlocked =
        unlockedSetIds.contains(set.id) || completed > 0;

    return ArchiveEntry(
      puzzleSet: set,
      isUnlocked: isUnlocked,
      completedCount: completed,
      totalPuzzles: puzzleIds.length,
    );
  }).toList();
});
