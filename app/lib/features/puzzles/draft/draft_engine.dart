import '../puzzle_engine.dart';
import 'draft_models.dart';

/// Engine for the DRAFT (Nonogram) puzzle.
///
/// The player must fill cells to match a hidden pattern. Clues along
/// each row and column describe the contiguous groups of filled cells
/// in that line. For example, clue [3, 2] means there is a group of
/// 3 filled cells, then a gap, then a group of 2.
class DraftEngine implements PuzzleEngine {
  final int width;
  final int height;
  final List<List<int>> rowClues;
  final List<List<int>> colClues;
  final List<DraftCellState> _cells;
  final List<DraftCellState> _initialCells;

  DraftEngine({
    required this.width,
    required this.height,
    required this.rowClues,
    required this.colClues,
    List<DraftCellState>? cells,
  })  : _cells = cells != null
            ? List.of(cells)
            : List.filled(width * height, DraftCellState.empty),
        _initialCells = cells != null
            ? List.of(cells)
            : List.filled(width * height, DraftCellState.empty);

  /// Create from grid_data JSON.
  factory DraftEngine.fromGridData(Map<String, dynamic> gridData) {
    final width = gridData['width'] as int;
    final height = gridData['height'] as int;

    final rowCluesRaw = gridData['row_clues'] as List;
    final colCluesRaw = gridData['col_clues'] as List;

    final rowClues = rowCluesRaw
        .map((r) => (r as List).map((v) => v as int).toList())
        .toList();
    final colClues = colCluesRaw
        .map((c) => (c as List).map((v) => v as int).toList())
        .toList();

    return DraftEngine(
      width: width,
      height: height,
      rowClues: rowClues,
      colClues: colClues,
    );
  }

  @override
  String get puzzleType => 'draft';

  /// Get cell state at (row, col).
  DraftCellState cellAt(int row, int col) => _cells[row * width + col];

  /// All cells as a flat list.
  List<DraftCellState> get cells => List.unmodifiable(_cells);

  /// Get the computed groups for a given row (based on current state).
  List<int> rowGroups(int row) {
    final groups = <int>[];
    int count = 0;
    for (int col = 0; col < width; col++) {
      if (_cells[row * width + col] == DraftCellState.filled) {
        count++;
      } else {
        if (count > 0) groups.add(count);
        count = 0;
      }
    }
    if (count > 0) groups.add(count);
    return groups;
  }

  /// Get the computed groups for a given column (based on current state).
  List<int> colGroups(int col) {
    final groups = <int>[];
    int count = 0;
    for (int row = 0; row < height; row++) {
      if (_cells[row * width + col] == DraftCellState.filled) {
        count++;
      } else {
        if (count > 0) groups.add(count);
        count = 0;
      }
    }
    if (count > 0) groups.add(count);
    return groups;
  }

  /// Whether the given row's current groups match its clue.
  bool isRowSatisfied(int row) {
    return _listsEqual(rowGroups(row), rowClues[row]);
  }

  /// Whether the given column's current groups match its clue.
  bool isColSatisfied(int col) {
    return _listsEqual(colGroups(col), colClues[col]);
  }

  static bool _listsEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  bool get isSolved {
    for (int row = 0; row < height; row++) {
      if (!isRowSatisfied(row)) return false;
    }
    for (int col = 0; col < width; col++) {
      if (!isColSatisfied(col)) return false;
    }
    return true;
  }

  @override
  Map<String, dynamic> get currentState => {
        'cells': _cells
            .map((c) => c == DraftCellState.filled ? 1 : 0)
            .toList(),
      };

  @override
  void handleTap(int row, int col) {
    if (row < 0 || row >= height || col < 0 || col >= width) return;
    final idx = row * width + col;
    switch (_cells[idx]) {
      case DraftCellState.empty:
        _cells[idx] = DraftCellState.filled;
      case DraftCellState.filled:
        _cells[idx] = DraftCellState.marked;
      case DraftCellState.marked:
        _cells[idx] = DraftCellState.empty;
    }
  }

  @override
  void handleDrag(int fromRow, int fromCol, int toRow, int toCol) {
    // Fill a line of cells (for quick nonogram input).
    if (fromRow < 0 || fromRow >= height || fromCol < 0 || fromCol >= width) return;
    if (toRow < 0 || toRow >= height || toCol < 0 || toCol >= width) return;

    // Determine the target state: if the starting cell is empty, fill; otherwise empty.
    final startIdx = fromRow * width + fromCol;
    final targetState = _cells[startIdx] == DraftCellState.filled
        ? DraftCellState.empty
        : DraftCellState.filled;

    // Only support horizontal or vertical drags
    if (fromRow == toRow) {
      final minCol = fromCol < toCol ? fromCol : toCol;
      final maxCol = fromCol > toCol ? fromCol : toCol;
      for (int c = minCol; c <= maxCol; c++) {
        _cells[fromRow * width + c] = targetState;
      }
    } else if (fromCol == toCol) {
      final minRow = fromRow < toRow ? fromRow : toRow;
      final maxRow = fromRow > toRow ? fromRow : toRow;
      for (int r = minRow; r <= maxRow; r++) {
        _cells[r * width + fromCol] = targetState;
      }
    }
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
