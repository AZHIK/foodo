import 'package:flutter/material.dart';

/// One colour family: a soft fill to sit behind content, and a saturated shade
/// of the same hue for the icon and text on top of it.
///
/// The pair is defined together, per brightness, rather than derived at the
/// call site — a tint computed as "accent at 12% alpha" looks fine in light
/// mode and turns to mud on a near-black surface.
@immutable
class DashboardColor {
  const DashboardColor({
    required this.tint,
    required this.accent,
    required this.onTint,
  });

  /// Card background. Deliberately pale, never a solid saturated block.
  final Color tint;

  /// Icons, trend badges, chart strokes.
  final Color accent;

  /// Body text over [tint]. Darker than [accent] in light mode so a long label
  /// stays comfortable to read rather than vibrating against the fill.
  final Color onTint;
}

/// The dashboard's colour assignments.
///
/// Every hue used on the Dashboard is named here once. Changing what "orders"
/// looks like is a one-line edit that moves the KPI card, its trend badge and
/// anything else keyed to the same family.
@immutable
class DashboardPalette {
  const DashboardPalette({
    required this.revenue,
    required this.orders,
    required this.value,
    required this.staff,
    required this.categories,
    required this.gridLine,
  });

  /// Money taken. Teal, the app's own accent — revenue is the number the
  /// screen is really about, so it keeps the brand colour.
  final DashboardColor revenue;

  /// How many tickets. Blue.
  final DashboardColor orders;

  /// Average order value. Coral.
  final DashboardColor value;

  /// People on shift. Purple.
  final DashboardColor staff;

  /// Donut slices and rank badges, in a fixed order so a category keeps its
  /// colour between the chart and the list beside it.
  final List<DashboardColor> categories;

  /// Chart gridlines and axis rules.
  final Color gridLine;

  static const _light = DashboardPalette(
    revenue: DashboardColor(
      tint: Color(0xFFDDF1EC),
      accent: Color(0xFF0A6B57),
      onTint: Color(0xFF06463A),
    ),
    orders: DashboardColor(
      tint: Color(0xFFE0E8FE),
      accent: Color(0xFF1B4FD8),
      onTint: Color(0xFF14368F),
    ),
    value: DashboardColor(
      tint: Color(0xFFFDE8DC),
      accent: Color(0xFFC2410C),
      onTint: Color(0xFF8A2E08),
    ),
    staff: DashboardColor(
      tint: Color(0xFFEBE3FD),
      accent: Color(0xFF6D28D9),
      onTint: Color(0xFF4C1D95),
    ),
    categories: [
      DashboardColor(
        tint: Color(0xFFDDF1EC),
        accent: Color(0xFF0A6B57),
        onTint: Color(0xFF06463A),
      ),
      DashboardColor(
        tint: Color(0xFFE0E8FE),
        accent: Color(0xFF1B4FD8),
        onTint: Color(0xFF14368F),
      ),
      DashboardColor(
        tint: Color(0xFFFDE8DC),
        accent: Color(0xFFE0642A),
        onTint: Color(0xFF8A2E08),
      ),
      DashboardColor(
        tint: Color(0xFFEBE3FD),
        accent: Color(0xFF7C3AED),
        onTint: Color(0xFF4C1D95),
      ),
      DashboardColor(
        tint: Color(0xFFFBEED2),
        accent: Color(0xFFB4790A),
        onTint: Color(0xFF7A5106),
      ),
      DashboardColor(
        tint: Color(0xFFFBE0EC),
        accent: Color(0xFFB0246A),
        onTint: Color(0xFF7C1849),
      ),
    ],
    gridLine: Color(0x14000000),
  );

  static const _dark = DashboardPalette(
    revenue: DashboardColor(
      tint: Color(0xFF0E2F28),
      accent: Color(0xFF5CD2B0),
      onTint: Color(0xFFB6EEDF),
    ),
    orders: DashboardColor(
      tint: Color(0xFF152147),
      accent: Color(0xFF96B6FF),
      onTint: Color(0xFFCBDAFF),
    ),
    value: DashboardColor(
      tint: Color(0xFF3A1F14),
      accent: Color(0xFFFFA878),
      onTint: Color(0xFFFFD2BA),
    ),
    staff: DashboardColor(
      tint: Color(0xFF281C47),
      accent: Color(0xFFC3A5FF),
      onTint: Color(0xFFE0D1FF),
    ),
    categories: [
      DashboardColor(
        tint: Color(0xFF0E2F28),
        accent: Color(0xFF5CD2B0),
        onTint: Color(0xFFB6EEDF),
      ),
      DashboardColor(
        tint: Color(0xFF152147),
        accent: Color(0xFF96B6FF),
        onTint: Color(0xFFCBDAFF),
      ),
      DashboardColor(
        tint: Color(0xFF3A1F14),
        accent: Color(0xFFFF9A63),
        onTint: Color(0xFFFFD2BA),
      ),
      DashboardColor(
        tint: Color(0xFF281C47),
        accent: Color(0xFFC3A5FF),
        onTint: Color(0xFFE0D1FF),
      ),
      DashboardColor(
        tint: Color(0xFF33280D),
        accent: Color(0xFFE8B84B),
        onTint: Color(0xFFF7DFA6),
      ),
      DashboardColor(
        tint: Color(0xFF3A1428),
        accent: Color(0xFFF48FBE),
        onTint: Color(0xFFFAC6DD),
      ),
    ],
    gridLine: Color(0x1FFFFFFF),
  );

  static DashboardPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  /// Wraps around, so a seventh category borrows the first colour rather than
  /// throwing.
  DashboardColor category(int index) =>
      categories[index % categories.length];
}

/// Card geometry for the dashboard.
///
/// Softer than the utilitarian tables elsewhere: rounder corners, no hairline
/// border, and a shadow doing the work a border does on the other screens.
abstract final class DashboardStyle {
  static const BorderRadius radius = BorderRadius.all(Radius.circular(16));
  static const EdgeInsets cardPadding = EdgeInsets.all(20);
  static const EdgeInsets cardPaddingMobile = EdgeInsets.all(14);

  /// Chart heights by form factor. Charts shorten on a phone so the cards
  /// under them are not pushed entirely below the fold.
  static const double chartHeightDesktop = 260;
  static const double chartHeightMobile = 180;

  static List<BoxShadow> shadow(Brightness brightness) => brightness ==
          Brightness.dark
      // A dark surface cannot show a soft grey shadow, so depth comes from a
      // deeper black with a wider spread instead.
      ? const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ];
}
