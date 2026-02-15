import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'conduit_engine.dart';

/// State for the CONDUIT puzzle UI.
class ConduitState {
  final ConduitEngine engine;
  final Set<int> connectedCells;
  final bool isSolved;
  final int moveCount;

  ConduitState({
    required this.engine,
    required this.connectedCells,
    required this.isSolved,
    this.moveCount = 0,
  });

  ConduitState copyWith({
    ConduitEngine? engine,
    Set<int>? connectedCells,
    bool? isSolved,
    int? moveCount,
  }) {
    return ConduitState(
      engine: engine ?? this.engine,
      connectedCells: connectedCells ?? this.connectedCells,
      isSolved: isSolved ?? this.isSolved,
      moveCount: moveCount ?? this.moveCount,
    );
  }
}

/// Notifier for CONDUIT puzzle interactions.
class ConduitNotifier extends Notifier<ConduitState> {
  @override
  ConduitState build() {
    throw UnimplementedError('Use overrideWith to provide initial grid data');
  }

  /// Initialize with grid data JSON.
  void initialize(Map<String, dynamic> gridData) {
    final engine = ConduitEngine.fromGridData(gridData);
    state = ConduitState(
      engine: engine,
      connectedCells: _computeAllConnected(engine),
      isSolved: engine.isSolved,
    );
  }

  /// Handle a tap on a cell.
  void tapCell(int row, int col) {
    if (state.isSolved) return;
    state.engine.handleTap(row, col);
    final connected = _computeAllConnected(state.engine);
    state = state.copyWith(
      connectedCells: connected,
      isSolved: state.engine.isSolved,
      moveCount: state.moveCount + 1,
    );
  }

  /// Reset to initial state.
  void resetPuzzle() {
    state.engine.reset();
    state = state.copyWith(
      connectedCells: _computeAllConnected(state.engine),
      isSolved: state.engine.isSolved,
      moveCount: 0,
    );
  }

  /// Compute the largest connected component for visual feedback.
  Set<int> _computeAllConnected(ConduitEngine engine) {
    // Find the largest connected component to highlight
    Set<int> largest = {};
    final visited = <int>{};

    for (int i = 0; i < engine.cells.length; i++) {
      if (visited.contains(i)) continue;
      final row = i ~/ engine.width;
      final col = i % engine.width;
      final component = engine.connectedComponent(row, col);
      visited.addAll(component);
      if (component.length > largest.length) {
        largest = component;
      }
    }

    return largest;
  }
}

/// Provider for a CONDUIT puzzle. Override with family for puzzle instances.
final conduitProvider =
    NotifierProvider<ConduitNotifier, ConduitState>(ConduitNotifier.new);
