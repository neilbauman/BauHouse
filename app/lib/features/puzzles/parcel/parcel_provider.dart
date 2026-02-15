import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'parcel_engine.dart';
import 'parcel_models.dart';

/// UI state for the PARCEL puzzle.
class ParcelState {
  final ParcelEngine engine;
  final bool isSolved;
  final int moveCount;

  /// Index of the region currently being dragged (preview), or null.
  final ParcelRegion? dragPreview;

  ParcelState({
    required this.engine,
    required this.isSolved,
    this.moveCount = 0,
    this.dragPreview,
  });

  ParcelState copyWith({
    ParcelEngine? engine,
    bool? isSolved,
    int? moveCount,
    ParcelRegion? Function()? dragPreview,
  }) {
    return ParcelState(
      engine: engine ?? this.engine,
      isSolved: isSolved ?? this.isSolved,
      moveCount: moveCount ?? this.moveCount,
      dragPreview: dragPreview != null ? dragPreview() : this.dragPreview,
    );
  }
}

/// Notifier for PARCEL puzzle interactions.
class ParcelNotifier extends Notifier<ParcelState> {
  @override
  ParcelState build() {
    throw UnimplementedError('Use overrideWith to provide initial grid data');
  }

  /// Initialize with grid data JSON.
  void initialize(Map<String, dynamic> gridData) {
    final engine = ParcelEngine.fromGridData(gridData);
    state = ParcelState(
      engine: engine,
      isSolved: false,
    );
  }

  /// Handle a tap — removes the region at the tapped cell.
  void tapCell(int row, int col) {
    if (state.isSolved) return;
    final removed = state.engine.removeRegionAt(row, col);
    if (removed != null) {
      state = state.copyWith(
        isSolved: state.engine.isSolved,
        moveCount: state.moveCount + 1,
      );
    }
  }

  /// Update the drag preview rectangle while the user is dragging.
  void updateDragPreview(int fromRow, int fromCol, int toRow, int toCol) {
    if (state.isSolved) return;
    final minRow = fromRow < toRow ? fromRow : toRow;
    final maxRow = fromRow > toRow ? fromRow : toRow;
    final minCol = fromCol < toCol ? fromCol : toCol;
    final maxCol = fromCol > toCol ? fromCol : toCol;

    state = state.copyWith(
      dragPreview: () => ParcelRegion(
        row: minRow,
        col: minCol,
        width: maxCol - minCol + 1,
        height: maxRow - minRow + 1,
      ),
    );
  }

  /// Finish a drag — place the region.
  void finishDrag(int fromRow, int fromCol, int toRow, int toCol) {
    if (state.isSolved) return;
    state.engine.handleDrag(fromRow, fromCol, toRow, toCol);
    state = state.copyWith(
      isSolved: state.engine.isSolved,
      moveCount: state.moveCount + 1,
      dragPreview: () => null,
    );
  }

  /// Clear the drag preview without placing.
  void cancelDrag() {
    state = state.copyWith(dragPreview: () => null);
  }

  /// Reset the puzzle.
  void resetPuzzle() {
    state.engine.reset();
    state = state.copyWith(
      isSolved: false,
      moveCount: 0,
      dragPreview: () => null,
    );
  }
}

/// Provider for a PARCEL puzzle.
final parcelProvider =
    NotifierProvider<ParcelNotifier, ParcelState>(ParcelNotifier.new);
