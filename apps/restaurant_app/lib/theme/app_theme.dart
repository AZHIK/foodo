import 'package:flutter/material.dart';

import '../constants/app_durations.dart';
import 'breakpoints.dart';
import 'role_badge_colors.dart';

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

  static const _fontFamily = 'Inter';

  /// The only weights the app uses. Inter is a variable font so any value
  /// interpolates, but restricting call sites to these four stops the
  /// w500/w600/w700/w800 soup that made every screen look like a different
  /// app — especially on phones where heavy weights blotch at small sizes.
  static const _regular = FontWeight.w400;
  static const _medium = FontWeight.w500;
  static const _semiBold = FontWeight.w600;
  static const _bold = FontWeight.w700;

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
    final roleBadges = isLight ? RoleBadgeColors.light : RoleBadgeColors.dark;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      // Inter is bundled locally (assets/fonts/Inter.ttf, registered in
      // pubspec) so text renders identically offline — no GoogleFonts network
      // fetch, no FOUT swapping Poppins in late on a slow counter terminal.
      fontFamily: _fontFamily,
    );

    return base.copyWith(
      scaffoldBackgroundColor: isLight
          ? const Color(0xFFEFF3F2)
          : const Color(0xFF0C100F),
      extensions: [semantic, roleBadges],
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
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 19,
          fontWeight: _bold,
          letterSpacing: -0.25,
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
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
            fontWeight: _semiBold,
            letterSpacing: 0,
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
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
            fontWeight: _semiBold,
            letterSpacing: 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
            fontWeight: _semiBold,
            letterSpacing: 0,
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
          fontWeight: _semiBold,
          letterSpacing: 0,
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
                ? _semiBold
                : _medium,
            letterSpacing: 0,
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
          fontWeight: _semiBold,
          letterSpacing: 0,
          color: scheme.onSurface,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 13,
          fontWeight: _medium,
          letterSpacing: 0,
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

      tooltipTheme: const TooltipThemeData(waitDuration: AppDurations.tooltipWait),
    );
  }

  /// One family (Inter), whole-point sizes, four weights, two text colours.
  ///
  /// Why Inter and nothing else: it is drawn for dense UI at 11–14px where
  /// Poppins (a geometric display face) turns blobby on phones, its tabular
  /// figures keep every price/quantity column aligned, and it ships bundled
  /// so the POS renders identically offline. Every M3 slot is set explicitly
  /// so no surface silently falls back to Roboto and re-introduces a second
  /// voice. w800 is banned — Inter ExtraBold at mobile sizes reads as noise.
  static TextTheme _textTheme(TextTheme base) {
    TextStyle style({
      TextStyle? from,
      required double size,
      required FontWeight weight,
      required double height,
      double letterSpacing = 0,
      bool tabular = false,
    }) {
      return (from ?? const TextStyle()).copyWith(
        fontFamily: _fontFamily,
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
      );
    }

    final display = style(
      from: base.displaySmall,
      size: 26,
      weight: _bold,
      height: 1.2,
      letterSpacing: -0.25,
    );
    final headline = style(
      from: base.headlineMedium,
      size: 22,
      weight: _bold,
      height: 1.25,
      letterSpacing: -0.25,
    );
    final headlineSm = style(
      from: base.headlineSmall,
      size: 19,
      weight: _bold,
      height: 1.3,
      letterSpacing: -0.25,
    );
    final titleLg = style(
      from: base.titleLarge,
      size: 17,
      weight: _semiBold,
      height: 1.35,
      letterSpacing: -0.1,
    );
    final titleMd = style(
      from: base.titleMedium,
      size: 15,
      weight: _semiBold,
      height: 1.4,
      letterSpacing: -0.1,
    );
    final titleSm = style(
      from: base.titleSmall,
      size: 14,
      weight: _semiBold,
      height: 1.4,
    );
    final bodyLg = style(
      from: base.bodyLarge,
      size: 15,
      weight: _regular,
      height: 1.5,
    );
    final bodyMd = style(
      from: base.bodyMedium,
      size: 14,
      weight: _regular,
      height: 1.5,
    );
    final bodySm = style(
      from: base.bodySmall,
      size: 13,
      weight: _regular,
      height: 1.45,
    );
    final labelLg = style(
      from: base.labelLarge,
      size: 13,
      weight: _semiBold,
      height: 1.4,
    );
    // The single "eyebrow" voice: section headers, KPI labels, table heads.
    // 12px floor (never 10/10.5 — unreadable on phones), one tracking value.
    final eyebrow = style(
      from: base.labelMedium,
      size: 12,
      weight: _semiBold,
      height: 1.35,
      letterSpacing: 0.6,
    );
    final caption = style(
      from: base.labelSmall,
      size: 12,
      weight: _medium,
      height: 1.35,
    );

    return base.copyWith(
      displayLarge: display.copyWith(fontSize: 30),
      displayMedium: display.copyWith(fontSize: 28),
      displaySmall: display,
      headlineLarge: headline.copyWith(fontSize: 24),
      headlineMedium: headline,
      headlineSmall: headlineSm,
      titleLarge: titleLg,
      titleMedium: titleMd,
      titleSmall: titleSm,
      bodyLarge: bodyLg,
      bodyMedium: bodyMd,
      bodySmall: bodySm,
      labelLarge: labelLg,
      labelMedium: eyebrow,
      labelSmall: caption,
    );
  }
}

/// Shared semantic text helpers so call sites stop inventing one-off
/// sizes/weights/colours. All resolve from the theme — Inter throughout.
extension AppTypography on TextTheme {
  /// 12px uppercase section/KPI/table header. Caller uppercases the string;
  /// tracking lives here so every eyebrow matches.
  TextStyle get eyebrow => labelMedium!;

  /// Secondary 12px line under a value ("3 of 9 on shift").
  TextStyle get caption => labelSmall!;

  /// Prices and totals. Tabular figures keep columns aligned as values change.
  /// Pick the size that matches the surrounding body text.
  TextStyle get moneyLarge => titleLarge!.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  TextStyle get moneyMedium => bodyMedium!.copyWith(
    fontWeight: FontWeight.w600,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  TextStyle get moneySmall => bodySmall!.copyWith(
    fontWeight: FontWeight.w600,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
