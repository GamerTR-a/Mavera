import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Ölçüler (Bölüm 11).
abstract final class Dims {
  static const gutter = 16.0;
  static const radius = 12.0;
  static const buttonHeight = 52.0;
  static const criticalHeight = 120.0;
}

/// Material 3 açık / koyu tema.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light, AppColors.light);
  static ThemeData dark() => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness b, AppColors c) {
    final scheme = ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: b,
      primary: c.accent,
      error: c.danger,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: b);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dims.radius));
    return base.copyWith(
      extensions: [c],
      scaffoldBackgroundColor: b == Brightness.light ? const Color(0xFFF7F8FA) : const Color(0xFF111418),
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: b == Brightness.light ? const Color(0xFFF7F8FA) : const Color(0xFF111418),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        shape: shape,
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLowest,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(Dims.buttonHeight),
          shape: shape,
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, Dims.buttonHeight),
          shape: shape,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Dims.radius)),
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
      ),
      listTileTheme: const ListTileThemeData(minVerticalPadding: 12),
    );
  }
}
