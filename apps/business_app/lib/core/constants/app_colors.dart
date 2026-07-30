import 'package:flutter/material.dart';

/// Brand colour palette and semantic status colours.
///
/// These hex values are the *exact* terracotta, sage, and gold seeds
/// agreed during the design phase.  The [AppColors] members serve as
/// the single source of truth — the theme's [ColorScheme] is built from
/// the seed colours below, while the semantic constants at the bottom
/// (low-stock, synced, etc.) remain independent of the theme so they
/// never shift when the seed changes.
// ── Brand seed colours ──────────────────────────────────────────
abstract final class AppColors {
  AppColors._();

  // ── Seeds (used by ColorScheme.fromSeed) ──────────────────────
  static const Color seedTerracotta = Color(0xFFC85A53);
  static const Color seedSage = Color(0xFF7A9A6B);
  static const Color seedGold = Color(0xFFD4A843);

  // ── ColorScheme light tokens (exact) ──────────────────────────
  static const Color lightPrimary = Color(0xFFC85A53);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimaryContainer = Color(0xFFFFDAD6);
  static const Color lightOnPrimaryContainer = Color(0xFF410002);
  static const Color lightSecondary = Color(0xFF7A9A6B);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightSecondaryContainer = Color(0xFFD9F5C7);
  static const Color lightOnSecondaryContainer = Color(0xFF0F1F08);
  static const Color lightTertiary = Color(0xFFD4A843);
  static const Color lightOnTertiary = Color(0xFFFFFFFF);
  static const Color lightTertiaryContainer = Color(0xFFFFDEA1);
  static const Color lightOnTertiaryContainer = Color(0xFF221B00);
  static const Color lightBackground = Color(0xFFFCFCFC);
  static const Color lightOnBackground = Color(0xFF1C1B1B);
  static const Color lightSurface = Color(0xFFFCFCFC);
  static const Color lightOnSurface = Color(0xFF1C1B1B);
  static const Color lightError = Color(0xFFBA1A1A);
  static const Color lightOnError = Color(0xFFFFFFFF);
  static const Color lightOutline = Color(0xFF747372);

  // ── ColorScheme dark tokens (exact) ───────────────────────────
  static const Color darkPrimary = Color(0xFFFFB4AB);
  static const Color darkOnPrimary = Color(0xFF690005);
  static const Color darkPrimaryContainer = Color(0xFF93000A);
  static const Color darkOnPrimaryContainer = Color(0xFFFFDAD6);
  static const Color darkSecondary = Color(0xFFB8DAAB);
  static const Color darkOnSecondary = Color(0xFF24351B);
  static const Color darkSecondaryContainer = Color(0xFF3B4C31);
  static const Color darkOnSecondaryContainer = Color(0xFFD9F5C7);
  static const Color darkTertiary = Color(0xFFF0C460);
  static const Color darkOnTertiary = Color(0xFF3A2F00);
  static const Color darkTertiaryContainer = Color(0xFF544400);
  static const Color darkOnTertiaryContainer = Color(0xFFFFDEA1);
  static const Color darkBackground = Color(0xFF1C1B1B);
  static const Color darkOnBackground = Color(0xFFE4E2E2);
  static const Color darkSurface = Color(0xFF1C1B1B);
  static const Color darkOnSurface = Color(0xFFE4E2E2);
  static const Color darkError = Color(0xFFFFB4AB);
  static const Color darkOnError = Color(0xFF690005);
  static const Color darkOutline = Color(0xFF8D8C8C);

  // ── Semantic status colours (independent of theme) ────────────
  static const Color lowStock = Color(0xFFF59E0B);
  static const Color outOfStock = Color(0xFFDC2626);
  static const Color synced = Color(0xFF22C55E);
  static const Color pendingSync = Color(0xFFF59E0B);
  static const Color timeSuspect = Color(0xFF8B5CF6);
}
