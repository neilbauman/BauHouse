import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'draft_engine.dart';

/// UI state for the DRAFT puzzle.
class DraftState {
  final DraftEngine engine;
  final bool isSolved;
  final int moveCount;
  final Set<int> satisfiedRows;
  final Set<int> satisfiedCols;

  DraftState({
    required this.engine,
    required this.isSolved,
    required this.satisfiedRows,
    required this.satisfiedCols,
    this.moveCount = 0,
  });

  DraftState copyWith({
    DraftEngine? engine,
    bool? isSolved,
    int? moveCount,
    Set<int>? satisfiedRows,
    Set<int>? satisfiedCols,
  }) {
    return DraftState(
      engine: engine ?? this.engine,
      isSolved: isSolved ?? this.isSolved,
      moveCount: moveCount ?? this.moveCount,
      satisfiedRows: satisfiedRows ?? this.satisfiedRows,
      satisfiedCols: satisfiedCols ?? this.satisfiedCols,
    );
  }
}

/// Notifier for DRAFT puzzle interactions.
class DraftNotifier extends Notifier<DraftState> {
  @override
  DraftState build() {
    throw UnimplementedError('Use overrideWith to provide initial grid data');
  }

  /// Initialize with grid data JSON.
  void initialize(Map<String, dynamic> gridData) {
    final engine = DraftEngine.fromGridData(gridData);
    state = DraftState(
      engine: engine,
      isSolved: false,
      satisfiedRows: {},
      satisfiedCols: {},
    );
  }

  /// Tap a cell — cycles empty → filled → marked → empty.
  void tapCell(int row, int col) {
    if (state.isSolved) return;
    state.engine.handleTap(row, col);
    _updateState();
  }

  /// Drag to fill/clear a line of cells.
  void dragCells(int fromRow, int fromCol, int toRow, int toCol) {
    if (state.isSolved) return;
    state.engine.handleDrag(fromRow, fromCol, toRow, toCol);
    _updateState();
  }

  void _updateState() {
    final engine = state.engine;
    final satisfiedRows = <int>{};
    final satisfiedCols = <int>{};

    for (int r = 0; r < engine.height; r++) {
      if (engine.isRowSatisfied(r)) satisfiedRows.add(r);
    }
    for (int c = 0; c < engine.width; c++) {
      if (engine.isColSatisfied(c)) satisfiedCols.add(c);
    }

    state = state.copyWith(
      isSolved: engine.isSolved,
      moveCount: state.moveCount + 1,
      satisfiedRows: satisfiedRows,
      satisfiedCols: satisfiedCols,
    );
  }

  /// Reset the puzzle.
  void resetPuzzle() {
    state.engine.reset();
    state = state.copyWith(
      isSolved: false,
      moveCount: 0,
      satisfiedRows: {},
      satisfiedCols: {},
    );
  }
}

/// Provider for a DRAFT puzzle.
final draftProvider =
    NotifierProvider<DraftNotifier, DraftState>(DraftNotifier.new);
