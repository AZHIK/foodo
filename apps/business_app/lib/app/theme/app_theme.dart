import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Light and dark [ThemeData] for the FoodLink Business App.
///
/// Both themes are built with [ColorScheme.fromSeed] using the agreed
/// terracotta/sage/gold seed colours.  The exact light/dark colour
/// tokens from [AppColors] can be used for fine-grained control
/// wherever the seed-generated scheme isn't sufficient.
abstract final class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildLight();
  static ThemeData get dark => _buildDark();

  static ThemeData _buildLight() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seedTerracotta,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
    );
  }

  static ThemeData _buildDark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seedTerracotta,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
    );
  }
}
