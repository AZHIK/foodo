import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';

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
    final button = isLoading
        ? FilledButton.icon(
            onPressed: null,
            icon: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            ),
            label: Text(label),
          )
        : icon != null
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: Text(label),
          )
        : FilledButton(onPressed: onPressed, child: Text(label));

    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
