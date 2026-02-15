/// Data model for a single puzzle within a puzzle set.
/// Note: solution_data is NEVER included in client-side data.
class Puzzle {
  final String id;
  final String puzzleSetId;
  final String puzzleType;
  final String mode;
  final int slotNumber;
  final double difficultyScore;
  final Map<String, dynamic> gridData;
  final String taskDescription;
  final int? avgSolveSeconds;
  final DateTime createdAt;

  const Puzzle({
    required this.id,
    required this.puzzleSetId,
    required this.puzzleType,
    required this.mode,
    required this.slotNumber,
    required this.difficultyScore,
    required this.gridData,
    required this.taskDescription,
    this.avgSolveSeconds,
    required this.createdAt,
  });

  factory Puzzle.fromJson(Map<String, dynamic> json) {
    return Puzzle(
      id: json['id'] as String,
      puzzleSetId: json['puzzle_set_id'] as String,
      puzzleType: json['puzzle_type'] as String,
      mode: json['mode'] as String,
      slotNumber: json['slot_number'] as int,
      difficultyScore: (json['difficulty_score'] as num).toDouble(),
      gridData: json['grid_data'] as Map<String, dynamic>,
      taskDescription: json['task_description'] as String,
      avgSolveSeconds: json['avg_solve_seconds'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Whether this is in the Schematic session.
  bool get isSchematic => mode == 'schematic';

  /// Whether this is in the Design session.
  bool get isDesign => mode == 'design';
}
