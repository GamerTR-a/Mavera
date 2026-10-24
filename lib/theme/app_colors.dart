import 'package:flutter/material.dart';

/// Anlamsal renkler (Bölüm 11). Tonlu yüzeyler rengin %12–16 opaklığıdır.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.safe,
    required this.warning,
    required this.danger,
    required this.accent,
    required this.brand,
  });

  final Color safe;
  final Color warning;
  final Color danger;
  final Color accent;

  /// Logodaki lacivert.
  final Color brand;

  static const light = AppColors(
    safe: Color(0xFF1E9E3A),
    warning: Color(0xFFE8A317),
    danger: Color(0xFFD93636),
    accent: Color(0xFF2B6FD6),
    brand: Color(0xFF0F2346),
  );

  static const dark = AppColors(
    safe: Color(0xFF3FCB5E),
    warning: Color(0xFFF5B942),
    danger: Color(0xFFFF5A5A),
    accent: Color(0xFF5B95F0),
    brand: Color(0xFF9DB4DE),
  );

  /// Rengin tonlu yüzey karşılığı.
  static Color tint(Color c, [double opacity = 0.14]) => c.withValues(alpha: opacity);

  @override
  AppColors copyWith({Color? safe, Color? warning, Color? danger, Color? accent, Color? brand}) => AppColors(
        safe: safe ?? this.safe,
        warning: warning ?? this.warning,
        danger: danger ?? this.danger,
        accent: accent ?? this.accent,
        brand: brand ?? this.brand,
      );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      safe: Color.lerp(safe, other.safe, t) ?? safe,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      brand: Color.lerp(brand, other.brand, t) ?? brand,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
