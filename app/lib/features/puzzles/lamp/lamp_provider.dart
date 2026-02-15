import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'lamp_engine.dart';
import 'lamp_models.dart';

/// UI state for the LAMP puzzle.
class LampState {
  final LampEngine engine;
  final List<LampPlayState> playStates;
  final bool isSolved;
  final int moveCount;

  LampState({
    required this.engine,
    required this.playStates,
    required this.isSolved,
    this.moveCount = 0,
  });

  LampState copyWith({
    LampEngine? engine,
    List<LampPlayState>? playStates,
    bool? isSolved,
    int? moveCount,
  }) {
    return LampState(
      engine: engine ?? this.engine,
      playStates: playStates ?? this.playStates,
      isSolved: isSolved ?? this.isSolved,
      moveCount: moveCount ?? this.moveCount,
    );
  }
}

/// Notifier for LAMP puzzle interactions.
class LampNotifier extends Notifier<LampState> {
  @override
  LampState build() {
    throw UnimplementedError('Use overrideWith to provide initial grid data');
  }

  /// Initialize with grid data JSON.
  void initialize(Map<String, dynamic> gridData) {
    final engine = LampEngine.fromGridData(gridData);
    state = LampState(
      engine: engine,
      playStates: engine.computePlayStates(),
      isSolved: false,
    );
  }

  /// Toggle a light at the given cell.
  void tapCell(int row, int col) {
    if (state.isSolved) return;
    state.engine.handleTap(row, col);
    state = state.copyWith(
      playStates: state.engine.computePlayStates(),
      isSolved: state.engine.isSolved,
      moveCount: state.moveCount + 1,
    );
  }

  /// Reset the puzzle.
  void resetPuzzle() {
    state.engine.reset();
    state = state.copyWith(
      playStates: state.engine.computePlayStates(),
      isSolved: false,
      moveCount: 0,
    );
  }
}

/// Provider for a LAMP puzzle.
final lampProvider =
    NotifierProvider<LampNotifier, LampState>(LampNotifier.new);
