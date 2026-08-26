import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';

/// One tappable option out of a set where exactly one is chosen.
///
/// Order type on the ticket, tender on the payment dialog — the same control
/// each time, so "the selected one" looks identical wherever the cashier meets
/// it. Selection is carried by fill *and* border rather than colour alone, for
/// the same reason [StatusBadge] pairs colour with an icon.
class SelectableOptionCard extends StatelessWidget {
  const SelectableOptionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.dense = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  /// Second line under the label, e.g. a tender's terminal state.
  final String? subtitle;

  /// Tightens the card for the narrow order panel, where three of these have
  /// to share 210px.
  final bool dense;

  /// Comfortable for a thumb on a counter terminal, and above the 44px floor
  /// at every breakpoint — these do not shrink on mobile, they reflow.
  static const double minHeight = 60;
  static const double denseMinHeight = 48;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = selected
        ? colors.onPrimaryContainer
        : colors.onSurfaceVariant;

    return Material(
      color: selected ? colors.primaryContainer : colors.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.sm + 2),
        side: BorderSide(
          color: selected ? colors.primary : context.semantic.hairline,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Tooltip(
          message: label,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: dense ? denseMinHeight : minHeight,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Insets.sm,
                vertical: dense ? Insets.sm : Insets.md - 2,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: dense ? 18 : 21, color: foreground),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: context.text.labelSmall?.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: context.text.labelSmall?.copyWith(
                        color: foreground.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lays options out in a grid of [perRow] equal columns.
///
/// A [Wrap] of measured widths rather than a GridView: these sit inside
/// dialogs and panels that are already scrolling, and equal widths are what
/// stops "QRIS" and "Mobile Pay" rendering as two different-sized buttons.
class SelectableOptionGrid extends StatelessWidget {
  const SelectableOptionGrid({
    super.key,
    required this.perRow,
    required this.children,
    this.spacing = Insets.sm,
  });

  final int perRow;
  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = perRow.clamp(1, children.length);
        // Floored, so rounding never leaves the last card a hair too wide for
        // the row it is meant to share.
        final width =
            ((constraints.maxWidth - spacing * (columns - 1)) / columns)
                .floorToDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: width > 0 ? width : null, child: child),
          ],
        );
      },
    );
  }
}
