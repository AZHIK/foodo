import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';

/// Semantic weight of a status, independent of what the status *means*.
///
/// Domain enums (OrderStatus, StockStatus, …) map themselves onto a tone at
/// the page layer, which keeps this widget free of any page-specific
/// knowledge — the whole point of it being shared.
enum StatusTone {
  positive,
  warning,
  danger,
  neutral,
  info;

  IconData get defaultIcon => switch (this) {
    StatusTone.positive => Icons.check_circle_rounded,
    StatusTone.warning => Icons.error_outline_rounded,
    StatusTone.danger => Icons.cancel_rounded,
    StatusTone.neutral => Icons.remove_circle_outline_rounded,
    StatusTone.info => Icons.info_outline_rounded,
  };
}

/// A coloured pill for a status value.
///
/// Always pairs colour with a shape-bearing icon, so the status survives a
/// monochrome receipt printer and a colour-blind reader.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
    this.dense = false,
    this.color,
  });

  final String label;
  final StatusTone tone;

  /// Overrides [StatusTone.defaultIcon].
  final IconData? icon;
  final bool dense;

  /// Replaces the colour [tone] would pick, for a palette the semantic tones
  /// have no slot for — one colour per staff role, say, where "Cashier" and
  /// "Manager" are both neutral facts that still need telling apart. The
  /// container is derived from it, so the pill keeps the same contrast
  /// relationship a toned badge has.
  final Color? color;

  /// Tint strength for a derived container. Low enough that the foreground
  /// text stays legible over it in both brightnesses.
  static const double _containerAlpha = 0.14;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final colors = context.colors;

    final (background, foreground) = switch (color) {
      final override? => (override.withValues(alpha: _containerAlpha), override),
      null => switch (tone) {
        StatusTone.positive => (semantic.successContainer, semantic.success),
        StatusTone.warning => (semantic.warningContainer, semantic.warning),
        StatusTone.danger => (semantic.dangerContainer, semantic.danger),
        StatusTone.neutral => (
          colors.surfaceContainerHighest,
          colors.onSurfaceVariant,
        ),
        StatusTone.info => (colors.primaryContainer, colors.onPrimaryContainer),
      },
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? Insets.sm : Insets.md - 2,
        vertical: dense ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? tone.defaultIcon,
            size: dense ? 12 : 13,
            color: foreground,
          ),
          const SizedBox(width: Insets.xs + 1),
          // Flexible so a badge in a too-narrow slot degrades to an ellipsis
          // rather than painting outside its container.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
