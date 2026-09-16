import 'package:flutter/material.dart';

import '../../constants/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../theme/dashboard_colors.dart';

/// A KPI tile in one of the dashboard's colour families.
///
/// The richer counterpart to [SummaryMetricCard], which stays neutral for the
/// dense tables on Inventory, Sales and Staff. This one exists because the
/// Dashboard is the first thing staff see and is allowed to be warmer: a
/// tinted fill, a soft shadow instead of a hairline border, and a trend badge
/// in the corner.
///
/// Both are kept — a page full of coloured cards would make the utilitarian
/// screens harder to scan, which is exactly what those screens are for.
class ColorfulMetricCard extends StatelessWidget {
  const ColorfulMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.family,
    this.change,
    this.caption,
    this.onTap,
    this.hero = false,
  });

  final String label;

  /// Pre-formatted — the card does no currency or locale work of its own.
  final String value;

  final IconData icon;

  /// Which colour family this card belongs to.
  final DashboardColor family;

  /// Period-on-period change as a fraction. Null hides the badge entirely,
  /// which is the honest rendering when there is nothing to compare against.
  final double? change;

  /// Small line under the value, for context a percentage cannot carry
  /// ("3 of 9 on shift").
  final String? caption;

  final VoidCallback? onTap;

  /// Full-width feature variant (net profit on mobile): deep tinted gradient
  /// with light-on-dark text so the hero reads as one deliberate banner
  /// rather than a fifth identical tile.
  final bool hero;

  /// Below this the card cannot hold an icon and a badge on one line, so the
  /// badge is dropped rather than crushed to a sliver. The caption underneath
  /// still carries the comparison in words.
  static const double _badgeMin = 150;

  /// And below this even the standard padding is too generous.
  static const double _tightPadding = 190;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = context.isMobile;
        return _build(
          context,
          showBadge: change != null && constraints.maxWidth >= _badgeMin,
          padding: constraints.maxWidth < _tightPadding
              ? const EdgeInsets.all(12)
              : isMobile
                  ? DashboardStyle.cardPaddingMobile
                  : DashboardStyle.cardPadding,
          caption: caption,
          isMobile: isMobile,
        );
      },
    );
  }

  Widget _build(
    BuildContext context, {
    required bool showBadge,
    required EdgeInsets padding,
    required String? caption,
    required bool isMobile,
  }) {
    final colors = context.colors;
    final bright = Theme.of(context).brightness == Brightness.light;

    Widget card;
    if (hero) {
      card = _HeroBody(
        padding: padding,
        isMobile: isMobile,
        showBadge: showBadge,
        label: label,
        value: value,
        caption: caption,
        icon: icon,
        family: family,
        change: change,
      );
    } else {
      // Tinted wash rather than plain white: a soft gradient from the family
      // tint into the surface, so the row reads warm without shouting.
      // The old 4px left-border treatment is gone — modern KPI tiles carry
      // colour in the icon chip + value accent-free hierarchy instead.
      final bg = bright
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [family.tint, colors.surfaceContainerLowest],
            )
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                family.tint,
                Color.lerp(family.tint, Colors.black, 0.35) ?? family.tint,
              ],
            );
      final _ = colors;
      card = Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: bg,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          border: Border.all(
            color: family.accent.withValues(alpha: bright ? 0.16 : 0.32),
          ),
          boxShadow: DashboardStyle.shadow(Theme.of(context).brightness),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          child: Stack(
            children: [
              // Soft decorative wash top-right — pure decoration, kept
              // behind content so it never affects legibility.
              Positioned(
                right: -28,
                top: -28,
                child: Container(
                  height: 92,
                  width: 92,
                  decoration: BoxDecoration(
                    color: family.accent.withValues(alpha: bright ? 0.10 : 0.18),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLowest.withValues(
                            alpha: bright ? 0.9 : 0.55,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: family.accent.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Icon(icon, size: 20, color: family.accent),
                      ),
                      const SizedBox(width: Insets.sm),
                      // Expanded + right-align rather than Spacer + Flexible:
                      // both of those are flex:1, so they split the leftover
                      // width evenly and the badge gets squeezed to "↑ 1…" on
                      // a two-up phone grid. This way the badge sizes to its
                      // content and only the empty space flexes.
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: showBadge
                              ? _TrendBadge(change: change!, family: family)
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? Insets.md : Insets.lg),
                  Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.eyebrow.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Scales down rather than wrapping, so a long currency value
                  // keeps every card in the row the same height.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: (isMobile
                              ? context.text.headlineSmall
                              : context.text.headlineMedium)
                          ?.copyWith(
                        // Deep tinted ink rather than near-black onSurface:
                        // full black vibrates against the pastel fill and
                        // shouts over the icon chip. onTint is drawn from the
                        // same hue, so the number sits inside the card instead
                        // of on top of it. Semibold is plenty at this size.
                        color: family.onTint,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  if (caption case final text?) ...[
                    const SizedBox(height: 3),
                    // Same shrink-to-fit as the value above: the full caption
                    // ("vs TSh 96.2k yesterday") always stays on one line and
                    // scales down only as much as a narrow card needs, so the
                    // leading "vs" is never chopped and every card in the row
                    // keeps the same height. The 4px left nudge keeps the
                    // first glyph clear of the card's hairline edge.
                    Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.caption.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: card),
    );
  }
}

/// Deep-tinted hero treatment for the full-width profit card.
class _HeroBody extends StatelessWidget {
  const _HeroBody({
    required this.padding,
    required this.isMobile,
    required this.showBadge,
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.family,
    required this.change,
  });

  final EdgeInsets padding;
  final bool isMobile;
  final bool showBadge;
  final String label;
  final String value;
  final String? caption;
  final IconData icon;
  final DashboardColor family;
  final double? change;

  @override
  Widget build(BuildContext context) {
    final bright = Theme.of(context).brightness == Brightness.light;
    final base = family.accent;
    final start = bright
        ? Color.lerp(base, Colors.black, 0.12) ?? base
        : Color.lerp(base, Colors.white, 0.08) ?? base;
    final end = bright
        ? Color.lerp(base, Colors.black, 0.42) ?? base
        : Color.lerp(base, Colors.black, 0.45) ?? base;

    return Container(
      padding: padding.copyWith(
        left: padding.left + 4,
        right: padding.right + 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [start, end],
        ),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: DashboardStyle.shadow(Theme.of(context).brightness),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -34,
            child: Container(
              height: 130,
              width: 130,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 44,
            bottom: -52,
            child: Container(
              height: 110,
              width: 110,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 23, color: Colors.white),
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.eyebrow.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        maxLines: 1,
                        style: (isMobile
                                ? context.text.headlineSmall
                                : context.text.headlineMedium)
                            ?.copyWith(
                          color: Colors.white,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    if (caption case final text?)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (showBadge)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Insets.sm,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        (change ?? 0) >= 0
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        AppStrings.trendPercent((change ?? 0).abs() * 100),
                        style: context.text.labelLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The "+12.4%" pill in a card's top-right corner.
class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.change, required this.family});

  final double change;
  final DashboardColor family;

  @override
  Widget build(BuildContext context) {
    final up = change >= 0;
    final semantic = context.semantic;

    // Direction is a fact about the business, not about the card's hue, so the
    // badge uses the app's success/danger colours rather than the family's —
    // a fall in revenue should not be painted reassuring teal.
    final colour = up ? semantic.success : semantic.danger;
    final percent = (change.abs() * 100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.sm, vertical: 3),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 12,
            color: colour.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              // One decimal below 10%, none above — "+3.4%" is useful,
              // "+128.0%" is just wider.
              AppStrings.trendPercent(percent),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelLarge?.copyWith(
                color: colour,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
