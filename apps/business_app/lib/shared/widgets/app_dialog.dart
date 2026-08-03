import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

/// Standardised confirm / alert dialog.
///
/// Usage:
/// ```dart
/// final confirmed = await AppDialog.showConfirm(
///   context,
///   title: 'End Shift',
///   message: 'Are you sure?',
///   confirmLabel: 'End shift',
///   isDestructive: true,
/// );
/// ```
abstract final class AppDialog {
  AppDialog._();

  /// Shows a confirm / cancel dialog.  Returns `true` if confirmed.
  static Future<bool> showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _AppDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  /// Shows a non-dismissible info/alert dialog.
  static Future<void> showAlert(
    BuildContext context, {
    required String title,
    required String message,
    String closeLabel = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => _AppDialog(
        title: title,
        message: message,
        confirmLabel: closeLabel,
        cancelLabel: null,
        isDestructive: false,
      ),
    );
  }
}

class _AppDialog extends StatelessWidget {
  const _AppDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDestructive,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String? cancelLabel;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      ),
      title: Text(title, style: AppTextStyles.headlineSmall),
      content: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      actions: [
        if (cancelLabel != null)
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel!),
          ),
        FilledButton(
          style: isDestructive
              ? FilledButton.styleFrom(backgroundColor: colorScheme.error)
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

/// A numeric notification badge overlaid on another widget.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.child,
    this.count,
    this.visible = true,
  });

  final Widget child;
  final int? count;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return child;
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceXS,
              vertical: AppDimensions.spaceXXS,
            ),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            decoration: BoxDecoration(
              color: colorScheme.error,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Text(
              count != null ? (count! > 99 ? '99+' : '$count') : '',
              style: AppTextStyles.labelSmall.copyWith(
                color: colorScheme.onError,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
