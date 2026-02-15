import 'package:flutter/material.dart';
import 'colours.dart';

class BauTypography {
  BauTypography._();

  static const _fontFamily = 'DMSans';

  static const headline1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: BauColours.darkText,
    height: 1.2,
  );

  static const headline2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: BauColours.darkText,
    height: 1.3,
  );

  static const headline3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: BauColours.darkText,
    height: 1.3,
  );

  static const body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: BauColours.darkText,
    height: 1.5,
  );

  static const bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: BauColours.midGrey,
    height: 1.5,
  );

  static const label = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: BauColours.midGrey,
    letterSpacing: 1.2,
    height: 1.4,
  );

  static const puzzleCoordinate = TextStyle(
    fontFamily: 'monospace',
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: BauColours.midGrey,
    height: 1.0,
  );

  static const puzzleClue = TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: BauColours.darkText,
    height: 1.0,
  );
}
