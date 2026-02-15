import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/colours.dart';
import 'parcel_models.dart';

/// Custom painter for rendering the PARCEL (Shikaku) puzzle grid.
///
/// Draws numbered givens, placed region rectangles with colour-coded
/// validation state, and the current drag-preview rectangle.
class ParcelPainter extends CustomPainter {
  final int width;
  final int height;
  final List<ParcelGiven> givens;
  final List<ParcelRegion> regions;
  final ParcelRegion? dragPreview;
  final bool isSolved;
  final String Function(ParcelRegion) validateRegion;

  /// Palette for distinct region colouring (up to 12, then wraps).
  static const _regionPalette = [
    Color(0xFF5B8FB9), // blue
    Color(0xFFB95B5B), // red
    Color(0xFF5BB98F), // green
    Color(0xFFB9A55B), // gold
    Color(0xFF8F5BB9), // purple
    Color(0xFF5BB9B9), // teal
    Color(0xFFB97A5B), // orange
    Color(0xFF7A5BB9), // indigo
    Color(0xFFB95B8F), // rose
    Color(0xFF5BB95B), // lime
    Color(0xFFB9B95B), // yellow
    Color(0xFF5B5BB9), // navy
  ];

  ParcelPainter({
    required this.width,
    required this.height,
    required this.givens,
    required this.regions,
    required this.validateRegion,
    this.dragPreview,
    this.isSolved = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / width;
    final cellHeight = size.height / height;
    final cellSize = math.min(cellWidth, cellHeight);

    final offsetX = (size.width - cellSize * width) / 2;
    final offsetY = (size.height - cellSize * height) / 2;

    // Draw placed regions
    for (int i = 0; i < regions.length; i++) {
      _drawRegion(canvas, offsetX, offsetY, cellSize, regions[i], i);
    }

    // Draw drag preview
    if (dragPreview != null) {
      _drawDragPreview(canvas, offsetX, offsetY, cellSize, dragPreview!);
    }

    // Draw grid lines
    _drawGrid(canvas, offsetX, offsetY, cellSize);

    // Draw given numbers
    for (final given in givens) {
      _drawGiven(canvas, offsetX, offsetY, cellSize, given);
    }
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

  void _drawRegion(Canvas canvas, double offsetX, double offsetY,
      double cellSize, ParcelRegion region, int index) {
    final status = validateRegion(region);

    Color fillColor;
    if (isSolved) {
      fillColor = BauColours.sage.withValues(alpha: 0.3);
    } else {
      final baseColor = _regionPalette[index % _regionPalette.length];
      fillColor = status == 'valid'
          ? baseColor.withValues(alpha: 0.25)
          : baseColor.withValues(alpha: 0.15);
    }

    final rect = Rect.fromLTWH(
      offsetX + region.col * cellSize + 1,
      offsetY + region.row * cellSize + 1,
      region.width * cellSize - 2,
      region.height * cellSize - 2,
    );

    // Fill
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    // Border
    Color borderColor;
    if (isSolved) {
      borderColor = BauColours.sage;
    } else if (status == 'valid') {
      borderColor = BauColours.blueprintBlue;
    } else {
      borderColor = BauColours.terracotta.withValues(alpha: 0.6);
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()
        ..color = borderColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawDragPreview(Canvas canvas, double offsetX, double offsetY,
      double cellSize, ParcelRegion preview) {
    final rect = Rect.fromLTWH(
      offsetX + preview.col * cellSize + 1,
      offsetY + preview.row * cellSize + 1,
      preview.width * cellSize - 2,
      preview.height * cellSize - 2,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()
        ..color = BauColours.blueprintBlue.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()
        ..color = BauColours.blueprintBlue.withValues(alpha: 0.5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // Show area in the center of the preview
    final area = preview.area;
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$area',
        style: TextStyle(
          color: BauColours.blueprintBlue.withValues(alpha: 0.5),
          fontSize: cellSize * 0.3,
          fontWeight: FontWeight.w700,
          fontFamily: 'DMSans',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        rect.center.dx - textPainter.width / 2,
        rect.center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawGiven(Canvas canvas, double offsetX, double offsetY,
      double cellSize, ParcelGiven given) {
    final cx = offsetX + given.col * cellSize + cellSize / 2;
    final cy = offsetY + given.row * cellSize + cellSize / 2;

    // Background circle
    canvas.drawCircle(
      Offset(cx, cy),
      cellSize * 0.3,
      Paint()
        ..color = BauColours.cream
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      cellSize * 0.3,
      Paint()
        ..color = BauColours.darkText
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // Number
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${given.value}',
        style: TextStyle(
          color: BauColours.darkText,
          fontSize: cellSize * 0.35,
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

  @override
  bool shouldRepaint(covariant ParcelPainter oldDelegate) {
    return oldDelegate.regions != regions ||
        oldDelegate.dragPreview != dragPreview ||
        oldDelegate.isSolved != isSolved;
  }
}
