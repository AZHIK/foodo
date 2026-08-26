import 'package:flutter/material.dart';

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
              : DashboardStyle.cardPadding,
          isMobile: isMobile,
        );
      },
    );
  }

  Widget _build(
    BuildContext context, {
    required bool showBadge,
    required EdgeInsets padding,
    required bool isMobile,
  }) {
    final colors = context.colors;

    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: DashboardStyle.radius,
        border: Border(
          left: BorderSide(
            color: family.accent.withValues(alpha: 0.6),
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: family.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: family.accent),
              ),
              const SizedBox(width: Insets.md),
              // Expanded + right-align rather than Spacer + Flexible: both of
              // those are flex:1, so they split the leftover width evenly and
              // the badge gets squeezed to "↑ 1…" on a two-up phone grid.
              // This way the badge sizes to its content and only the empty
              // space flexes.
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
            style: TextStyle(
              color: colors.onSurfaceVariant,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 11 : 11,
            ),
          ),
          const SizedBox(height: 6),
          // Scales down rather than wrapping, so a long currency value keeps
          // every card in the row the same height.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: family.accent,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                fontSize: isMobile ? 20 : 24,
              ),
            ),
          ),
          if (caption case final text?) ...[
            const SizedBox(height: 4),
            Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: isMobile ? 11 : 12,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      borderRadius: DashboardStyle.radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: card),
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
              '${percent < 10 ? percent.toStringAsFixed(1) : percent.round()}%',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(
                color: colour.withValues(alpha: 0.85),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
