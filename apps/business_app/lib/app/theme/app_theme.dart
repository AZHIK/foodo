import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  static final _cardShape = RoundedRectangleBorder(
    borderRadius: _defaultRadius,
  );

  static ThemeData _buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      onPrimary: isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary,
      primaryContainer: isDark
          ? AppColors.darkPrimaryContainer
          : AppColors.lightPrimaryContainer,
      onPrimaryContainer: isDark
          ? AppColors.darkOnPrimaryContainer
          : AppColors.lightOnPrimaryContainer,
      secondary: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
      onSecondary: isDark
          ? AppColors.darkOnSecondary
          : AppColors.lightOnSecondary,
      secondaryContainer: isDark
          ? AppColors.darkSecondaryContainer
          : AppColors.lightSecondaryContainer,
      onSecondaryContainer: isDark
          ? AppColors.darkOnSecondaryContainer
          : AppColors.lightOnSecondaryContainer,
      tertiary: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
      onTertiary: isDark ? AppColors.darkOnTertiary : AppColors.lightOnTertiary,
      tertiaryContainer: isDark
          ? AppColors.darkTertiaryContainer
          : AppColors.lightTertiaryContainer,
      onTertiaryContainer: isDark
          ? AppColors.darkOnTertiaryContainer
          : AppColors.lightOnTertiaryContainer,
      error: isDark ? AppColors.darkError : AppColors.lightError,
      onError: isDark ? AppColors.darkOnError : AppColors.lightOnError,
      surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      onSurface: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
      outline: isDark ? AppColors.darkOutline : AppColors.lightOutline,
      outlineVariant: isDark
          ? AppColors.darkOutlineVariant
          : AppColors.lightOutlineVariant,
      shadow: isDark ? AppColors.darkShadow : AppColors.lightShadow,
      inverseSurface: isDark
          ? AppColors.darkInverseSurface
          : AppColors.lightInverseSurface,
      onInverseSurface: isDark
          ? AppColors.darkOnInverseSurface
          : AppColors.lightOnInverseSurface,
      surfaceContainerHighest: isDark
          ? AppColors.darkSurfaceContainerHighest
          : AppColors.lightSurfaceContainerHighest,
      surfaceContainerLow: isDark
          ? AppColors.darkSurfaceContainerLow
          : AppColors.lightSurfaceContainerLow,
      surfaceContainerLowest: isDark
          ? AppColors.darkSurfaceContainerLowest
          : AppColors.lightSurfaceContainerLowest,
    );

    const baseTextTheme = TextTheme(
      displayLarge: AppTextStyles.displayLarge,
      displayMedium: AppTextStyles.displayMedium,
      displaySmall: AppTextStyles.displaySmall,
      headlineLarge: AppTextStyles.headlineLarge,
      headlineMedium: AppTextStyles.headlineMedium,
      headlineSmall: AppTextStyles.headlineSmall,
      titleLarge: AppTextStyles.titleLarge,
      titleMedium: AppTextStyles.titleMedium,
      titleSmall: AppTextStyles.titleSmall,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.labelLarge,
      labelMedium: AppTextStyles.labelMedium,
      labelSmall: AppTextStyles.labelSmall,
    );

    final textTheme = baseTextTheme.apply(
      fontFamily: GoogleFonts.inter().fontFamily,
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      canvasColor: colorScheme.surface,

      // ── AppBar ─────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
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
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // ── Input fields ───────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        fillColor: null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceMD,
          vertical: AppDimensions.spaceSM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.9),
            width: 0.8,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.9),
            width: 0.8,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: BorderSide(color: colorScheme.error, width: 1.2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.55),
            width: 0.8,
          ),
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
        helperStyle: AppTextStyles.bodySmall.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.52),
        ),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: colorScheme.error),
        prefixIconColor: colorScheme.onSurface.withValues(alpha: 0.48),
        suffixIconColor: colorScheme.onSurface.withValues(alpha: 0.48),
      ),

      // ── Filled button ──────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.onSurface.withValues(
            alpha: 0.08,
          ),
          disabledForegroundColor: colorScheme.onSurface.withValues(
            alpha: 0.38,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceLG,
            vertical: AppDimensions.spaceSM,
          ),
        ),
      ),

      // ── Outlined button ────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          foregroundColor: colorScheme.onSurface.withValues(alpha: 0.82),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.95),
            width: 0.8,
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceLG,
            vertical: AppDimensions.spaceSM,
          ),
        ),
      ),

      // ── Text button ────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
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
        color: colorScheme.outline.withValues(alpha: 0.12),
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
        elevation: 0,
        selectedLabelStyle: AppTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: AppTextStyles.labelSmall,
      ),

      // ── Navigation rail ────────────────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        selectedIconTheme: IconThemeData(color: colorScheme.primary, size: 24),
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurface.withValues(alpha: 0.5),
          size: 24,
        ),
        selectedLabelTextStyle: AppTextStyles.labelSmall.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: AppTextStyles.labelSmall.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        indicatorColor: colorScheme.primary.withValues(alpha: 0.1),
        minWidth: AppDimensions.navRailWidth,
      ),

      // ── Snack bar ──────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        ),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
        ),
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
        labelStyle: AppTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
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
