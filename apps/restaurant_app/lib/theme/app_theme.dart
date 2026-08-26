import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'breakpoints.dart';

/// Semantic colours that Material's [ColorScheme] has no slot for — order
/// statuses, "in cart" highlights and the like. Exposed as a [ThemeExtension]
/// so widgets read them from the theme instead of branching on brightness.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.danger,
    required this.dangerContainer,
    required this.hairline,
  });

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color danger;
  final Color dangerContainer;

  /// Low-contrast divider colour for table rows and panel edges.
  final Color hairline;

  static const light = AppSemanticColors(
    success: Color(0xFF157F4B),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFDFF5E8),
    warning: Color(0xFF8A5A00),
    onWarning: Color(0xFFFFFFFF),
    warningContainer: Color(0xFFFDF0D5),
    danger: Color(0xFFB3261E),
    dangerContainer: Color(0xFFFCE9E7),
    hairline: Color(0x14000000),
  );

  static const dark = AppSemanticColors(
    success: Color(0xFF6ED3A0),
    onSuccess: Color(0xFF00341C),
    successContainer: Color(0xFF17402C),
    warning: Color(0xFFF0C070),
    onWarning: Color(0xFF3A2A00),
    warningContainer: Color(0xFF453515),
    danger: Color(0xFFFFB4AB),
    dangerContainer: Color(0xFF4E1F1B),
    hairline: Color(0x1FFFFFFF),
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? danger,
    Color? dangerContainer,
    Color? hairline,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      danger: danger ?? this.danger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      hairline: hairline ?? this.hairline,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
    );
  }
}

extension AppThemeX on ThemeData {
  AppSemanticColors get semantic => extension<AppSemanticColors>()!;
}

extension AppThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  AppSemanticColors get semantic => Theme.of(this).semantic;
}

abstract final class AppTheme {
  /// Deep emerald-teal. Reads as professional retail hardware software rather
  /// than a consumer food app, and stays legible under the harsh overhead
  /// lighting a counter terminal actually lives under.
  static const seed = Color(0xFF0B6B57);

  static const _fontFamily = 'Poppins';

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      // A near-neutral surface keeps the large cart/grid panels calm next to
      // the saturated accent, and stops the whole terminal reading as green.
      surface: isLight ? const Color(0xFFFBFCFC) : const Color(0xFF121615),
    );

    final semantic = isLight ? AppSemanticColors.light : AppSemanticColors.dark;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: GoogleFonts.poppins().fontFamily,
    );

    return base.copyWith(
      scaffoldBackgroundColor: isLight
          ? const Color(0xFFEFF3F2)
          : const Color(0xFF0C100F),
      extensions: [semantic],
      textTheme: _textTheme(base.textTheme),
      // InkSparkle loads `shaders/ink_sparkle.frag` at runtime, which is not
      // bundled on every target — on Linux desktop the first ripple throws
      // "Asset not found". InkRipple needs no shader and is visually near
      // identical at this size.
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,

      appBarTheme: AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 0.5,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: scheme.onSurface,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.card,
          side: BorderSide(color: semantic.hairline),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: semantic.hairline,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.md,
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
          borderSide: BorderSide(color: semantic.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
          borderSide: BorderSide(color: semantic.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: Insets.xl),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.pill),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        side: BorderSide(color: semantic.hairline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        labelStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: _fontFamily,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        useIndicator: true,
        labelType: NavigationRailLabelType.none,
        selectedLabelTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: scheme.onSurfaceVariant,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),

      tooltipTheme: const TooltipThemeData(waitDuration: Duration(seconds: 1)),
    );
  }

  /// Tighter tracking on the large sizes; roomier on the small ones. This is
  /// what makes the hierarchy read as deliberate rather than default.
  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      displaySmall: GoogleFonts.poppins(
        textStyle: base.displaySmall,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
        fontSize: 28,
      ),
      headlineMedium: GoogleFonts.poppins(
        textStyle: base.headlineMedium,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        fontSize: 24,
      ),
      headlineSmall: GoogleFonts.poppins(
        textStyle: base.headlineSmall,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        fontSize: 20,
      ),
      titleLarge: GoogleFonts.poppins(
        textStyle: base.titleLarge,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        fontSize: 18,
      ),
      titleMedium: GoogleFonts.poppins(
        textStyle: base.titleMedium,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        fontSize: 15,
      ),
      titleSmall: GoogleFonts.poppins(
        textStyle: base.titleSmall,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      bodyMedium: GoogleFonts.poppins(
        textStyle: base.bodyMedium,
        height: 1.4,
        fontSize: 14,
      ),
      bodySmall: GoogleFonts.poppins(
        textStyle: base.bodySmall,
        height: 1.35,
        fontSize: 12,
      ),
      labelLarge: GoogleFonts.poppins(
        textStyle: base.labelLarge,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      labelMedium: GoogleFonts.poppins(
        textStyle: base.labelMedium,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        fontSize: 11,
      ),
      labelSmall: GoogleFonts.poppins(
        textStyle: base.labelSmall,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        fontSize: 10,
      ),
    );
  }
}
