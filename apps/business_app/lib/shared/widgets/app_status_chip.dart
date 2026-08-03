import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

/// Pill-shaped status badge.
///
/// [variant] drives colour automatically from the [ColorScheme]:
/// - [AppStatusChipVariant.active] → secondary container (green / sage)
/// - [AppStatusChipVariant.locked] → error container (red)
/// - [AppStatusChipVariant.synced] → tertiary container (gold)
/// - [AppStatusChipVariant.custom] → uses [color] / [onColor]
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    super.key,
    required this.label,
    this.variant = AppStatusChipVariant.active,
    this.color,
    this.onColor,
    this.icon,
  });

  final String label;
  final AppStatusChipVariant variant;
  final Color? color;
  final Color? onColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (bg, fg) = _colors(colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMD,
        vertical: AppDimensions.spaceXXS + 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: AppDimensions.spaceXXS + 2),
          ],
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  (Color bg, Color fg) _colors(ColorScheme cs) {
    return switch (variant) {
      AppStatusChipVariant.active => (cs.secondaryContainer, cs.onSecondaryContainer),
      AppStatusChipVariant.locked => (cs.errorContainer, cs.onErrorContainer),
      AppStatusChipVariant.synced => (cs.tertiaryContainer, cs.onTertiaryContainer),
      AppStatusChipVariant.custom => (
          color ?? cs.primaryContainer,
          onColor ?? cs.onPrimaryContainer,
        ),
    };
  }
}

enum AppStatusChipVariant { active, locked, synced, custom }
