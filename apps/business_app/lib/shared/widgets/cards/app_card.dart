import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';

/// Unified card widget with three visual variants.
///
/// - [AppCard.flat] — white surface with a minimal ambient shadow
/// - [AppCard.elevated] — white surface with a softer, deeper shadow
/// - [AppCard.outlined] — white surface with a hairline neutral border
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
    final borderRadius = BorderRadius.circular(r);

    final (bg, border, shadows) = switch (variant) {
      AppCardVariant.flat => (
        color ?? colorScheme.surface,
        Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          width: 0.8,
        ),
        _softShadow(colorScheme, opacity: 0.05, blur: 18, offsetY: 6),
      ),
      AppCardVariant.elevated => (
        color ?? colorScheme.surface,
        Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.65),
          width: 0.8,
        ),
        _softShadow(colorScheme, opacity: 0.08, blur: 28, offsetY: 10),
      ),
      AppCardVariant.outlined => (
        color ?? colorScheme.surface,
        Border.all(
          color: colorScheme.outline.withValues(alpha: 0.55),
          width: 0.8,
        ),
        _softShadow(colorScheme, opacity: 0.035, blur: 14, offsetY: 4),
      ),
    };

    return Container(
      margin: margin ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: borderRadius,
        border: border,
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: clipBehavior,
        child: Material(
          color: Colors.transparent,
          child: onTap != null || onLongPress != null
              ? InkWell(
                  onTap: onTap,
                  onLongPress: onLongPress,
                  borderRadius: borderRadius,
                  child: _content,
                )
              : _content,
        ),
      ),
    );
  }

  Widget get _content =>
      padding != null ? Padding(padding: padding!, child: child) : child;

  static List<BoxShadow> _softShadow(
    ColorScheme colorScheme, {
    required double opacity,
    required double blur,
    required double offsetY,
  }) {
    return [
      BoxShadow(
        color: colorScheme.shadow.withValues(alpha: opacity),
        blurRadius: blur,
        offset: Offset(0, offsetY),
      ),
    ];
  }
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
      padding: padding ?? const EdgeInsets.all(AppDimensions.spaceMD),
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
