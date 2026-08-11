import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_durations.dart';
import '../../core/constants/app_text_styles.dart';

/// Light and dark [ThemeData] for the FoodLink Business App.
///
/// All design tokens are sourced from the constants layer:
///   - Colours → [AppColors]
///   - Spacing / radii → [AppDimensions]
///   - Typography → [AppTextStyles]
///   - Transition timing → [AppDurations]
abstract final class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildTheme(brightness: Brightness.light);
  static ThemeData get dark => _buildTheme(brightness: Brightness.dark);

  // ── Shared shape ─────────────────────────────────────────────
  static final _defaultRadius = BorderRadius.circular(AppDimensions.radiusMD);
  static final _cardShape = RoundedRectangleBorder(borderRadius: _defaultRadius);

  static ThemeData _buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      onPrimary: isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary,
      primaryContainer:
          isDark ? AppColors.darkPrimaryContainer : AppColors.lightPrimaryContainer,
      onPrimaryContainer:
          isDark ? AppColors.darkOnPrimaryContainer : AppColors.lightOnPrimaryContainer,
      secondary: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
      onSecondary: isDark ? AppColors.darkOnSecondary : AppColors.lightOnSecondary,
      secondaryContainer:
          isDark ? AppColors.darkSecondaryContainer : AppColors.lightSecondaryContainer,
      onSecondaryContainer: isDark
          ? AppColors.darkOnSecondaryContainer
          : AppColors.lightOnSecondaryContainer,
      tertiary: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
      onTertiary: isDark ? AppColors.darkOnTertiary : AppColors.lightOnTertiary,
      tertiaryContainer:
          isDark ? AppColors.darkTertiaryContainer : AppColors.lightTertiaryContainer,
      onTertiaryContainer: isDark
          ? AppColors.darkOnTertiaryContainer
          : AppColors.lightOnTertiaryContainer,
      error: isDark ? AppColors.darkError : AppColors.lightError,
      onError: isDark ? AppColors.darkOnError : AppColors.lightOnError,
      surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      onSurface: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
      outline: isDark ? AppColors.darkOutline : AppColors.lightOutline,
      surfaceContainerHighest: isDark
          ? const Color(0xFF302F2F) // subtle elevation surface for dark
          : const Color(0xFFF0EDEC),
      surfaceContainerLow: isDark
          ? const Color(0xFF242323)
          : const Color(0xFFF7F5F4),
    );

    final textTheme = TextTheme(
      displayLarge: AppTextStyles.displayLarge.copyWith(color: colorScheme.onSurface),
      displayMedium: AppTextStyles.displayMedium.copyWith(color: colorScheme.onSurface),
      displaySmall: AppTextStyles.displaySmall.copyWith(color: colorScheme.onSurface),
      headlineLarge: AppTextStyles.headlineLarge.copyWith(color: colorScheme.onSurface),
      headlineMedium: AppTextStyles.headlineMedium.copyWith(color: colorScheme.onSurface),
      headlineSmall: AppTextStyles.headlineSmall.copyWith(color: colorScheme.onSurface),
      titleLarge: AppTextStyles.titleLarge.copyWith(color: colorScheme.onSurface),
      titleMedium: AppTextStyles.titleMedium.copyWith(color: colorScheme.onSurface),
      titleSmall: AppTextStyles.titleSmall.copyWith(color: colorScheme.onSurface),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: colorScheme.onSurface),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: colorScheme.onSurface),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: colorScheme.onSurface),
      labelLarge: AppTextStyles.labelLarge.copyWith(color: colorScheme.onSurface),
      labelMedium: AppTextStyles.labelMedium.copyWith(color: colorScheme.onSurface),
      labelSmall: AppTextStyles.labelSmall.copyWith(color: colorScheme.onSurface),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,

      // ── AppBar ─────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        toolbarHeight: AppDimensions.appBarHeight,
      ),

      // ── Cards ──────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        shape: _cardShape,
        color: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // ── Input fields ───────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceMD,
          vertical: AppDimensions.spaceMD,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        floatingLabelStyle: AppTextStyles.labelMedium.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.38),
        ),
        errorStyle: AppTextStyles.labelSmall.copyWith(color: colorScheme.error),
        prefixIconColor: colorScheme.onSurface.withValues(alpha: 0.6),
        suffixIconColor: colorScheme.onSurface.withValues(alpha: 0.6),
      ),

      // ── Filled button ──────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceLG,
            vertical: AppDimensions.spaceMD,
          ),
        ),
      ),

      // ── Outlined button ────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          side: BorderSide(color: colorScheme.outline),
          textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceLG,
            vertical: AppDimensions.spaceMD,
          ),
        ),
      ),

      // ── Text button ────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceMD,
            vertical: AppDimensions.spaceSM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
          ),
        ),
      ),

      // ── Divider ────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withValues(alpha: 0.2),
        thickness: 1,
        space: AppDimensions.spaceMD,
      ),

      // ── ListTile ───────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceMD,
          vertical: AppDimensions.spaceXS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        ),
        titleTextStyle: AppTextStyles.titleSmall.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: AppTextStyles.bodySmall.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),

      // ── Bottom navigation ──────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.5),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTextStyles.labelSmall,
      ),

      // ── Navigation rail ────────────────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        selectedIconTheme: IconThemeData(color: colorScheme.primary, size: 24),
        unselectedIconTheme:
            IconThemeData(color: colorScheme.onSurface.withValues(alpha: 0.5), size: 24),
        selectedLabelTextStyle: AppTextStyles.labelSmall.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: AppTextStyles.labelSmall.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        indicatorColor: colorScheme.primaryContainer,
        minWidth: AppDimensions.navRailWidth,
      ),

      // ── Snack bar ──────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        ),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
      ),

      // ── Dialog ─────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        ),
        elevation: 3,
        titleTextStyle: AppTextStyles.headlineSmall.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),

      // ── Chip ───────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceMD,
          vertical: AppDimensions.spaceXS,
        ),
        labelStyle: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600),
      ),

      // ── Page transitions ───────────────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
