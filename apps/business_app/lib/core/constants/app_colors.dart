import 'package:flutter/material.dart';

/// Brand colour palette and semantic status colours.
///
/// These hex values are the *exact* terracotta, sage, and gold seeds
/// agreed during the design phase.  The [AppColors] members serve as
/// the single source of truth — the theme's [ColorScheme] is built from
/// the seed colours below, while the semantic constants at the bottom
/// (low-stock, synced, etc.) remain independent of the theme so they
/// never shift when the seed changes.
//
// VISUAL DIRECTION — white-dominant / accent-only:
//   - Surfaces are pure/near-white; brand colours appear only as small
//     deliberate accents (CTA buttons, nav indicators, status badges,
//     focused input borders).
//   - Text is near-black neutral; colour in text is reserved for links
//     and status messaging.
//   - Borders/dividers are hairline light-neutral gray, used sparingly.
// ── Brand seed colours ──────────────────────────────────────────
abstract final class AppColors {
  AppColors._();

  // ── Seeds (used by ColorScheme.fromSeed) ──────────────────────
  static const Color seedTerracotta = Color(0xFFC85A53);
  static const Color seedSage = Color(0xFF7A9A6B);
  static const Color seedGold = Color(0xFFD4A843);

  // ── ColorScheme light tokens (white-dominant) ─────────────────
  static const Color lightPrimary = Color(0xFFC85A53);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimaryContainer = Color(0xFFFFF3F1);
  static const Color lightOnPrimaryContainer = Color(0xFF7A2D28);
  static const Color lightSecondary = Color(0xFF7A9A6B);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightSecondaryContainer = Color(0xFFF6F8F5);
  static const Color lightOnSecondaryContainer = Color(0xFF34482C);
  static const Color lightTertiary = Color(0xFFD4A843);
  static const Color lightOnTertiary = Color(0xFFFFFFFF);
  static const Color lightTertiaryContainer = Color(0xFFFAF7EF);
  static const Color lightOnTertiaryContainer = Color(0xFF5D4810);
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightOnBackground = Color(0xFF18181B);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOnSurface = Color(0xFF18181B);
  static const Color lightError = Color(0xFFBA1A1A);
  static const Color lightOnError = Color(0xFFFFFFFF);
  static const Color lightOutline = Color(0xFFE5E7EB);
  static const Color lightOutlineVariant = Color(0xFFF0F0F0);
  static const Color lightSurfaceContainerHighest = Color(0xFFF4F4F5);
  static const Color lightSurfaceContainerLow = Color(0xFFFAFAFA);
  static const Color lightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color lightInverseSurface = Color(0xFF27272A);
  static const Color lightOnInverseSurface = Color(0xFFFAFAFA);
  static const Color lightShadow = Color(0xFF111827);

  // ── ColorScheme dark tokens (dark-neutral surfaces) ───────────
  static const Color darkPrimary = Color(0xFFFFB4AB);
  static const Color darkOnPrimary = Color(0xFF690005);
  static const Color darkPrimaryContainer = Color(0xFF3A2422);
  static const Color darkOnPrimaryContainer = Color(0xFFFFDAD6);
  static const Color darkSecondary = Color(0xFFB8DAAB);
  static const Color darkOnSecondary = Color(0xFF24351B);
  static const Color darkSecondaryContainer = Color(0xFF273025);
  static const Color darkOnSecondaryContainer = Color(0xFFD9F5C7);
  static const Color darkTertiary = Color(0xFFF0C460);
  static const Color darkOnTertiary = Color(0xFF3A2F00);
  static const Color darkTertiaryContainer = Color(0xFF332D20);
  static const Color darkOnTertiaryContainer = Color(0xFFFFDEA1);
  static const Color darkBackground = Color(0xFF111111);
  static const Color darkOnBackground = Color(0xFFEDEDED);
  static const Color darkSurface = Color(0xFF181818);
  static const Color darkOnSurface = Color(0xFFEDEDED);
  static const Color darkError = Color(0xFFFFB4AB);
  static const Color darkOnError = Color(0xFF690005);
  static const Color darkOutline = Color(0xFF3F3F46);
  static const Color darkOutlineVariant = Color(0xFF2A2A2D);
  static const Color darkSurfaceContainerHighest = Color(0xFF242424);
  static const Color darkSurfaceContainerLow = Color(0xFF1D1D1D);
  static const Color darkSurfaceContainerLowest = Color(0xFF111111);
  static const Color darkInverseSurface = Color(0xFFEDEDED);
  static const Color darkOnInverseSurface = Color(0xFF181818);
  static const Color darkShadow = Color(0xFF000000);

  // ── Semantic status colours (independent of theme) ────────────
  static const Color lowStock = Color(0xFFF59E0B);
  static const Color outOfStock = Color(0xFFDC2626);
  static const Color synced = Color(0xFF22C55E);
  static const Color pendingSync = Color(0xFFF59E0B);
  static const Color timeSuspect = Color(0xFF8B5CF6);
}
