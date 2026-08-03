import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

/// Helper that shows consistently styled snack-bars across the app.
///
/// Usage:
/// ```dart
/// AppSnackBar.showSuccess(context, 'Profile saved');
/// AppSnackBar.showError(context, AppStrings.networkError);
/// AppSnackBar.showInfo(context, AppStrings.syncing);
/// ```
abstract final class AppSnackBar {
  AppSnackBar._();

  static void showSuccess(BuildContext context, String message) =>
      _show(context, message, _Variant.success);

  static void showError(BuildContext context, String message) =>
      _show(context, message, _Variant.error);

  static void showInfo(BuildContext context, String message) =>
      _show(context, message, _Variant.info);

  static void showWarning(BuildContext context, String message) =>
      _show(context, message, _Variant.warning);

  static void _show(BuildContext context, String message, _Variant variant) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(variant.icon, color: Colors.white, size: 20),
              const SizedBox(width: AppDimensions.spaceSM),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: variant.color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          margin: const EdgeInsets.all(AppDimensions.spaceMD),
        ),
      );
  }
}

enum _Variant {
  success(AppColors.synced, Icons.check_circle_outline),
  error(AppColors.outOfStock, Icons.error_outline),
  info(AppColors.lightPrimary, Icons.info_outline),
  warning(AppColors.pendingSync, Icons.warning_amber_outlined);

  const _Variant(this.color, this.icon);
  final Color color;
  final IconData icon;
}
