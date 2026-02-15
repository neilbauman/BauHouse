import '../puzzle_engine.dart';
import 'setback_models.dart';

/// Engine for the SETBACK (Kings-variant) puzzle.
///
/// The player must place exactly [houseCount] houses on the grid
/// such that no two houses are adjacent horizontally, vertically,
/// or diagonally (8-directional king's-move separation).
/// Pre-placed "fixed" houses count toward the total.
/// "Restricted" cells cannot receive a house.
class SetbackEngine implements PuzzleEngine {
  final int width;
  final int height;
  final int houseCount;
  final List<SetbackCellState> _cells;
  final List<SetbackCellState> _initialCells;

  SetbackEngine({
    required this.width,
    required this.height,
    required this.houseCount,
    required List<SetbackCellState> cells,
  })  : _cells = List.of(cells),
        _initialCells = List.of(cells);

  /// Create from grid_data JSON.
  factory SetbackEngine.fromGridData(Map<String, dynamic> gridData) {
    final width = gridData['width'] as int;
    final height = gridData['height'] as int;
    final houseCount = gridData['house_count'] as int;
    final fixedJson = (gridData['fixed'] as List?) ?? [];
    final restrictedJson = (gridData['restricted'] as List?) ?? [];

    final cells = List.filled(width * height, SetbackCellState.empty);

    for (final f in fixedJson) {
      final pos = CellPosition.fromJson(f as Map<String, dynamic>);
      cells[pos.row * width + pos.col] = SetbackCellState.fixed;
    }

    for (final r in restrictedJson) {
      final pos = CellPosition.fromJson(r as Map<String, dynamic>);
      cells[pos.row * width + pos.col] = SetbackCellState.restricted;
    }

    return SetbackEngine(
      width: width,
      height: height,
      houseCount: houseCount,
      cells: cells,
    );
  }

  @override
  String get puzzleType => 'setback';

  /// Get cell state at (row, col).
  SetbackCellState cellAt(int row, int col) => _cells[row * width + col];

  /// All cells as a flat list.
  List<SetbackCellState> get cells => List.unmodifiable(_cells);

  /// Number of currently placed houses (including fixed).
  int get placedCount {
    int count = 0;
    for (final c in _cells) {
      if (c == SetbackCellState.house || c == SetbackCellState.fixed) count++;
    }
    return count;
  }

  /// Whether a cell at (row, col) has a conflict with an adjacent house.
  bool hasConflict(int row, int col) {
    final state = cellAt(row, col);
    if (state != SetbackCellState.house && state != SetbackCellState.fixed) {
      return false;
    }

    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = row + dr;
        final nc = col + dc;
        if (nr < 0 || nr >= height || nc < 0 || nc >= width) continue;
        final neighbor = cellAt(nr, nc);
        if (neighbor == SetbackCellState.house ||
            neighbor == SetbackCellState.fixed) {
          return true;
        }
      }
    }
    return false;
  }

  /// Get all cells that have adjacency conflicts.
  Set<int> get conflictCells {
    final conflicts = <int>{};
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        if (hasConflict(row, col)) {
          conflicts.add(row * width + col);
        }
      }
    }
    return conflicts;
  }

  @override
  bool get isSolved {
    // Must have exactly the right number of houses
    if (placedCount != houseCount) return false;

    // No two houses may be adjacent (including diagonals)
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        final state = cellAt(row, col);
        if (state != SetbackCellState.house && state != SetbackCellState.fixed) {
          continue;
        }
        if (hasConflict(row, col)) return false;
      }
    }

    return true;
  }

  @override
  Map<String, dynamic> get currentState {
    final houses = <Map<String, dynamic>>[];
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        final state = cellAt(row, col);
        if (state == SetbackCellState.house ||
            state == SetbackCellState.fixed) {
          houses.add({'row': row, 'col': col});
        }
      }
    }
    return {'houses': houses};
  }

  @override
  void handleTap(int row, int col) {
    if (row < 0 || row >= height || col < 0 || col >= width) return;
    final idx = row * width + col;
    final state = _cells[idx];

    switch (state) {
      case SetbackCellState.empty:
        _cells[idx] = SetbackCellState.house;
      case SetbackCellState.house:
        _cells[idx] = SetbackCellState.empty;
      case SetbackCellState.fixed:
      case SetbackCellState.restricted:
        break; // Cannot change
    }
  }

  @override
  void handleDrag(int fromRow, int fromCol, int toRow, int toCol) {
    // SETBACK does not use drag — taps only
  }

  @override
  void applyHint() {
    // Future feature — no-op for now.
  }

  @override
  void reset() {
    for (int i = 0; i < _cells.length; i++) {
      _cells[i] = _initialCells[i];
    }
  }
}
