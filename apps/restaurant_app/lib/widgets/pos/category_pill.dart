import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';

/// One tab in the POS category strip.
///
/// Selection is carried by fill *and* weight rather than colour alone, so it
/// still reads at a glance under glare and for a colour-blind cashier.
class CategoryPill extends StatelessWidget {
  const CategoryPill({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = selected ? colors.onPrimary : colors.onSurfaceVariant;

    return Material(
      color: selected ? colors.primary : colors.surfaceContainerLowest,
      elevation: selected ? 1 : 0,
      shadowColor: selected ? colors.primary : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.pill),
        side: BorderSide(
          color: selected ? colors.primary : context.semantic.hairline,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.md,
            vertical: Insets.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: Insets.xs),
              Text(
                label,
                style: context.text.labelMedium?.copyWith(
                  color: selected ? colors.onPrimary : colors.onSurface,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: Insets.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.onPrimary.withValues(alpha: 0.2)
                        : context.semantic.hairline,
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                  child: Text(
                    '$count',
                    style: context.text.labelSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
