import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'setback_engine.dart';

/// UI state for the SETBACK puzzle.
class SetbackState {
  final SetbackEngine engine;
  final Set<int> conflictCells;
  final bool isSolved;
  final int moveCount;

  SetbackState({
    required this.engine,
    required this.conflictCells,
    required this.isSolved,
    this.moveCount = 0,
  });

  SetbackState copyWith({
    SetbackEngine? engine,
    Set<int>? conflictCells,
    bool? isSolved,
    int? moveCount,
  }) {
    return SetbackState(
      engine: engine ?? this.engine,
      conflictCells: conflictCells ?? this.conflictCells,
      isSolved: isSolved ?? this.isSolved,
      moveCount: moveCount ?? this.moveCount,
    );
  }
}

/// Notifier for SETBACK puzzle interactions.
class SetbackNotifier extends Notifier<SetbackState> {
  @override
  SetbackState build() {
    throw UnimplementedError('Use overrideWith to provide initial grid data');
  }

  /// Initialize with grid data JSON.
  void initialize(Map<String, dynamic> gridData) {
    final engine = SetbackEngine.fromGridData(gridData);
    state = SetbackState(
      engine: engine,
      conflictCells: engine.conflictCells,
      isSolved: false,
    );
  }

  /// Toggle a house on/off at the given cell.
  void tapCell(int row, int col) {
    if (state.isSolved) return;
    state.engine.handleTap(row, col);
    state = state.copyWith(
      conflictCells: state.engine.conflictCells,
      isSolved: state.engine.isSolved,
      moveCount: state.moveCount + 1,
    );
  }

  /// Reset the puzzle.
  void resetPuzzle() {
    state.engine.reset();
    state = state.copyWith(
      conflictCells: state.engine.conflictCells,
      isSolved: false,
      moveCount: 0,
    );
  }
}

/// Provider for a SETBACK puzzle.
final setbackProvider =
    NotifierProvider<SetbackNotifier, SetbackState>(SetbackNotifier.new);
