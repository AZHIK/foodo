import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';

/// Styled icon-button wrapper with consistent sizing, splash radius,
/// and optional filled / outlined / tonal variants.
///
/// Drop-in replacement for raw [IconButton] usage — the wrapper ensures
/// every icon button respects the theme tokens without ad hoc styling.
///
/// Usage:
/// ```dart
/// AppIconButton(
///   icon: Icons.delete_outline,
///   variant: AppIconButtonVariant.tonal,
///   isDestructive: true,
///   onPressed: () => _removeItem(line),
/// )
/// ```
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = AppIconButtonVariant.plain,
    this.isDestructive = false,
    this.tooltip,
    this.size = 40,
    this.iconSize = 22,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final AppIconButtonVariant variant;
  final bool isDestructive;
  final String? tooltip;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg, side) = switch (variant) {
      AppIconButtonVariant.plain => (null, isDestructive ? cs.error : null, null),
      AppIconButtonVariant.tonal => (
          isDestructive
              ? cs.errorContainer.withValues(alpha: 0.5)
              : cs.secondaryContainer,
          isDestructive ? cs.onErrorContainer : cs.onSecondaryContainer,
          null,
        ),
      AppIconButtonVariant.filled => (
          isDestructive ? cs.error : cs.primary,
          isDestructive ? cs.onError : cs.onPrimary,
          null,
        ),
      AppIconButtonVariant.outlined => (
          Colors.transparent,
          isDestructive ? cs.error : cs.onSurfaceVariant,
          BorderSide(color: cs.outlineVariant),
        ),
    };

    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: side,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          padding: EdgeInsets.zero,
        ),
        icon: Icon(icon, size: iconSize),
      ),
    );
  }
}

enum AppIconButtonVariant {
  /// Transparent background, icon-only. Default for toolbar actions.
  plain,

  /// Tonal background matching Material 3 IconButton.tonal.
  tonal,

  /// Solid filled background.
  filled,

  /// Outlined border with no fill.
  outlined,
}
