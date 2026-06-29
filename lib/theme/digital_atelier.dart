import 'package:flutter/material.dart';

class DigitalAtelierTokens {
  const DigitalAtelierTokens._();

  static const Color background = Color(0xFF0A0A0A);
  static const Color textPrimary = Color(0xFFF0EDE8);
  static const Color accentOrange = Color(0xFFF97316);

  static const String coachVoiceFontFamily = 'Playfair';
  static const String dataFontFamily = 'Inter';

  static const double cornerRadius = 4;
}

ThemeData buildDigitalAtelierTheme() {
  final shape =
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
      );

  const colorScheme = ColorScheme.dark(
    surface: DigitalAtelierTokens.background,
    onSurface: DigitalAtelierTokens.textPrimary,
    primary: DigitalAtelierTokens.accentOrange,
    onPrimary: DigitalAtelierTokens.background,
    secondary: DigitalAtelierTokens.accentOrange,
  );

  const baseTextTheme = TextTheme(
    headlineMedium: TextStyle(
      fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
      color: DigitalAtelierTokens.textPrimary,
      fontSize: 40,
      fontWeight: FontWeight.w600,
      height: 1.1,
    ),
    titleMedium: TextStyle(
      fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
      color: DigitalAtelierTokens.textPrimary,
      fontSize: 22,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: TextStyle(
      fontFamily: DigitalAtelierTokens.dataFontFamily,
      color: DigitalAtelierTokens.textPrimary,
      fontSize: 16,
      height: 1.4,
    ),
    bodyMedium: TextStyle(
      fontFamily: DigitalAtelierTokens.dataFontFamily,
      color: DigitalAtelierTokens.textPrimary,
      fontSize: 14,
      height: 1.4,
    ),
  );

  return ThemeData(
    brightness: Brightness.dark,
    fontFamily: DigitalAtelierTokens.dataFontFamily,
    scaffoldBackgroundColor: DigitalAtelierTokens.background,
    colorScheme: colorScheme,
    textTheme: baseTextTheme,
    useMaterial3: true,
    cardTheme: CardThemeData(
      color: Color(0xFF0A0A0A),
      margin: EdgeInsets.zero,
      shape: shape,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DigitalAtelierTokens.accentOrange,
        foregroundColor: DigitalAtelierTokens.background,
        shape: shape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: DigitalAtelierTokens.textPrimary,
        shape: shape,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF151515),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
        borderSide: const BorderSide(color: Color(0xFFF97316)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
        borderSide: const BorderSide(color: Color(0xFFF97316)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
        borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.2),
      ),
    ),
  );
}
