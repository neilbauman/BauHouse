import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/colours.dart';
import 'lamp_models.dart';
import 'lamp_engine.dart';

/// Custom painter for rendering the LAMP (Light Up / Akari) puzzle grid.
///
/// Draws black cells (with optional clue numbers), illuminated cells,
/// light bulb icons, and conflict indicators.
class LampPainter extends CustomPainter {
  final int width;
  final int height;
  final List<LampGridCell> gridCells;
  final List<LampPlayState> playStates;
  final LampEngine engine;
  final bool isSolved;

  LampPainter({
    required this.width,
    required this.height,
    required this.gridCells,
    required this.playStates,
    required this.engine,
    this.isSolved = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / width;
    final cellHeight = size.height / height;
    final cellSize = math.min(cellWidth, cellHeight);

    final offsetX = (size.width - cellSize * width) / 2;
    final offsetY = (size.height - cellSize * height) / 2;

    // Draw cell backgrounds
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        _drawCell(canvas, offsetX, offsetY, cellSize, row, col);
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
      double cellSize, int row, int col) {
    final idx = row * width + col;
    final gridCell = gridCells[idx];
    final playState = playStates[idx];
    final x = offsetX + col * cellSize;
    final y = offsetY + row * cellSize;
    final cx = x + cellSize / 2;
    final cy = y + cellSize / 2;
    final rect = Rect.fromLTWH(x, y, cellSize, cellSize);

    if (gridCell.type == LampCellType.black) {
      // Black cell
      canvas.drawRect(
        rect,
        Paint()
          ..color = BauColours.darkText
          ..style = PaintingStyle.fill,
      );

      // Draw clue number if present
      if (gridCell.clue != null) {
        final correct = engine.isClueCorrect(row, col);
        final over = engine.isClueOver(row, col);
        final clueColor = (correct == true)
            ? BauColours.sage
            : over
                ? BauColours.terracotta
                : BauColours.cream;

        final textPainter = TextPainter(
          text: TextSpan(
            text: '${gridCell.clue}',
            style: TextStyle(
              color: clueColor,
              fontSize: cellSize * 0.5,
              fontWeight: FontWeight.w700,
              fontFamily: 'DMSans',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
        );
      }
    } else {
      // Empty cell — draw background based on play state
      switch (playState) {
        case LampPlayState.lit:
          canvas.drawRect(
            rect,
            Paint()
              ..color = (isSolved ? BauColours.sage : BauColours.blueprintBlue)
                  .withValues(alpha: 0.12)
              ..style = PaintingStyle.fill,
          );

        case LampPlayState.light:
          canvas.drawRect(
            rect,
            Paint()
              ..color = (isSolved ? BauColours.sage : BauColours.blueprintBlue)
                  .withValues(alpha: 0.2)
              ..style = PaintingStyle.fill,
          );
          _drawLightBulb(canvas, cx, cy, cellSize,
              isSolved ? BauColours.sage : BauColours.blueprintBlue);

        case LampPlayState.lightConflict:
          canvas.drawRect(
            rect,
            Paint()
              ..color = BauColours.terracotta.withValues(alpha: 0.15)
              ..style = PaintingStyle.fill,
          );
          _drawLightBulb(canvas, cx, cy, cellSize, BauColours.terracotta);

        case LampPlayState.dark:
          break;
      }
    }
  }

  void _drawLightBulb(
      Canvas canvas, double cx, double cy, double cellSize, Color color) {
    // Simple bulb: filled circle with rays
    final radius = cellSize * 0.22;

    // Glow
    canvas.drawCircle(
      Offset(cx, cy),
      radius * 1.6,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );

    // Bulb body
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    // Small highlight
    canvas.drawCircle(
      Offset(cx - radius * 0.3, cy - radius * 0.3),
      radius * 0.25,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant LampPainter oldDelegate) {
    return oldDelegate.playStates != playStates ||
        oldDelegate.isSolved != isSolved;
  }
}
