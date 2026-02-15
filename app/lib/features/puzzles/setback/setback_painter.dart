import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/colours.dart';
import 'setback_models.dart';

/// Custom painter for rendering the SETBACK (Kings-variant) puzzle grid.
///
/// Draws empty cells, houses (player-placed and fixed), restricted zones,
/// and highlights adjacency conflicts in red.
class SetbackPainter extends CustomPainter {
  final int width;
  final int height;
  final List<SetbackCellState> cells;
  final Set<int> conflictCells;
  final bool isSolved;
  final int houseCount;
  final int placedCount;

  SetbackPainter({
    required this.width,
    required this.height,
    required this.cells,
    required this.conflictCells,
    required this.houseCount,
    required this.placedCount,
    this.isSolved = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / width;
    final cellHeight = size.height / height;
    final cellSize = math.min(cellWidth, cellHeight);

    final offsetX = (size.width - cellSize * width) / 2;
    final offsetY = (size.height - cellSize * height) / 2;

    // Draw cells
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        final idx = row * width + col;
        _drawCell(canvas, offsetX, offsetY, cellSize, row, col, cells[idx],
            conflictCells.contains(idx));
      }
    }

    // Draw grid lines
    _drawGrid(canvas, offsetX, offsetY, cellSize);
  }

  void _drawGrid(
      Canvas canvas, double offsetX, double offsetY, double cellSize) {
    final gridPaint = Paint()
      ..color = BauColours.gridLine
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int row = 0; row <= height; row++) {
      canvas.drawLine(
        Offset(offsetX, offsetY + row * cellSize),
        Offset(offsetX + width * cellSize, offsetY + row * cellSize),
        gridPaint,
      );
    }
    for (int col = 0; col <= width; col++) {
      canvas.drawLine(
        Offset(offsetX + col * cellSize, offsetY),
        Offset(offsetX + col * cellSize, offsetY + height * cellSize),
        gridPaint,
      );
    }
  }

  void _drawCell(Canvas canvas, double offsetX, double offsetY,
      double cellSize, int row, int col, SetbackCellState state, bool hasConflict) {
    final x = offsetX + col * cellSize;
    final y = offsetY + row * cellSize;
    final cx = x + cellSize / 2;
    final cy = y + cellSize / 2;
    final rect = Rect.fromLTWH(x + 0.5, y + 0.5, cellSize - 1, cellSize - 1);

    switch (state) {
      case SetbackCellState.restricted:
        // Hatched pattern for restricted zones
        canvas.drawRect(
          rect,
          Paint()
            ..color = BauColours.midGrey.withValues(alpha: 0.15)
            ..style = PaintingStyle.fill,
        );
        final hatchPaint = Paint()
          ..color = BauColours.midGrey.withValues(alpha: 0.3)
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke;
        for (double d = -cellSize; d < cellSize * 2; d += cellSize * 0.2) {
          canvas.drawLine(
            Offset(x + d, y),
            Offset(x + d + cellSize, y + cellSize),
            hatchPaint,
          );
        }

      case SetbackCellState.fixed:
        // Pre-placed house: solid fill with darker house icon
        _drawHouseBackground(canvas, rect, isSolved
            ? BauColours.sage.withValues(alpha: 0.3)
            : BauColours.blueprintBlue.withValues(alpha: 0.2));
        _drawHouseIcon(canvas, cx, cy, cellSize,
            isSolved ? BauColours.sage : BauColours.blueprintBlue);
        // Small lock indicator
        _drawFixedIndicator(canvas, x + cellSize - 8, y + 4);

      case SetbackCellState.house:
        // Player-placed house
        final bgColor = hasConflict
            ? BauColours.terracotta.withValues(alpha: 0.15)
            : isSolved
                ? BauColours.sage.withValues(alpha: 0.3)
                : BauColours.blueprintBlue.withValues(alpha: 0.15);
        _drawHouseBackground(canvas, rect, bgColor);

        final iconColor = hasConflict
            ? BauColours.terracotta
            : isSolved
                ? BauColours.sage
                : BauColours.blueprintBlue;
        _drawHouseIcon(canvas, cx, cy, cellSize, iconColor);

      case SetbackCellState.empty:
        // Nothing to draw
        break;
    }
  }

  void _drawHouseBackground(Canvas canvas, Rect rect, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  void _drawHouseIcon(
      Canvas canvas, double cx, double cy, double cellSize, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final houseSize = cellSize * 0.35;

    // Simple house: triangle roof + square body
    final roofPath = Path()
      ..moveTo(cx, cy - houseSize)
      ..lineTo(cx + houseSize, cy - houseSize * 0.2)
      ..lineTo(cx - houseSize, cy - houseSize * 0.2)
      ..close();
    canvas.drawPath(roofPath, paint);

    // Body
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, cy + houseSize * 0.3),
        width: houseSize * 1.6,
        height: houseSize * 0.9,
      ),
      paint,
    );
  }

  void _drawFixedIndicator(Canvas canvas, double x, double y) {
    canvas.drawCircle(
      Offset(x, y),
      3,
      Paint()
        ..color = BauColours.midGrey
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant SetbackPainter oldDelegate) {
    return oldDelegate.cells != cells ||
        oldDelegate.conflictCells != conflictCells ||
        oldDelegate.isSolved != isSolved ||
        oldDelegate.placedCount != placedCount;
  }
}
