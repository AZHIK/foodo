import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Material 3 typography scale constants using Inter font.
///
/// In Stage 1 these are plain [TextStyle] constants mirroring the M3
/// type scale with Inter as the base font family.  A future iteration
/// may switch to [TextTheme] extension or generated l10n typography.
abstract final class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _base => GoogleFonts.inter();

  // ── Display ───────────────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
  static const TextStyle displayMedium = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
  static const TextStyle displaySmall = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  // ── Headline ──────────────────────────────────────────────────
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  // ── Title ─────────────────────────────────────────────────────
  static const TextStyle titleLarge = TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  // ── Body ──────────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  // ── Label ─────────────────────────────────────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  /// Apply the Inter font family to a [TextStyle].
  static TextStyle withInter(TextStyle style) {
    return style.copyWith(fontFamily: _base.fontFamily);
  }
}
