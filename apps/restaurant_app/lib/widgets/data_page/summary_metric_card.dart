import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';

/// Direction of a trend line, which decides its colour and arrow.
enum TrendDirection {
  up,
  down,
  flat;

  IconData get icon => switch (this) {
    TrendDirection.up => Icons.trending_up_rounded,
    TrendDirection.down => Icons.trending_down_rounded,
    TrendDirection.flat => Icons.trending_flat_rounded,
  };
}

/// One headline number in a data page's summary row.
///
/// [trend] is free text ("+12% vs last week", "4 need reordering") so a page
/// can put whatever context matters under the value.
class SummaryMetricCard extends StatelessWidget {
  const SummaryMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.trend,
    this.trendDirection,
    this.trendColor,
    this.icon,
    this.accent,
  });

  final String label;
  final String value;

  /// Small context line under the value.
  final String? trend;

  /// Supplies a default arrow and colour for [trend].
  final TrendDirection? trendDirection;

  /// Overrides the colour [trendDirection] would pick.
  final Color? trendColor;

  final IconData? icon;

  /// Tints the icon chip. Defaults to the scheme's primary.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final semantic = context.semantic;
    final tint = accent ?? colors.primary;

    final trendTone =
        trendColor ??
        switch (trendDirection) {
          TrendDirection.up => semantic.success,
          TrendDirection.down => semantic.danger,
          TrendDirection.flat || null => colors.onSurfaceVariant,
        };

    return Container(
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: Radii.card,
        border: Border.all(color: semantic.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                  child: Icon(icon, size: 17, color: tint),
                ),
                const SizedBox(width: Insets.md - 2),
              ],
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    letterSpacing: 0.9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          // Scales down rather than wrapping, so a long currency value keeps
          // the three cards the same height.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: context.text.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (trend != null) ...[
            const SizedBox(height: Insets.xs),
            Row(
              children: [
                if (trendDirection != null) ...[
                  Icon(trendDirection!.icon, size: 14, color: trendTone),
                  const SizedBox(width: Insets.xs),
                ],
                Expanded(
                  child: Text(
                    trend!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(color: trendTone),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
