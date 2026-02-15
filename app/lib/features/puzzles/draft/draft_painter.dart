import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/colours.dart';
import 'draft_models.dart';

/// Custom painter for rendering the DRAFT (Nonogram) puzzle grid.
///
/// Draws:
/// - Row clues on the left
/// - Column clues on the top
/// - The grid with filled/marked/empty cells
/// - Satisfied rows/columns with a visual indicator
class DraftPainter extends CustomPainter {
  final int width;
  final int height;
  final List<List<int>> rowClues;
  final List<List<int>> colClues;
  final List<DraftCellState> cells;
  final Set<int> satisfiedRows;
  final Set<int> satisfiedCols;
  final bool isSolved;

  /// Fraction of the total width/height reserved for clue gutters.
  static const _clueRatio = 0.25;

  DraftPainter({
    required this.width,
    required this.height,
    required this.rowClues,
    required this.colClues,
    required this.cells,
    required this.satisfiedRows,
    required this.satisfiedCols,
    this.isSolved = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Reserve space for clues
    final clueWidth = size.width * _clueRatio;
    final clueHeight = size.height * _clueRatio;

    final gridWidth = size.width - clueWidth;
    final gridHeight = size.height - clueHeight;

    final cellW = gridWidth / width;
    final cellH = gridHeight / height;
    final cellSize = math.min(cellW, cellH);

    final gridOffX = clueWidth;
    final gridOffY = clueHeight;

    // Draw grid cells
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        _drawCell(canvas, gridOffX, gridOffY, cellSize, row, col);
      }
    }

    // Draw grid lines
    _drawGridLines(canvas, gridOffX, gridOffY, cellSize);

    // Draw row clues
    for (int row = 0; row < height; row++) {
      _drawRowClue(canvas, gridOffX, gridOffY, cellSize, clueWidth, row);
    }

    // Draw column clues
    for (int col = 0; col < width; col++) {
      _drawColClue(canvas, gridOffX, gridOffY, cellSize, clueHeight, col);
    }
  }

  void _drawCell(Canvas canvas, double gridOffX, double gridOffY,
      double cellSize, int row, int col) {
    final idx = row * width + col;
    final state = cells[idx];
    final x = gridOffX + col * cellSize;
    final y = gridOffY + row * cellSize;

    switch (state) {
      case DraftCellState.filled:
        final color = isSolved
            ? BauColours.sage
            : BauColours.blueprintBlue;
        canvas.drawRect(
          Rect.fromLTWH(x + 1, y + 1, cellSize - 2, cellSize - 2),
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );

      case DraftCellState.marked:
        // Small X to indicate intentionally empty
        final xPaint = Paint()
          ..color = BauColours.midGrey.withValues(alpha: 0.5)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        final margin = cellSize * 0.3;
        canvas.drawLine(
          Offset(x + margin, y + margin),
          Offset(x + cellSize - margin, y + cellSize - margin),
          xPaint,
        );
        canvas.drawLine(
          Offset(x + cellSize - margin, y + margin),
          Offset(x + margin, y + cellSize - margin),
          xPaint,
        );

      case DraftCellState.empty:
        break;
    }
  }

  void _drawGridLines(
      Canvas canvas, double gridOffX, double gridOffY, double cellSize) {
    final thinPaint = Paint()
      ..color = BauColours.gridLine
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final thickPaint = Paint()
      ..color = BauColours.gridLine
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int row = 0; row <= height; row++) {
      final paint = (row % 5 == 0) ? thickPaint : thinPaint;
      canvas.drawLine(
        Offset(gridOffX, gridOffY + row * cellSize),
        Offset(gridOffX + width * cellSize, gridOffY + row * cellSize),
        paint,
      );
    }
    for (int col = 0; col <= width; col++) {
      final paint = (col % 5 == 0) ? thickPaint : thinPaint;
      canvas.drawLine(
        Offset(gridOffX + col * cellSize, gridOffY),
        Offset(gridOffX + col * cellSize, gridOffY + height * cellSize),
        paint,
      );
    }
  }

  void _drawRowClue(Canvas canvas, double gridOffX, double gridOffY,
      double cellSize, double clueWidth, int row) {
    final clue = rowClues[row];
    final satisfied = satisfiedRows.contains(row);
    final text = clue.isEmpty ? '0' : clue.join(' ');

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: satisfied
              ? BauColours.sage
              : BauColours.darkText,
          fontSize: cellSize * 0.35,
          fontWeight: FontWeight.w500,
          fontFamily: 'DMSans',
          decoration:
              satisfied ? TextDecoration.lineThrough : TextDecoration.none,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    )..layout(maxWidth: clueWidth - 8);

    final y = gridOffY + row * cellSize + (cellSize - textPainter.height) / 2;
    textPainter.paint(
      canvas,
      Offset(gridOffX - textPainter.width - 6, y),
    );
  }

  void _drawColClue(Canvas canvas, double gridOffX, double gridOffY,
      double cellSize, double clueHeight, int col) {
    final clue = colClues[col];
    final satisfied = satisfiedCols.contains(col);
    final text = clue.isEmpty ? '0' : clue.join('\n');

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: satisfied
              ? BauColours.sage
              : BauColours.darkText,
          fontSize: cellSize * 0.35,
          fontWeight: FontWeight.w500,
          fontFamily: 'DMSans',
          decoration:
              satisfied ? TextDecoration.lineThrough : TextDecoration.none,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: cellSize);

    final x = gridOffX + col * cellSize + (cellSize - textPainter.width) / 2;
    textPainter.paint(
      canvas,
      Offset(x, gridOffY - textPainter.height - 4),
    );
  }

  @override
  bool shouldRepaint(covariant DraftPainter oldDelegate) {
    return oldDelegate.cells != cells ||
        oldDelegate.satisfiedRows != satisfiedRows ||
        oldDelegate.satisfiedCols != satisfiedCols ||
        oldDelegate.isSolved != isSolved;
  }
}
