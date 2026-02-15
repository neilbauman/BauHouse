/// Data models for the LAMP (Light Up / Akari) puzzle.
///
/// Players place light bulbs on empty cells to illuminate the entire grid.
/// Lights shine in all four cardinal directions until blocked by a black cell
/// or the grid edge. Numbered black cells indicate exactly how many adjacent
/// (orthogonal) lights are required.

/// The type of a cell in the initial grid.
enum LampCellType {
  /// An empty cell that can receive a light or be illuminated.
  empty,

  /// A black (wall) cell. May optionally have a numeric clue.
  black;
}

/// Initial grid cell — either empty or black with an optional clue.
class LampGridCell {
  final LampCellType type;

  /// For black cells: the number of adjacent lights required (null = no clue).
  final int? clue;

  const LampGridCell({required this.type, this.clue});

  factory LampGridCell.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    return LampGridCell(
      type: typeStr == 'black' ? LampCellType.black : LampCellType.empty,
      clue: json['clue'] as int?,
    );
  }
}

/// Runtime state of an empty cell during play.
enum LampPlayState {
  /// Empty and not illuminated.
  dark,

  /// Empty but illuminated by a light in the same row/column.
  lit,

  /// Contains a player-placed light bulb.
  light,

  /// A light that conflicts with another light (they can see each other).
  lightConflict;
}
