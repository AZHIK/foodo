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
    this.deepGradient = false,
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

  /// Deep primary-colour gradient on mobile, making the card stand out
  /// as the headline metric (Today's Sales).
  final bool deepGradient;

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
        change: change,
        family: family,
      );
    } else if (isMobile) {
      // Clean and minimal on mobile: flat surface, hairline border,
      // subtle family tint on the icon chip and value, no gradient
      // or shadow. Deep gradient for the headline metric.
      card = _MobileCard(
        padding: padding,
        icon: icon,
        label: label,
        value: value,
        caption: caption,
        change: change,
        showBadge: showBadge,
        family: family,
        deepGradient: deepGradient,
      );
    } else {
      // Tinted wash rather than plain white: a soft gradient from the family
      // tint into the surface, so the row reads warm without shouting.
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
      card = _DesktopCard(
        padding: padding,
        bg: bg,
        icon: icon,
        label: label,
        value: value,
        caption: caption,
        change: change,
        showBadge: showBadge,
        family: family,
        bright: bright,
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

/// Clean, flat card for mobile — no gradient, shadow, or decorative elements.
class _MobileCard extends StatelessWidget {
  const _MobileCard({
    required this.padding,
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.change,
    required this.showBadge,
    required this.family,
    this.deepGradient = false,
  });

  final EdgeInsets padding;
  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  final double? change;
  final bool showBadge;
  final DashboardColor family;
  final bool deepGradient;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: deepGradient
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primary,
                  colors.primary.withValues(alpha: 0.7),
                  colors.primary.withValues(alpha: 0.4),
                ],
              )
            : null,
        color: deepGradient ? null : colors.surfaceContainerLowest,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(
          color: deepGradient
              ? colors.primary.withValues(alpha: 0.3)
              : context.semantic.hairline,
        ),
      ),
      child: Column(
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
                  color: deepGradient
                      ? Colors.white.withValues(alpha: 0.15)
                      : family.tint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: deepGradient ? Colors.white : family.accent,
                ),
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: showBadge
                      ? _TrendBadge(change: change!)
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
          SizedBox(height: Insets.md),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.eyebrow.copyWith(
              color: deepGradient
                  ? Colors.white.withValues(alpha: 0.8)
                  : colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: context.text.headlineSmall?.copyWith(
                color: deepGradient ? Colors.white : family.accent,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (caption case final text?) ...[
            const SizedBox(height: 3),
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
                    color: deepGradient
                        ? Colors.white.withValues(alpha: 0.7)
                        : colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Gradient, shadow, decorative circle card for desktop.
class _DesktopCard extends StatelessWidget {
  const _DesktopCard({
    required this.padding,
    required this.bg,
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.change,
    required this.showBadge,
    required this.family,
    required this.bright,
  });

  final EdgeInsets padding;
  final Gradient bg;
  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  final double? change;
  final bool showBadge;
  final DashboardColor family;
  final bool bright;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
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
                SizedBox(height: Insets.lg),
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.eyebrow.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: context.text.headlineMedium?.copyWith(
                      color: family.onTint,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                if (caption case final text?) ...[
                  const SizedBox(height: 3),
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
}

/// Full-width feature variant (net profit).
class _HeroBody extends StatelessWidget {
  const _HeroBody({
    required this.padding,
    required this.isMobile,
    required this.showBadge,
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.change,
    required this.family,
  });

  final EdgeInsets padding;
  final bool isMobile;
  final bool showBadge;
  final String label;
  final String value;
  final String? caption;
  final IconData icon;
  final double? change;
  final DashboardColor family;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (isMobile) {
      return Container(
        padding: padding.copyWith(
          left: padding.left + 4,
          right: padding.right + 4,
        ),
        decoration: BoxDecoration(
          color: family.tint,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          border: Border.all(color: family.accent.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 23, color: family.accent),
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
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          maxLines: 1,
                          style: context.text.headlineSmall?.copyWith(
                            color: family.accent,
                            fontWeight: FontWeight.w600,
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
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (showBadge)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Insets.sm,
                      vertical: 5,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (change ?? 0) >= 0
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 13,
                          color: context.semantic.success,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          AppStrings.trendPercent((change ?? 0).abs() * 100),
                          style: context.text.labelLarge?.copyWith(
                            color: context.semantic.success,
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

    // Desktop hero: gradient with decorative circles and white text.
    final bright = Theme.of(context).brightness == Brightness.light;
    final base = Theme.of(context).colorScheme.primary;
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
                        style: context.text.headlineMedium?.copyWith(
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Insets.sm,
                    vertical: 5,
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
  const _TrendBadge({required this.change, this.family});

  final double change;
  final DashboardColor? family;

  @override
  Widget build(BuildContext context) {
    final up = change >= 0;
    final semantic = context.semantic;

    // Direction is a fact about the business, not about the card's hue, so the
    // badge uses the app's success/danger colours rather than the family's —
    // a fall in revenue should not be painted reassuring teal.
    final colour = up ? semantic.success : semantic.danger;
    final percent = (change.abs() * 100);

    // No background fill: the percentage reads as plain coloured text with
    // its direction arrow, sitting directly on the card.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.sm, vertical: 3),
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
