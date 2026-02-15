// Data models for the DRAFT (Nonogram) puzzle.
//
// Players fill cells to reveal a hidden blueprint pattern.
// Clues along each row and column indicate contiguous groups
// of filled cells.

/// The state of a single cell in the DRAFT grid.
enum DraftCellState {
  /// Unfilled — default state.
  empty,

  /// Filled by the player.
  filled,

  /// Marked as intentionally empty (player convenience, not required).
  marked;
}
