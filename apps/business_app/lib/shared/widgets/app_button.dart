import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_durations.dart';
import '../../core/constants/app_text_styles.dart';

/// Branded primary button with loading-state support.
///
/// Wraps [FilledButton] with a consistent height, radius from
/// [AppDimensions.radiusMD], and an animated [CircularProgressIndicator]
/// when [isLoading] is true.
///
/// Usage:
/// ```dart
/// AppPrimaryButton(
///   label: 'Continue',
///   onPressed: _submit,
///   isLoading: _loading,
/// )
/// ```
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  /// If `true` the button stretches to fill available width.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    Widget button;

    if (icon != null && !isLoading) {
      button = FilledButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
      );
    } else {
      button = FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: AnimatedSwitcher(
          duration: AppDurations.fast,
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(key: const ValueKey('label'), label),
        ),
      );
    }

    return expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

/// Secondary outlined button with the same sizing contract.
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
    final fgColor = isDestructive ? colorScheme.error : null;
    final borderColor = isDestructive ? colorScheme.error : colorScheme.outline;

    Widget button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: fgColor,
        side: BorderSide(color: borderColor),
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

    return expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

/// Flat text link button styled consistently with [AppTextStyles.labelLarge].
class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fgColor = isDestructive ? colorScheme.error : colorScheme.primary;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: fgColor),
      child: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16),
                const SizedBox(width: AppDimensions.spaceXS),
                Text(label),
              ],
            )
          : Text(label),
    );
  }
}
