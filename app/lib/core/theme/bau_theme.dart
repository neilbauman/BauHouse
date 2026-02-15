import 'package:flutter/material.dart';
import 'colours.dart';

class BauTheme {
  BauTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: BauColours.cream,
        colorScheme: const ColorScheme.light(
          primary: BauColours.blueprintBlue,
          secondary: BauColours.terracotta,
          tertiary: BauColours.sage,
          surface: BauColours.cream,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: BauColours.darkText,
        ),
        fontFamily: 'DMSans',
        appBarTheme: const AppBarTheme(
          backgroundColor: BauColours.cream,
          foregroundColor: BauColours.darkText,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: BauColours.blueprintBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: BauColours.blueprintBlue,
          ),
        ),
        cardTheme: CardThemeData(
          color: BauColours.surface,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
}
