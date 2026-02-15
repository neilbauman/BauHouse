import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase/supabase_client.dart';
import '../../shared/models/puzzle_set.dart';
import '../../shared/models/puzzle.dart';

/// Holds a puzzle set and its puzzles for a given date.
class DailyBrief {
  final PuzzleSet puzzleSet;
  final List<Puzzle> schematicPuzzles;
  final List<Puzzle> designPuzzles;

  const DailyBrief({
    required this.puzzleSet,
    required this.schematicPuzzles,
    required this.designPuzzles,
  });

  /// All puzzles in order: schematic first, then design.
  List<Puzzle> get allPuzzles => [...schematicPuzzles, ...designPuzzles];

  /// Total puzzle count.
  int get totalPuzzles => schematicPuzzles.length + designPuzzles.length;
}

/// Fetches today's puzzle set and its puzzles.
/// Queries the puzzles_client view to exclude solution_data.
final todaysBriefProvider = FutureProvider<DailyBrief?>((ref) async {
  final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
  return await fetchBriefForDate(today);
});

/// Fetches a puzzle set for a specific date string (YYYY-MM-DD).
Future<DailyBrief?> fetchBriefForDate(String dateStr) async {
  // Fetch the puzzle set for the given date
  final setResponse = await SupabaseClientManager.client
      .from('puzzle_sets')
      .select()
      .eq('scheduled_date', dateStr)
      .maybeSingle();

  if (setResponse == null) return null;

  final puzzleSet = PuzzleSet.fromJson(setResponse);

  // Fetch puzzles via the client view (no solution_data)
  // Ordered by mode (schematic first) then slot_number
  final puzzlesResponse = await SupabaseClientManager.client
      .from('puzzles_client')
      .select()
      .eq('puzzle_set_id', puzzleSet.id)
      .order('mode')
      .order('slot_number');

  final puzzles = (puzzlesResponse as List)
      .map((p) => Puzzle.fromJson(p as Map<String, dynamic>))
      .toList();

  final schematic = puzzles.where((p) => p.isSchematic).toList()
    ..sort((a, b) => a.slotNumber.compareTo(b.slotNumber));
  final design = puzzles.where((p) => p.isDesign).toList()
    ..sort((a, b) => a.slotNumber.compareTo(b.slotNumber));

  return DailyBrief(
    puzzleSet: puzzleSet,
    schematicPuzzles: schematic,
    designPuzzles: design,
  );
}

/// Fetches a specific puzzle set by date parameter (for archive access).
final briefByDateProvider =
    FutureProvider.family<DailyBrief?, String>((ref, date) async {
  return await fetchBriefForDate(date);
});
