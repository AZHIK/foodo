import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

/// Unified card widget with three visual variants.
///
/// - [AppCard.flat] — no elevation, coloured surface with low contrast
/// - [AppCard.elevated] — slight elevation + surface tint
/// - [AppCard.outlined] — border only, no elevation
///
/// All variants use [AppDimensions.radiusMD] / [AppDimensions.radiusLG]
/// and delegate colour tokens to the ambient [CardTheme].
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.variant = AppCardVariant.flat,
    this.radius,
    this.color,
    this.clipBehavior = Clip.antiAlias,
  });

  /// Convenience constructor — no border, subtle fill.
  const AppCard.flat({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.radius,
    this.color,
    this.clipBehavior = Clip.antiAlias,
  }) : variant = AppCardVariant.flat;

  /// Elevated card — matches the standard M3 filled-card style.
  const AppCard.elevated({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.radius,
    this.color,
    this.clipBehavior = Clip.antiAlias,
  }) : variant = AppCardVariant.elevated;

  /// Outlined card — border only, transparent background.
  const AppCard.outlined({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.radius,
    this.color,
    this.clipBehavior = Clip.antiAlias,
  }) : variant = AppCardVariant.outlined;

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final AppCardVariant variant;
  final double? radius;
  final Color? color;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final r = radius ?? AppDimensions.radiusMD;

    final (bg, elevation, border) = switch (variant) {
      AppCardVariant.flat => (
          color ?? colorScheme.surfaceContainerLow,
          0.0,
          BorderSide.none,
        ),
      AppCardVariant.elevated => (
          color ?? colorScheme.surfaceContainerLow,
          1.0,
          BorderSide.none,
        ),
      AppCardVariant.outlined => (
          color ?? Colors.transparent,
          0.0,
          BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
    };

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(r),
      side: border,
    );

    return Card(
      margin: margin ?? EdgeInsets.zero,
      elevation: elevation,
      color: bg,
      surfaceTintColor: Colors.transparent,
      shape: shape,
      clipBehavior: clipBehavior,
      child: onTap != null || onLongPress != null
          ? InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(r),
              child: _content,
            )
          : _content,
    );
  }

  Widget get _content => padding != null
      ? Padding(padding: padding!, child: child)
      : child;
}

enum AppCardVariant { flat, elevated, outlined }

/// A coloured info / alert container — not a tappable card.
///
/// Use for banners, callouts, and highlight boxes.
class AppInfoContainer extends StatelessWidget {
  const AppInfoContainer({
    super.key,
    required this.child,
    this.color,
    this.padding,
    this.radius = AppDimensions.radiusMD,
    this.icon,
    this.title,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final IconData? icon;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = color ?? colorScheme.primaryContainer;
    final fg = _contrastFg(colorScheme, bg);

    return Container(
      width: double.infinity,
      padding: padding ??
          const EdgeInsets.all(AppDimensions.spaceMD),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null || title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: fg),
                  const SizedBox(width: AppDimensions.spaceSM),
                ],
                if (title != null)
                  Text(
                    title!,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceSM),
          ],
          DefaultTextStyle(
            style: AppTextStyles.bodySmall.copyWith(color: fg),
            child: child,
          ),
        ],
      ),
    );
  }

  Color _contrastFg(ColorScheme cs, Color bg) {
    if (bg == cs.primaryContainer) return cs.onPrimaryContainer;
    if (bg == cs.secondaryContainer) return cs.onSecondaryContainer;
    if (bg == cs.tertiaryContainer) return cs.onTertiaryContainer;
    if (bg == cs.errorContainer) return cs.onErrorContainer;
    return cs.onSurface;
  }
}
