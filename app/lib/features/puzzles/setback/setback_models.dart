/// Data models for the SETBACK (Kings-variant) puzzle.
///
/// Players place houses on a grid such that no two houses are
/// adjacent (including diagonals). Some cells may be pre-placed
/// ("fixed") or restricted.

/// The state of a single cell on the SETBACK grid.
enum SetbackCellState {
  /// Empty cell — can be toggled by the player.
  empty,

  /// Player-placed house.
  house,

  /// Pre-placed house — cannot be removed.
  fixed,

  /// Restricted zone — no house can be placed here.
  restricted;
}

/// A cell position on the grid.
class CellPosition {
  final int row;
  final int col;

  const CellPosition({required this.row, required this.col});

  factory CellPosition.fromJson(Map<String, dynamic> json) {
    return CellPosition(
      row: json['row'] as int,
      col: json['col'] as int,
    );
  }

  Map<String, dynamic> toJson() => {'row': row, 'col': col};

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CellPosition && other.row == row && other.col == col;
  }

  @override
  int get hashCode => Object.hash(row, col);
}
