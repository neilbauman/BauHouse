import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/colours.dart';

/// Paints a simple architectural sketch of the player's house and plot.
class PlotPainter extends CustomPainter {
  final String houseStyle;
  final Color accentColour;
  final int streak;

  PlotPainter({
    required this.houseStyle,
    required this.accentColour,
    this.streak = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ground line
    final groundPaint = Paint()
      ..color = BauColours.sage.withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, h * 0.75),
      Offset(w, h * 0.75),
      groundPaint,
    );

    // Garden path
    final pathPaint = Paint()
      ..color = BauColours.gridLine
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(w * 0.5, h * 0.75),
      Offset(w * 0.5, h * 0.95),
      pathPaint,
    );

    // House based on style
    switch (houseStyle) {
      case 'classic':
        _drawClassicHouse(canvas, w, h);
      case 'modern':
        _drawModernHouse(canvas, w, h);
      case 'cottage':
        _drawCottageHouse(canvas, w, h);
    }

    // Accent colour fence
    final fencePaint = Paint()
      ..color = accentColour
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Left fence
    for (double x = w * 0.1; x < w * 0.3; x += 12) {
      canvas.drawLine(
        Offset(x, h * 0.73),
        Offset(x, h * 0.78),
        fencePaint,
      );
    }
    canvas.drawLine(
      Offset(w * 0.1, h * 0.75),
      Offset(w * 0.3, h * 0.75),
      fencePaint,
    );

    // Right fence
    for (double x = w * 0.7; x < w * 0.9; x += 12) {
      canvas.drawLine(
        Offset(x, h * 0.73),
        Offset(x, h * 0.78),
        fencePaint,
      );
    }
    canvas.drawLine(
      Offset(w * 0.7, h * 0.75),
      Offset(w * 0.9, h * 0.75),
      fencePaint,
    );

    // Tree (grows with streak)
    if (streak > 0) {
      final treeHeight = math.min(streak * 2.0, 40.0);
      final treePaint = Paint()
        ..color = BauColours.sage
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final treeX = w * 0.2;
      final treeBase = h * 0.75;

      // Trunk
      canvas.drawLine(
        Offset(treeX, treeBase),
        Offset(treeX, treeBase - treeHeight),
        treePaint,
      );

      // Branches
      if (streak >= 3) {
        canvas.drawLine(
          Offset(treeX, treeBase - treeHeight * 0.6),
          Offset(treeX - 10, treeBase - treeHeight * 0.8),
          treePaint,
        );
        canvas.drawLine(
          Offset(treeX, treeBase - treeHeight * 0.5),
          Offset(treeX + 12, treeBase - treeHeight * 0.7),
          treePaint,
        );
      }

      // Canopy
      if (streak >= 7) {
        final canopyPaint = Paint()
          ..color = BauColours.sage.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(treeX, treeBase - treeHeight - 8),
          15,
          canopyPaint,
        );
      }
    }
  }

  void _drawClassicHouse(Canvas canvas, double w, double h) {
    final housePaint = Paint()
      ..color = BauColours.blueprintBlue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Body
    final body = Rect.fromLTWH(w * 0.3, h * 0.45, w * 0.4, h * 0.3);
    canvas.drawRect(body, housePaint);

    // Roof (triangle)
    final roofPath = Path()
      ..moveTo(w * 0.25, h * 0.45)
      ..lineTo(w * 0.5, h * 0.25)
      ..lineTo(w * 0.75, h * 0.45)
      ..close();
    canvas.drawPath(roofPath, housePaint);

    // Door
    canvas.drawRect(
      Rect.fromLTWH(w * 0.44, h * 0.58, w * 0.12, h * 0.17),
      housePaint,
    );

    // Window
    canvas.drawRect(
      Rect.fromLTWH(w * 0.35, h * 0.50, w * 0.07, h * 0.07),
      housePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.58, h * 0.50, w * 0.07, h * 0.07),
      housePaint,
    );

    // Accent chimney
    final chimneyPaint = Paint()
      ..color = accentColour
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.58, h * 0.22, w * 0.06, h * 0.15),
      chimneyPaint,
    );
  }

  void _drawModernHouse(Canvas canvas, double w, double h) {
    final housePaint = Paint()
      ..color = BauColours.blueprintBlue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Main body (flat roof, geometric)
    canvas.drawRect(
      Rect.fromLTWH(w * 0.25, h * 0.35, w * 0.5, h * 0.4),
      housePaint,
    );

    // Flat roof accent
    final roofPaint = Paint()
      ..color = accentColour
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.23, h * 0.35),
      Offset(w * 0.77, h * 0.35),
      roofPaint,
    );

    // Large window
    canvas.drawRect(
      Rect.fromLTWH(w * 0.30, h * 0.42, w * 0.18, h * 0.15),
      housePaint,
    );

    // Door (tall, narrow)
    canvas.drawRect(
      Rect.fromLTWH(w * 0.55, h * 0.45, w * 0.12, h * 0.3),
      housePaint,
    );
  }

  void _drawCottageHouse(Canvas canvas, double w, double h) {
    final housePaint = Paint()
      ..color = BauColours.blueprintBlue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Body (wider, shorter)
    canvas.drawRect(
      Rect.fromLTWH(w * 0.25, h * 0.50, w * 0.5, h * 0.25),
      housePaint,
    );

    // Thatched roof (curved)
    final roofPath = Path()
      ..moveTo(w * 0.20, h * 0.50)
      ..quadraticBezierTo(w * 0.5, h * 0.25, w * 0.80, h * 0.50);
    canvas.drawPath(roofPath, housePaint);

    // Round door
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.68),
      w * 0.05,
      housePaint,
    );

    // Window
    canvas.drawCircle(
      Offset(w * 0.36, h * 0.58),
      w * 0.03,
      housePaint,
    );
    canvas.drawCircle(
      Offset(w * 0.64, h * 0.58),
      w * 0.03,
      housePaint,
    );

    // Accent flower box
    final accentPaint = Paint()
      ..color = accentColour
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.32, h * 0.62, w * 0.08, h * 0.03),
      accentPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.60, h * 0.62, w * 0.08, h * 0.03),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant PlotPainter oldDelegate) {
    return oldDelegate.houseStyle != houseStyle ||
        oldDelegate.accentColour != accentColour ||
        oldDelegate.streak != streak;
  }
}
