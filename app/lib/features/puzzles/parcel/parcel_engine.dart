import '../puzzle_engine.dart';
import 'parcel_models.dart';

/// Engine for the PARCEL (Shikaku-variant) puzzle.
///
/// The grid contains numbered "givens". The player must divide the entire
/// grid into non-overlapping rectangles such that:
///   1. Every cell belongs to exactly one rectangle.
///   2. Each rectangle contains exactly one given.
///   3. The area of the rectangle equals the given's value.
class ParcelEngine implements PuzzleEngine {
  final int width;
  final int height;
  final List<ParcelGiven> givens;
  final List<ParcelRegion> _regions;
  final List<ParcelRegion> _initialRegions;

  ParcelEngine({
    required this.width,
    required this.height,
    required this.givens,
    List<ParcelRegion>? regions,
  })  : _regions = regions != null ? List.of(regions) : [],
        _initialRegions = regions != null ? List.of(regions) : [];

  /// Create from grid_data JSON.
  factory ParcelEngine.fromGridData(Map<String, dynamic> gridData) {
    final width = gridData['width'] as int;
    final height = gridData['height'] as int;
    final givensJson = gridData['givens'] as List;
    final givens = givensJson
        .map((g) => ParcelGiven.fromJson(g as Map<String, dynamic>))
        .toList();

    return ParcelEngine(width: width, height: height, givens: givens);
  }

  @override
  String get puzzleType => 'parcel';

  /// Current list of placed regions (unmodifiable).
  List<ParcelRegion> get regions => List.unmodifiable(_regions);

  /// The given at a specific cell, or null if none.
  ParcelGiven? givenAt(int row, int col) {
    for (final g in givens) {
      if (g.row == row && g.col == col) return g;
    }
    return null;
  }

  /// Which region index covers cell (row, col), or -1 if none.
  int regionIndexAt(int row, int col) {
    for (int i = 0; i < _regions.length; i++) {
      if (_regions[i].contains(row, col)) return i;
    }
    return -1;
  }

  /// The region covering cell (row, col), or null.
  ParcelRegion? regionAt(int row, int col) {
    final idx = regionIndexAt(row, col);
    return idx >= 0 ? _regions[idx] : null;
  }

  /// Try to place a region. Returns true if placement is valid.
  /// Validity checks:
  ///   - Region fits within grid bounds.
  ///   - Region does not overlap any existing region.
  bool addRegion(ParcelRegion region) {
    if (!_fitsInGrid(region)) return false;
    if (_overlapsExisting(region)) return false;
    _regions.add(region);
    return true;
  }

  /// Remove the region that contains the given cell.
  /// Returns the removed region, or null if no region was there.
  ParcelRegion? removeRegionAt(int row, int col) {
    final idx = regionIndexAt(row, col);
    if (idx < 0) return null;
    return _regions.removeAt(idx);
  }

  /// Remove a specific region.
  bool removeRegion(ParcelRegion region) {
    return _regions.remove(region);
  }

  /// Clear all placed regions.
  void clearRegions() {
    _regions.clear();
  }

  bool _fitsInGrid(ParcelRegion region) {
    return region.row >= 0 &&
        region.col >= 0 &&
        region.row + region.height <= height &&
        region.col + region.width <= width &&
        region.width > 0 &&
        region.height > 0;
  }

  bool _overlapsExisting(ParcelRegion newRegion) {
    for (final existing in _regions) {
      if (_regionsOverlap(existing, newRegion)) return true;
    }
    return false;
  }

  static bool _regionsOverlap(ParcelRegion a, ParcelRegion b) {
    // Two rectangles do NOT overlap if one is entirely left, right, above, or below the other.
    if (a.col + a.width <= b.col) return false;
    if (b.col + b.width <= a.col) return false;
    if (a.row + a.height <= b.row) return false;
    if (b.row + b.height <= a.row) return false;
    return true;
  }

  @override
  bool get isSolved {
    // 1. Every cell must be covered by exactly one region.
    final totalCells = width * height;
    final coveredCells = <int>{};

    for (final region in _regions) {
      final indices = region.cellIndices(width);
      for (final idx in indices) {
        if (coveredCells.contains(idx)) return false; // overlap
        coveredCells.add(idx);
      }
    }
    if (coveredCells.length != totalCells) return false;

    // 2. Each region must contain exactly one given whose value equals the area.
    for (final region in _regions) {
      final containedGivens = givens
          .where((g) => region.contains(g.row, g.col))
          .toList();
      if (containedGivens.length != 1) return false;
      if (containedGivens.first.value != region.area) return false;
    }

    // 3. Every given must be inside a region (implied by full coverage + one-given-per-region,
    //    but only if region count == given count).
    if (_regions.length != givens.length) return false;

    return true;
  }

  /// Validate a single region in isolation (for UI feedback).
  /// Returns a status string: 'valid', 'no_given', 'wrong_area', 'multi_given'.
  String validateRegion(ParcelRegion region) {
    final containedGivens = givens
        .where((g) => region.contains(g.row, g.col))
        .toList();
    if (containedGivens.isEmpty) return 'no_given';
    if (containedGivens.length > 1) return 'multi_given';
    if (containedGivens.first.value != region.area) return 'wrong_area';
    return 'valid';
  }

  @override
  Map<String, dynamic> get currentState => {
        'width': width,
        'height': height,
        'givens': givens.map((g) => g.toJson()).toList(),
        'regions': _regions.map((r) => r.toJson()).toList(),
      };

  @override
  void handleTap(int row, int col) {
    // Tap on an existing region to remove it.
    removeRegionAt(row, col);
  }

  @override
  void handleDrag(int fromRow, int fromCol, int toRow, int toCol) {
    // Create a region from the drag rectangle.
    final minRow = fromRow < toRow ? fromRow : toRow;
    final maxRow = fromRow > toRow ? fromRow : toRow;
    final minCol = fromCol < toCol ? fromCol : toCol;
    final maxCol = fromCol > toCol ? fromCol : toCol;

    final region = ParcelRegion(
      row: minRow,
      col: minCol,
      width: maxCol - minCol + 1,
      height: maxRow - minRow + 1,
    );

    // Remove any regions that overlap with the new one
    _regions.removeWhere((r) => _regionsOverlap(r, region));
    addRegion(region);
  }

  @override
  void applyHint() {
    // Future feature — no-op for now.
  }

  @override
  void reset() {
    _regions.clear();
    _regions.addAll(_initialRegions.map((r) => ParcelRegion(
          row: r.row,
          col: r.col,
          width: r.width,
          height: r.height,
        )));
  }
}
