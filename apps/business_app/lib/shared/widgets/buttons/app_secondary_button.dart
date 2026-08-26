import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';

/// Secondary outlined button with the same sizing contract as
/// [AppPrimaryButton].
///
/// Re-uses the same visual tokens (corner radius, horizontal padding)
/// so primary/secondary buttons placed next to each other share
/// identical height and hit-target size.
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = true,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  /// When `true`, colours the button with [ColorScheme.error].
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fgColor = isDestructive
        ? colorScheme.error
        : colorScheme.onSurface.withValues(alpha: 0.82);
    final borderColor = isDestructive
        ? colorScheme.error
        : colorScheme.outlineVariant;

    Widget button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: fgColor,
        side: BorderSide(
          color: borderColor.withValues(alpha: 0.95),
          width: 0.8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        ),
      ),
      child: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: AppDimensions.spaceSM),
                Text(label),
              ],
            )
          : Text(label),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
