import '../puzzle_engine.dart';
import 'conduit_models.dart';

/// Engine for the CONDUIT (pipes routing) puzzle.
///
/// The grid is a rectangular array of pipe cells. Each cell has a type
/// (straight, corner, tee, cross, end) and a rotation (0/90/180/270).
/// The player taps a cell to rotate it 90 degrees clockwise.
/// The puzzle is solved when all cells form a single connected network
/// where every connection is reciprocated by its neighbor.
class ConduitEngine implements PuzzleEngine {
  final int width;
  final int height;
  final List<ConduitCell> _cells;
  final List<ConduitCell> _initialCells;

  ConduitEngine({
    required this.width,
    required this.height,
    required List<ConduitCell> cells,
  })  : _cells = cells,
        _initialCells = cells.map((c) => c.copyWith()).toList();

  /// Create from grid_data JSON.
  factory ConduitEngine.fromGridData(Map<String, dynamic> gridData) {
    final width = gridData['width'] as int;
    final height = gridData['height'] as int;
    final cellsJson = gridData['cells'] as List;
    final cells = cellsJson
        .map((c) => ConduitCell.fromJson(c as Map<String, dynamic>))
        .toList();

    if (cells.length != width * height) {
      throw ArgumentError(
        'Cell count (${cells.length}) does not match grid dimensions ($width x $height)',
      );
    }

    return ConduitEngine(width: width, height: height, cells: cells);
  }

  @override
  String get puzzleType => 'conduit';

  /// Get the cell at the given row and column.
  ConduitCell cellAt(int row, int col) => _cells[row * width + col];

  /// Get all cells as a flat list.
  List<ConduitCell> get cells => List.unmodifiable(_cells);

  @override
  bool get isSolved {
    // Check that every cell's connection to a neighbor is reciprocated.
    // Also check that all cells form a single connected component.
    if (_cells.isEmpty) return true;

    // Direction offsets: 0=up(-1,0), 1=right(0,1), 2=down(1,0), 3=left(0,-1)
    const dRow = [-1, 0, 1, 0];
    const dCol = [0, 1, 0, -1];
    const opposite = [2, 3, 0, 1];

    // First check: every connection is reciprocated by its neighbor
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        final cell = cellAt(row, col);
        for (final dir in cell.connections) {
          final nRow = row + dRow[dir];
          final nCol = col + dCol[dir];

          // Connection points off the grid = not solved
          if (nRow < 0 || nRow >= height || nCol < 0 || nCol >= width) {
            return false;
          }

          // Neighbor must connect back
          final neighbor = cellAt(nRow, nCol);
          if (!neighbor.connections.contains(opposite[dir])) {
            return false;
          }
        }
      }
    }

    // Second check: all cells are connected (single component)
    final visited = List.filled(_cells.length, false);
    final queue = <int>[0];
    visited[0] = true;
    int visitCount = 1;

    while (queue.isNotEmpty) {
      final idx = queue.removeAt(0);
      final row = idx ~/ width;
      final col = idx % width;
      final cell = cellAt(row, col);

      for (final dir in cell.connections) {
        final nRow = row + dRow[dir];
        final nCol = col + dCol[dir];
        if (nRow < 0 || nRow >= height || nCol < 0 || nCol >= width) continue;

        final nIdx = nRow * width + nCol;
        if (!visited[nIdx]) {
          visited[nIdx] = true;
          visitCount++;
          queue.add(nIdx);
        }
      }
    }

    return visitCount == _cells.length;
  }

  @override
  Map<String, dynamic> get currentState => {
        'width': width,
        'height': height,
        'cells': _cells.map((c) => c.toJson()).toList(),
      };

  @override
  void handleTap(int row, int col) {
    if (row < 0 || row >= height || col < 0 || col >= width) return;
    _cells[row * width + col].rotateCW();
  }

  @override
  void handleDrag(int fromRow, int fromCol, int toRow, int toCol) {
    // CONDUIT does not use drag — taps only
  }

  @override
  void applyHint() {
    // Find a cell that is not in its solved rotation and rotate it to match.
    // For Phase 0, hints are a future feature — no-op for now.
  }

  @override
  void reset() {
    for (int i = 0; i < _cells.length; i++) {
      _cells[i] = _initialCells[i].copyWith();
    }
  }

  /// Get the set of cells that are connected to the given cell.
  /// Used for visual feedback during play.
  Set<int> connectedComponent(int row, int col) {
    const dRow = [-1, 0, 1, 0];
    const dCol = [0, 1, 0, -1];
    const opposite = [2, 3, 0, 1];

    final startIdx = row * width + col;
    final visited = <int>{startIdx};
    final queue = <int>[startIdx];

    while (queue.isNotEmpty) {
      final idx = queue.removeAt(0);
      final r = idx ~/ width;
      final c = idx % width;
      final cell = cellAt(r, c);

      for (final dir in cell.connections) {
        final nRow = r + dRow[dir];
        final nCol = c + dCol[dir];
        if (nRow < 0 || nRow >= height || nCol < 0 || nCol >= width) continue;

        final neighbor = cellAt(nRow, nCol);
        if (!neighbor.connections.contains(opposite[dir])) continue;

        final nIdx = nRow * width + nCol;
        if (!visited.contains(nIdx)) {
          visited.add(nIdx);
          queue.add(nIdx);
        }
      }
    }

    return visited;
  }
}
