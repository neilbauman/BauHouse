import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/colours.dart';
import 'conduit_models.dart';

/// Custom painter for rendering the CONDUIT (pipes) puzzle grid.
///
/// Draws pipe segments with connections based on cell type and rotation.
/// Connected cells are highlighted in blueprint blue; disconnected in grey.
class ConduitPainter extends CustomPainter {
  final int width;
  final int height;
  final List<ConduitCell> cells;
  final Set<int> connectedCells;
  final bool isSolved;
  final int? lastTappedIndex;

  ConduitPainter({
    required this.width,
    required this.height,
    required this.cells,
    required this.connectedCells,
    this.isSolved = false,
    this.lastTappedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / width;
    final cellHeight = size.height / height;
    final cellSize = math.min(cellWidth, cellHeight);

    // Center the grid
    final offsetX = (size.width - cellSize * width) / 2;
    final offsetY = (size.height - cellSize * height) / 2;

    // Draw background grid
    _drawGrid(canvas, offsetX, offsetY, cellSize);

    // Draw each cell's pipe
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        final idx = row * width + col;
        final cell = cells[idx];
        final isConnected = connectedCells.contains(idx);
        final cx = offsetX + col * cellSize + cellSize / 2;
        final cy = offsetY + row * cellSize + cellSize / 2;

        _drawPipe(canvas, cx, cy, cellSize, cell, isConnected);
      }
    }
  }

  void _drawGrid(Canvas canvas, double offsetX, double offsetY, double cellSize) {
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

  void _drawPipe(
    Canvas canvas,
    double cx,
    double cy,
    double cellSize,
    ConduitCell cell,
    bool isConnected,
  ) {
    final color = isSolved
        ? BauColours.sage
        : isConnected
            ? BauColours.blueprintBlue
            : BauColours.midGrey;

    final pipePaint = Paint()
      ..color = color
      ..strokeWidth = cellSize * 0.18
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final halfCell = cellSize / 2;
    final pipeLength = halfCell * 0.85;

    // Draw a line from center toward each connected direction
    for (final dir in cell.connections) {
      late Offset end;
      switch (dir) {
        case 0: // up
          end = Offset(cx, cy - pipeLength);
        case 1: // right
          end = Offset(cx + pipeLength, cy);
        case 2: // down
          end = Offset(cx, cy + pipeLength);
        case 3: // left
          end = Offset(cx - pipeLength, cy);
      }
      canvas.drawLine(Offset(cx, cy), end, pipePaint);
    }

    // Draw center dot
    canvas.drawCircle(Offset(cx, cy), cellSize * 0.08, dotPaint);
  }

  @override
  bool shouldRepaint(covariant ConduitPainter oldDelegate) {
    return oldDelegate.cells != cells ||
        oldDelegate.connectedCells != connectedCells ||
        oldDelegate.isSolved != isSolved ||
        oldDelegate.lastTappedIndex != lastTappedIndex;
  }
}
