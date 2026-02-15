/// Abstract interface for all BauHouse puzzle types.
///
/// Each puzzle type (PARCEL, SETBACK, DRAFT, CONDUIT, LAMP)
/// implements this interface. The puzzle screen is generic —
/// it receives a PuzzleEngine and renders it without knowing
/// the puzzle type.
abstract class PuzzleEngine {
  /// The puzzle type identifier: 'parcel' | 'setback' | 'draft' | 'conduit' | 'lamp'
  String get puzzleType;

  /// Whether the current board state represents a valid solution
  bool get isSolved;

  /// The current board state as a serialisable map
  Map<String, dynamic> get currentState;

  /// Handle a tap on a cell at the given row and column
  void handleTap(int row, int col);

  /// Handle a drag gesture from one cell to another
  void handleDrag(int fromRow, int fromCol, int toRow, int toCol);

  /// Apply a hint — reveal one correct cell or action
  void applyHint();

  /// Reset the board to its initial state
  void reset();
}
