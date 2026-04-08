import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark  => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final cs = isDark ? _darkScheme : _lightScheme;
    final textColor = cs.onSurface;
    final subColor  = cs.onSurfaceVariant;

    // AppBar uses white background in light mode (content area), dark in dark mode
    final appBarBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final appBarFg = isDark ? Colors.white : AppColors.textPrimary;

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? const Color(0xFF0B1120) : AppColors.bgBody,
      fontFamily: 'Roboto',

      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: cs.shadow,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineMedium.copyWith(color: appBarFg),
        iconTheme: IconThemeData(color: appBarFg),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: cs.outline.withAlpha(isDark ? 40 : 80), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: AppTypography.labelLarge,
          elevation: 0,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: AppTypography.labelLarge,
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.onSurface,
          side: BorderSide(color: cs.outline),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.accent),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: AppTypography.bodyMedium.copyWith(color: subColor),
        labelStyle: AppTypography.bodyMedium.copyWith(color: subColor),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        selectedColor: AppColors.accent.withAlpha(30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: cs.outline),
        ),
        labelStyle: AppTypography.bodySmall.copyWith(color: textColor),
      ),

      dividerTheme: DividerThemeData(color: cs.outline, thickness: 1),

      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: textColor,
        iconColor: subColor,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.accent : null),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.accent.withAlpha(80) : null),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: const Color(0xFF0F172A),
        selectedIconTheme: const IconThemeData(color: AppColors.accent),
        unselectedIconTheme: const IconThemeData(color: Color(0xFF94A3B8)),
        selectedLabelTextStyle: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: const TextStyle(color: Color(0xFF94A3B8)),
        indicatorColor: Color(0x22F59E0B),
      ),

      textTheme: TextTheme(
        displayLarge:   AppTypography.displayLarge.copyWith(color: textColor),
        displayMedium:  AppTypography.displayMedium.copyWith(color: textColor),
        headlineLarge:  AppTypography.headlineLarge.copyWith(color: textColor),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: textColor),
        headlineSmall:  AppTypography.headlineSmall.copyWith(color: textColor),
        titleLarge:     AppTypography.headlineMedium.copyWith(color: textColor),
        titleMedium:    AppTypography.headlineSmall.copyWith(color: textColor),
        bodyLarge:      AppTypography.bodyLarge.copyWith(color: textColor),
        bodyMedium:     AppTypography.bodyMedium.copyWith(color: textColor),
        bodySmall:      AppTypography.bodySmall.copyWith(color: subColor),
        labelLarge:     AppTypography.labelLarge.copyWith(color: textColor),
        labelMedium:    AppTypography.labelMedium.copyWith(color: textColor),
      ),
    );
  }

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary:    AppColors.accent,
    onPrimary:  Colors.white,
    primaryContainer: Color(0xFFFEF3C7),
    onPrimaryContainer: Color(0xFF78350F),
    secondary:  Color(0xFF0F172A),
    onSecondary: Colors.white,
    surface:    Colors.white,
    onSurface:  AppColors.textPrimary,
    surfaceContainerHighest: AppColors.bgBody,
    surfaceContainerLow: AppColors.bgBody,
    onSurfaceVariant: AppColors.textSecondary,
    outline:    AppColors.border,
    outlineVariant: Color(0xFFE2E8F0),
    error:      AppColors.error,
    onError:    Colors.white,
    shadow:     Color(0x1A000000),
    scrim:      Color(0x33000000),
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary:    AppColors.accent,
    onPrimary:  Color(0xFF0F172A),
    primaryContainer: Color(0xFF78350F),
    onPrimaryContainer: Color(0xFFFEF3C7),
    secondary:  Color(0xFF93C5FD),
    onSecondary: Color(0xFF0F172A),
    surface:    Color(0xFF1E293B),
    onSurface:  Color(0xFFF1F5F9),
    surfaceContainerHighest: Color(0xFF0F172A),
    surfaceContainerLow: Color(0xFF0B1120),
    onSurfaceVariant: Color(0xFF94A3B8),
    outline:    Color(0xFF334155),
    outlineVariant: Color(0xFF1E293B),
    error:      Color(0xFFFCA5A5),
    onError:    Color(0xFF450A0A),
    shadow:     Color(0x40000000),
    scrim:      Color(0x66000000),
  );
}
