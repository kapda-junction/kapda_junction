import 'package:flutter/material.dart';

/// Colors removed intentionally — let ThemeData.textTheme drive them.
/// Use .copyWith(color: ...) only when you need an explicit override.
class AppTypography {
  AppTypography._();

  static const String fontBody = 'DMSans';
  static const String fontDisplay = 'PlayfairDisplay';

  static const TextStyle displayLarge = TextStyle(fontFamily: fontDisplay, fontSize: 32, fontWeight: FontWeight.w700);
  static const TextStyle displayMedium = TextStyle(fontFamily: fontDisplay, fontSize: 26, fontWeight: FontWeight.w700);
  static const TextStyle displaySmall  = TextStyle(fontFamily: fontDisplay, fontSize: 22, fontWeight: FontWeight.w700);

  static const TextStyle headlineLarge  = TextStyle(fontFamily: fontBody, fontSize: 20, fontWeight: FontWeight.w700);
  static const TextStyle headlineMedium = TextStyle(fontFamily: fontBody, fontSize: 18, fontWeight: FontWeight.w600);
  static const TextStyle headlineSmall  = TextStyle(fontFamily: fontBody, fontSize: 16, fontWeight: FontWeight.w600);

  static const TextStyle bodyLarge  = TextStyle(fontFamily: fontBody, fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  static const TextStyle bodyMedium = TextStyle(fontFamily: fontBody, fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static const TextStyle bodySmall  = TextStyle(fontFamily: fontBody, fontSize: 12, fontWeight: FontWeight.w400, height: 1.4);

  static const TextStyle labelLarge  = TextStyle(fontFamily: fontBody, fontSize: 14, fontWeight: FontWeight.w600);
  static const TextStyle labelMedium = TextStyle(fontFamily: fontBody, fontSize: 12, fontWeight: FontWeight.w600);

  /// Price uses accent color — always override via .copyWith or the theme's secondary color.
  static const TextStyle price = TextStyle(fontFamily: fontBody, fontSize: 15, fontWeight: FontWeight.w700);
  static const TextStyle priceStrikethrough = TextStyle(
    fontFamily: fontBody, fontSize: 12, fontWeight: FontWeight.w400,
    decoration: TextDecoration.lineThrough,
  );
}
