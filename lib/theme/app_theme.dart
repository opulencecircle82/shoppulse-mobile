import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/shop.dart';

Color hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  final buffer = cleaned.length == 6 ? 'ff$cleaned' : cleaned;
  return Color(int.parse(buffer, radix: 16));
}

/// Builds a ThemeData from a shop's brand color + font settings, configured
/// in the ShopPulse web dashboard under "Customize Mobile App".
ThemeData buildAppTheme(Shop shop) {
  final primary = hexToColor(shop.primaryColorHex);
  final accent = hexToColor(shop.accentColorHex);
  final baseTextTheme = GoogleFonts.getTextTheme(shop.mobileAppFontFamily);

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
      brightness: Brightness.dark,
    ),
    textTheme: baseTextTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? accent : null,
      ),
    ),
  );
}
