/// Data models for the PARCEL (Shikaku-variant) puzzle.
///
/// Players divide a grid into non-overlapping rectangles.
/// Each rectangle must contain exactly one "given" number,
/// and the rectangle's area must equal that number.

/// A pre-placed number on the grid that constrains region sizing.
class ParcelGiven {
  final int row;
  final int col;
  final int value;

  const ParcelGiven({
    required this.row,
    required this.col,
    required this.value,
  });

  factory ParcelGiven.fromJson(Map<String, dynamic> json) {
    return ParcelGiven(
      row: json['row'] as int,
      col: json['col'] as int,
      value: json['value'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'row': row,
        'col': col,
        'value': value,
      };
}

/// A rectangular region placed by the player.
class ParcelRegion {
  final int row;
  final int col;
  final int width;
  final int height;

  const ParcelRegion({
    required this.row,
    required this.col,
    required this.width,
    required this.height,
  });

  int get area => width * height;

  /// Whether a cell at (r, c) falls inside this region.
  bool contains(int r, int c) {
    return r >= row && r < row + height && c >= col && c < col + width;
  }

  /// All cell indices (row-major) covered by this region for a grid of [gridWidth].
  Set<int> cellIndices(int gridWidth) {
    final indices = <int>{};
    for (int r = row; r < row + height; r++) {
      for (int c = col; c < col + width; c++) {
        indices.add(r * gridWidth + c);
      }
    }
    return indices;
  }

  factory ParcelRegion.fromJson(Map<String, dynamic> json) {
    return ParcelRegion(
      row: json['row'] as int,
      col: json['col'] as int,
      width: json['width'] as int,
      height: json['height'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'row': row,
        'col': col,
        'width': width,
        'height': height,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParcelRegion &&
        other.row == row &&
        other.col == col &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(row, col, width, height);
}
