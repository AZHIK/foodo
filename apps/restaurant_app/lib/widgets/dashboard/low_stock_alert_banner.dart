import 'package:flutter/material.dart';

import '../../models/inventory_item.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';

/// A slim amber strip naming the lines that need reordering.
///
/// Uses the same warning colours as the Low stock badge in the Inventory
/// table, so the alert and the rows it refers to are recognisably the same
/// signal. Renders nothing at all when the stockroom is healthy rather than a
/// reassuring green bar — an alert component that is always present stops
/// being read.
class LowStockAlertBanner extends StatelessWidget {
  const LowStockAlertBanner({
    super.key,
    required this.items,
    required this.onTap,
  });

  final List<InventoryItem> items;

  /// Opens Inventory filtered to the lines this strip is about.
  final VoidCallback onTap;

  /// How many item names to spell out before summarising the remainder.
  static const int _named = 3;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final semantic = context.semantic;
    final outCount = items
        .where((i) => i.status == StockStatus.outOfStock)
        .length;

    final names = items.take(_named).map((i) => i.name).join(', ');
    // Negative when fewer than [_named] items exist, which the guard below
    // treats the same as none left over.
    final extra = items.length - _named;

    final headline = outCount > 0
        ? '$outCount out of stock, ${items.length - outCount} running low'
        : '${items.length} ${items.length == 1 ? 'line needs' : 'lines need'} '
              'reordering';

    return Material(
      color: semantic.warningContainer,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg,
            vertical: Insets.md,
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 20,
                color: semantic.warning,
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      headline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: semantic.warning,
                      ),
                    ),
                    Text(
                      extra > 0 ? '$names and $extra more' : names,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(
                        color: semantic.warning.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Insets.sm),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: semantic.warning,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
