/// Cell types for the CONDUIT (pipes routing) puzzle.
enum CellType {
  straight,
  corner,
  tee,
  cross,
  end;

  static CellType fromString(String s) {
    return CellType.values.firstWhere((e) => e.name == s);
  }
}

/// A single cell in the CONDUIT grid.
class ConduitCell {
  final CellType type;
  int rotation; // 0, 90, 180, 270

  ConduitCell({required this.type, required this.rotation});

  /// Returns the set of directions this cell connects to
  /// given its type and current rotation.
  /// Directions: 0=up, 1=right, 2=down, 3=left
  Set<int> get connections {
    final base = _baseConnections(type);
    return base.map((d) => (d + rotation ~/ 90) % 4).toSet();
  }

  /// Base connections for each cell type at rotation=0.
  /// Convention: 0=up, 1=right, 2=down, 3=left
  static Set<int> _baseConnections(CellType type) {
    switch (type) {
      case CellType.straight:
        return {0, 2}; // vertical pipe: up + down
      case CellType.corner:
        return {0, 1}; // up + right
      case CellType.tee:
        return {0, 1, 2}; // up + right + down (T-piece)
      case CellType.cross:
        return {0, 1, 2, 3}; // all four directions
      case CellType.end:
        return {0}; // up only (dead end)
    }
  }

  /// Rotate this cell 90 degrees clockwise.
  void rotateCW() {
    rotation = (rotation + 90) % 360;
  }

  /// Create from JSON map.
  factory ConduitCell.fromJson(Map<String, dynamic> json) {
    return ConduitCell(
      type: CellType.fromString(json['type'] as String),
      rotation: json['rotation'] as int,
    );
  }

  /// Convert to JSON map.
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'rotation': rotation,
      };

  ConduitCell copyWith({CellType? type, int? rotation}) {
    return ConduitCell(
      type: type ?? this.type,
      rotation: rotation ?? this.rotation,
    );
  }
}
