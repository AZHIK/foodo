import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

/// Full-screen or inline empty state with icon, title, subtitle, and optional CTA.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  /// When `true`, uses smaller spacing and text — suitable for inline use.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconSize = compact ? 48.0 : 72.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppDimensions.spaceLG : AppDimensions.spaceXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(compact ? AppDimensions.spaceMD : AppDimensions.spaceLG),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: iconSize, color: colorScheme.primary),
            ),
            SizedBox(height: compact ? AppDimensions.spaceMD : AppDimensions.spaceLG),
            Text(
              title,
              style: (compact ? AppTextStyles.titleMedium : AppTextStyles.headlineSmall)
                  .copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppDimensions.spaceSM),
              Text(
                subtitle!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              SizedBox(height: compact ? AppDimensions.spaceMD : AppDimensions.spaceLG),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Centred branded loading spinner.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          if (message != null) ...[
            const SizedBox(height: AppDimensions.spaceMD),
            Text(
              message!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
