/// Spacing scale, corner radii, and adaptive breakpoints.
///
/// All values are in logical pixels.  These constants feed directly
/// into [flutter_adaptive_scaffold] breakpoints and should be used
/// consistently across all widgets to maintain visual rhythm.
abstract final class AppDimensions {
  AppDimensions._();

  // ── Spacing scale ─────────────────────────────────────────────
  static const double spaceXXS = 4;
  static const double spaceXS = 8;
  static const double spaceSM = 12;
  static const double spaceMD = 20;
  static const double spaceLG = 28;
  static const double spaceXL = 40;
  static const double spaceXXL = 56;
  static const double spaceXXXL = 80;

  // ── Corner radii ──────────────────────────────────────────────
  static const double radiusXS = 6;
  static const double radiusSM = 10;
  static const double radiusMD = 16;
  static const double radiusLG = 24;
  static const double radiusXL = 32;
  static const double radiusFull = 999;

  // ── Adaptive breakpoints (matching flutter_adaptive_scaffold) ─
  static const double breakpointMobile = 0;
  static const double breakpointTablet = 600;
  static const double breakpointDesktop = 900;

  // ── AppBar / NavRail / BottomNav sizing ───────────────────────
  static const double appBarHeight = 56;
  static const double navRailWidth = 72;
  static const double bottomNavHeight = 64;
}
