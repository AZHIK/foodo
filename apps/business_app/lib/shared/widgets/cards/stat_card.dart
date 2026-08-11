import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import 'app_card.dart';

/// Dashboard-style metric card showing a [label], [value], optional
/// [trend] delta, and optional leading [icon].
///
/// Use this for KPI tiles on the Dashboard and any summary row where a
/// single number needs visual prominence.
///
/// Usage:
/// ```dart
/// StatCard(
///   label: 'Today\'s Sales',
///   value: 'TZS 485,200',
///   trend: '+12.4%',
///   trendDirection: TrendDirection.up,
///   icon: Icons.point_of_sale_outlined,
/// )
/// ```
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.trend,
    this.trendDirection,
    this.icon,
    this.onTap,
  });

  final String label;
  final String value;

  /// e.g. `+12.4%` or `-3.1%` — display only, no math here.
  final String? trend;
  final TrendDirection? trendDirection;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final trendColor = switch (trendDirection) {
      TrendDirection.up => colorScheme.secondary,
      TrendDirection.down => colorScheme.error,
      _ => colorScheme.onSurface.withValues(alpha: 0.6),
    };
    final trendIcon = switch (trendDirection) {
      TrendDirection.up => Icons.trending_up_rounded,
      TrendDirection.down => Icons.trending_down_rounded,
      _ => Icons.trending_flat_rounded,
    };

    return AppCard.elevated(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceSM),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  ),
                  child: Icon(icon, size: 18, color: colorScheme.primary),
                ),
              if (icon != null) const SizedBox(width: AppDimensions.spaceSM),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (trend != null) ...[
            const SizedBox(height: AppDimensions.spaceXS),
            Row(
              children: [
                Icon(trendIcon, size: 14, color: trendColor),
                const SizedBox(width: AppDimensions.spaceXXS),
                Text(
                  trend!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: trendColor,
                    fontWeight: FontWeight.w600,
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

/// Whether a trend is increasing, decreasing, or flat.
enum TrendDirection { up, down, flat }
