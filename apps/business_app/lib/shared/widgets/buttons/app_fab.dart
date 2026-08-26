import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';

/// Styled floating action button used as the primary entry-point CTA
/// for POS ("New sale") and Inventory ("Add item").
///
/// Wraps [FloatingActionButton.extended] on wide widths (label + icon)
/// and falls back to a standard compact FAB on narrow widths — so the
/// same widget drops into both layouts without branching logic at the
/// call site.
///
/// Usage:
/// ```dart
/// AppFab(
///   label: 'Add item',
///   icon: Icons.add_rounded,
///   onPressed: () => _openItemEditor(),
/// )
/// ```
class AppFab extends StatelessWidget {
  const AppFab({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.heroTag,
    this.isDestructive = false,
    this.forceCompact = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Object? heroTag;

  /// When `true`, colours the FAB with [ColorScheme.error].
  final bool isDestructive;

  /// Bypass the adaptive check and always render the compact FAB.
  final bool forceCompact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final useExtended =
        !forceCompact && width >= AppDimensions.breakpointTablet;

    final bg = isDestructive ? cs.error : cs.primary;
    final fg = isDestructive ? cs.onError : cs.onPrimary;

    if (useExtended) {
      return FloatingActionButton.extended(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 1,
        hoverElevation: 2,
        focusElevation: 2,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        ),
        icon: Icon(icon),
        label: Text(label),
      );
    }
    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: onPressed,
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 1,
      hoverElevation: 2,
      focusElevation: 2,
      highlightElevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
      ),
      child: Icon(icon),
    );
  }
}
