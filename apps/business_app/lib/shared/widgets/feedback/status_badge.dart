import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';

/// Coloured semantic badge / pill used for status indicators anywhere
/// in the app (inventory stock level, sync state, sale status, etc.).
///
/// Colour is driven entirely by [variant] using the semantic colour
/// tokens defined in [AppColors] (never ad hoc RGB values):
///
/// | Variant | Color | Intended use |
/// |---|---|---|
/// | [success]  | `AppColors.synced`     (green)  | In stock, Synced, Completed |
/// | [warning]  | `AppColors.pendingSync`(amber)  | Low stock, Pending sync |
/// | [danger]   | `AppColors.outOfStock` (red)    | Out of stock, Voided, Error |
/// | [info]     | `AppColors.primary`    (terra)  | Default / info |
/// | [suspect]  | `AppColors.timeSuspect`(purple) | Time-suspect records |
/// | [custom]   | Pass explicit `color` / `onColor` | Edge cases |
///
/// [size] switches between full and compact (inline-list-friendly)
/// layouts — compact uses smaller padding and font size so it fits in
/// a single row next to text without pushing line heights.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.variant = StatusBadgeVariant.info,
    this.size = StatusBadgeSize.regular,
    this.icon,
    this.color,
    this.onColor,
  });

  final String label;
  final StatusBadgeVariant variant;
  final StatusBadgeSize size;
  final IconData? icon;

  /// Only read when [variant] == [StatusBadgeVariant.custom].
  final Color? color;
  final Color? onColor;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors();
    final isCompact = size == StatusBadgeSize.compact;
    final hp = isCompact ? AppDimensions.spaceSM : AppDimensions.spaceMD;
    final vp = isCompact ? 1.0 : AppDimensions.spaceXXS + 2;
    final iconSize = isCompact ? 10.0 : 12.0;
    final textStyle = isCompact
        ? AppTextStyles.labelSmall.copyWith(
            color: fg,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          )
        : AppTextStyles.labelSmall.copyWith(
            color: fg,
            fontWeight: FontWeight.w700,
          );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hp, vertical: vp),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: fg),
            SizedBox(width: isCompact ? 2 : AppDimensions.spaceXXS + 2),
          ],
          Flexible(
            child: Text(
              label,
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  (Color bg, Color fg) _colors() {
    (Color, Color) light(Color b, Color f) =>
        (b.withValues(alpha: 0.18), f);
    return switch (variant) {
      StatusBadgeVariant.success => light(AppColors.synced, AppColors.synced),
      StatusBadgeVariant.warning =>
        light(AppColors.pendingSync, AppColors.pendingSync),
      StatusBadgeVariant.danger =>
        light(AppColors.outOfStock, AppColors.outOfStock),
      StatusBadgeVariant.info =>
        light(AppColors.lightPrimary, AppColors.lightPrimary),
      StatusBadgeVariant.suspect =>
        light(AppColors.timeSuspect, AppColors.timeSuspect),
      StatusBadgeVariant.custom => (
          color ?? AppColors.lightPrimary.withValues(alpha: 0.18),
          onColor ?? AppColors.lightPrimary,
        ),
    };
  }
}

enum StatusBadgeVariant {
  success,
  warning,
  danger,
  info,
  suspect,
  custom,
}

enum StatusBadgeSize {
  regular,
  compact,
}
