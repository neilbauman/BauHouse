import '../puzzle_engine.dart';
import 'lamp_models.dart';

/// Engine for the LAMP (Light Up / Akari) puzzle.
///
/// Rules:
/// 1. Place lights on empty cells.
/// 2. Lights illuminate all cells in their row and column until blocked.
/// 3. No two lights may illuminate each other (no line of sight).
/// 4. All empty cells must be illuminated.
/// 5. Numbered black cells must have exactly that many adjacent lights.
class LampEngine implements PuzzleEngine {
  final int width;
  final int height;
  final List<LampGridCell> _gridCells;

  /// Public accessor for the static grid cells.
  List<LampGridCell> get gridCells => _gridCells;

  /// Tracks which empty cells have a player-placed light.
  final List<bool> _lights;
  final List<bool> _initialLights;

  LampEngine({
    required this.width,
    required this.height,
    required List<LampGridCell> gridCells,
    List<bool>? lights,
  })  : _gridCells = List.unmodifiable(gridCells),
        _lights = lights != null
            ? List.of(lights)
            : List.filled(width * height, false),
        _initialLights = lights != null
            ? List.of(lights)
            : List.filled(width * height, false);

  /// Create from grid_data JSON.
  factory LampEngine.fromGridData(Map<String, dynamic> gridData) {
    final width = gridData['width'] as int;
    final height = gridData['height'] as int;
    final cellsJson = gridData['cells'] as List;
    final gridCells = cellsJson
        .map((c) => LampGridCell.fromJson(c as Map<String, dynamic>))
        .toList();

    if (gridCells.length != width * height) {
      throw ArgumentError(
        'Cell count (${gridCells.length}) does not match grid dimensions ($width x $height)',
      );
    }

    return LampEngine(width: width, height: height, gridCells: gridCells);
  }

  @override
  String get puzzleType => 'lamp';

  /// The static grid cell at (row, col).
  LampGridCell gridCellAt(int row, int col) => _gridCells[row * width + col];

  /// Whether (row, col) has a player-placed light.
  bool hasLight(int row, int col) => _lights[row * width + col];

  /// All light positions.
  List<bool> get lights => List.unmodifiable(_lights);

  /// Compute the play state for each cell.
  List<LampPlayState> computePlayStates() {
    final states = List.filled(width * height, LampPlayState.dark);

    // First pass: mark all lights
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        final idx = row * width + col;
        if (_gridCells[idx].type == LampCellType.black) continue;
        if (_lights[idx]) {
          states[idx] = LampPlayState.light;
        }
      }
    }

    // Second pass: illuminate from each light
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        if (!_lights[row * width + col]) continue;

        // Cast light in all four directions
        for (final dir in [
          [0, 1],
          [0, -1],
          [1, 0],
          [-1, 0]
        ]) {
          int r = row + dir[0];
          int c = col + dir[1];
          while (r >= 0 && r < height && c >= 0 && c < width) {
            final nIdx = r * width + c;
            if (_gridCells[nIdx].type == LampCellType.black) break;
            if (states[nIdx] == LampPlayState.light ||
                states[nIdx] == LampPlayState.lightConflict) {
              // This light conflicts with another light
              states[nIdx] = LampPlayState.lightConflict;
              states[row * width + col] = LampPlayState.lightConflict;
            } else {
              states[nIdx] = LampPlayState.lit;
            }
            r += dir[0];
            c += dir[1];
          }
        }
      }
    }

    return states;
  }

  /// Count lights adjacent (orthogonally) to a black cell.
  int adjacentLightCount(int row, int col) {
    int count = 0;
    for (final dir in [
      [0, 1],
      [0, -1],
      [1, 0],
      [-1, 0]
    ]) {
      final nr = row + dir[0];
      final nc = col + dir[1];
      if (nr < 0 || nr >= height || nc < 0 || nc >= width) continue;
      if (_lights[nr * width + nc]) count++;
    }
    return count;
  }

  /// Whether a clued black cell's constraint is satisfied.
  /// Returns null if the cell has no clue.
  bool? isClueCorrect(int row, int col) {
    final cell = gridCellAt(row, col);
    if (cell.type != LampCellType.black || cell.clue == null) return null;
    return adjacentLightCount(row, col) == cell.clue;
  }

  /// Whether a clued black cell has too many adjacent lights.
  bool isClueOver(int row, int col) {
    final cell = gridCellAt(row, col);
    if (cell.type != LampCellType.black || cell.clue == null) return false;
    return adjacentLightCount(row, col) > cell.clue!;
  }

  @override
  bool get isSolved {
    final states = computePlayStates();

    // 1. No conflicts between lights
    for (final state in states) {
      if (state == LampPlayState.lightConflict) return false;
    }

    // 2. All empty cells must be illuminated
    for (int i = 0; i < _gridCells.length; i++) {
      if (_gridCells[i].type == LampCellType.empty) {
        if (states[i] == LampPlayState.dark) return false;
      }
    }

    // 3. All clued black cells must be exactly satisfied
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        final correct = isClueCorrect(row, col);
        if (correct != null && !correct) return false;
      }
    }

    return true;
  }

  @override
  Map<String, dynamic> get currentState {
    final lightPositions = <Map<String, dynamic>>[];
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        if (_lights[row * width + col]) {
          lightPositions.add({'row': row, 'col': col});
        }
      }
    }
    return {'lights': lightPositions};
  }

  @override
  void handleTap(int row, int col) {
    if (row < 0 || row >= height || col < 0 || col >= width) return;
    final idx = row * width + col;
    // Only toggle on empty cells
    if (_gridCells[idx].type == LampCellType.black) return;
    _lights[idx] = !_lights[idx];
  }

  @override
  void handleDrag(int fromRow, int fromCol, int toRow, int toCol) {
    // LAMP does not use drag — taps only
  }

  @override
  void applyHint() {
    // Future feature — no-op for now.
  }

  @override
  void reset() {
    for (int i = 0; i < _lights.length; i++) {
      _lights[i] = _initialLights[i];
    }
  }

  /// Number of placed lights.
  int get lightCount {
    int count = 0;
    for (final l in _lights) {
      if (l) count++;
    }
    return count;
  }
}
