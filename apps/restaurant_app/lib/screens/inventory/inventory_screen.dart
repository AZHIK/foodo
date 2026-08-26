import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock_inventory.dart';
import '../../models/inventory_item.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/stock_movement_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../../widgets/data_page/data_column_spec.dart';
import '../../widgets/data_page/data_page_scaffold.dart';
import '../../widgets/data_page/data_table_toolbar.dart';
import '../../widgets/data_page/export_actions.dart';
import '../../widgets/data_page/reusable_data_table.dart';
import '../../widgets/data_page/status_badge.dart';
import '../../widgets/data_page/summary_metric_card.dart';
import '../../widgets/dialogs/item_form_dialog.dart';
import '../../widgets/dialogs/reorder_dialog.dart';
import 'inventory_filter_panel.dart';
import 'stock_adjust_dialog.dart';
import 'stock_transfer_dialog.dart';
import 'waste_log_dialog.dart';

/// Maps the stockroom's vocabulary onto the shared badge tones.
extension StockStatusTone on StockStatus {
  StatusTone get tone => switch (this) {
    StockStatus.inStock => StatusTone.positive,
    StockStatus.lowStock => StatusTone.warning,
    StockStatus.outOfStock => StatusTone.danger,
  };

  IconData get badgeIcon => switch (this) {
    StockStatus.inStock => Icons.check_circle_rounded,
    StockStatus.lowStock => Icons.warning_amber_rounded,
    StockStatus.outOfStock => Icons.remove_shopping_cart_outlined,
  };
}

/// Stock levels, built entirely from the shared data-page layer — this file
/// contains column config, filters and actions, and no layout of its own.
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(inventoryQueryProvider);
    final slice = ref.watch(inventorySliceProvider);
    final summary = ref.watch(inventorySummaryProvider);
    final filters = ref.watch(inventoryFiltersProvider);
    final notifier = ref.read(inventoryQueryProvider.notifier);

    return DataPageScaffold(
      title: 'Inventory',
      subtitle:
          '${summary.totalItems} lines tracked across '
          '${MockInventory.categories.length} categories',
      // Exports the filtered, sorted list — every matching row, not just the
      // page on screen.
      actions: dataPageExportActions<InventoryItem>(
        context: context,
        columns: inventoryColumns,
        rows: ref.watch(filteredInventoryProvider),
        title: 'Inventory',
        subtitle: _exportSubtitle(filters, query.search),
      ),
      primaryAction: context.isMobile
          ? SizedBox(
              height: 40,
              width: 40,
              child: Tooltip(
                message: 'Add item',
                child: Material(
                  color: context.colors.primary,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    onPressed: () => showItemFormDialog(context),
                    icon: const Icon(Icons.add_rounded),
                    color: context.colors.onPrimary,
                  ),
                ),
              ),
            )
          : FilledButton.icon(
              onPressed: () => showItemFormDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add item'),
            ),
      metrics: [
        SummaryMetricCard(
          label: 'Total items',
          value: '${summary.totalItems}',
          trend: '${summary.totalItems - summary.needsAttention} fully stocked',
          icon: Icons.inventory_2_outlined,
        ),
        SummaryMetricCard(
          label: 'Low stock',
          value: '${summary.lowStockCount}',
          trend: summary.outOfStockCount == 0
              ? 'Nothing out of stock'
              : '${summary.outOfStockCount} out of stock',
          trendDirection: summary.needsAttention == 0
              ? TrendDirection.flat
              : TrendDirection.down,
          icon: Icons.warning_amber_rounded,
          accent: context.semantic.warning,
        ),
        SummaryMetricCard(
          label: 'Inventory value',
          value: Fmt.moneyCompact(summary.totalValue),
          trend: 'At cost, all categories',
          icon: Icons.savings_outlined,
          accent: context.semantic.success,
        ),
      ],
      toolbar: DataTableToolbar(
        searchHint: 'Search items, SKU or supplier',
        searchValue: query.search,
        onSearchChanged: notifier.setSearch,
        activeFilterCount: filters.activeCount,
        onClearFilters: ref.read(inventoryFiltersProvider.notifier).clear,
        filterBuilder: (_) => const InventoryFilterPanel(),
        sortOptions: const [
          SortOption(label: 'Name', field: InventorySort.name),
          SortOption(label: 'Category', field: InventorySort.category),
          SortOption(label: 'Stock', field: InventorySort.stock),
          SortOption(label: 'Unit cost', field: InventorySort.cost),
          SortOption(label: 'Status', field: InventorySort.status),
        ],
        sortField: query.sortField,
        sortAscending: query.ascending,
        onSortChanged: (field, ascending) =>
            notifier.setSort(field, ascending: ascending),
      ),
      table: ReusableDataTable<InventoryItem>(
        columns: inventoryColumns,
        slice: slice,
        query: query,
        onSort: notifier.toggleSort,
        onPageChanged: notifier.setPage,
        // The row body opens the read-only detail screen; the row's own "Edit"
        // action still goes straight to the form.
        onRowTap: (item) =>
            context.pushNamed(
              AppRoute.itemDetailName,
              pathParameters: {'itemId': item.id},
            ),
        rowActions: _actions(ref),
      ),
    );
  }

  List<DataRowAction<InventoryItem>> _actions(WidgetRef ref) => [
    DataRowAction(
      label: 'View detail',
      icon: Icons.open_in_new_rounded,
      onSelected: (context, item) => context.pushNamed(
        AppRoute.itemDetailName,
        pathParameters: {'itemId': item.id},
      ),
    ),
    DataRowAction(
      label: 'Edit item',
      icon: Icons.edit_outlined,
      onSelected: (context, item) =>
          showItemFormDialog(context, existingItem: item),
    ),
    DataRowAction(
      label: 'Adjust stock',
      icon: Icons.tune_rounded,
      // Untracked lines have no count to adjust.
      isEnabled: (item) => item.trackStock,
      onSelected: (context, item) => showStockAdjustDialog(context, item),
    ),
    DataRowAction(
      label: 'Create reorder',
      icon: Icons.shopping_cart_outlined,
      isEnabled: (item) => item.trackStock,
      onSelected: (context, item) => showReorderDialog(context, item),
    ),
    DataRowAction(
      label: 'Log waste',
      icon: Icons.delete_sweep_outlined,
      isEnabled: (item) => item.trackStock && item.stock > 0,
      onSelected: (context, item) => showWasteLogDialog(context, item),
    ),
    DataRowAction(
      label: 'Transfer stock',
      icon: Icons.swap_horiz_rounded,
      isEnabled: (item) => item.trackStock && item.stock > 0,
      onSelected: (context, item) => showStockTransferDialog(context, item),
    ),
    DataRowAction(
      label: 'Delete',
      icon: Icons.delete_outline_rounded,
      isDestructive: true,
      onSelected: (context, item) => _confirmDelete(context, ref, item),
    ),
  ];

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${item.name}?'),
        content: const Text(
          'The item and its stock count will be removed from inventory. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    ref.read(inventoryItemsProvider.notifier).delete(item.id);
    // The ledger goes with the item — orphaned movements would keep counting
    // against a line that no longer exists.
    ref.read(stockMovementsProvider.notifier).clearForItem(item.id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${item.name} deleted')));
  }

  /// Records on the exported file which view produced it — an unqualified
  /// stock report is easy to mistake for the whole stockroom.
  static String _exportSubtitle(InventoryFilters filters, String search) {
    final parts = <String>[
      if (filters.categoryIds.isNotEmpty)
        '${filters.categoryIds.length} categories',
      if (filters.statuses.isNotEmpty)
        filters.statuses.map((s) => s.label).join(', '),
      if (filters.hasStockRange)
        'stock ${filters.minStock ?? 0}–${filters.maxStock ?? 'any'}',
      if (search.trim().isNotEmpty) 'matching "${search.trim()}"',
    ];

    return parts.isEmpty ? 'All items' : 'Filtered by ${parts.join(' · ')}';
  }
}

/// Column config for the stock table.
///
/// Top-level so the exporters can reuse the exact same definitions — the
/// spreadsheet then carries the same columns and the same formatting the
/// screen shows.
final inventoryColumns = <DataColumnSpec<InventoryItem>>[
  DataColumnSpec(
    label: 'Item',
    field: InventorySort.name,
    role: ColumnRole.primary,
    flex: 5,
    value: (item) => item.name,
    cellBuilder: (context, item) => _ItemCell(item: item),
  ),
  DataColumnSpec(
    label: 'Category',
    field: InventorySort.category,
    flex: 3,
    minTableWidth: 860,
    value: (item) => MockInventory.categoryLabel(item.categoryId),
  ),
  DataColumnSpec(
    label: 'Stock',
    field: InventorySort.stock,
    flex: 2,
    numeric: true,
    value: (item) => '${item.stock} ${item.unit}',
    cellBuilder: (context, item) => _StockCell(item: item),
  ),
  DataColumnSpec(
    label: 'Unit cost',
    field: InventorySort.cost,
    flex: 2,
    numeric: true,
    minTableWidth: 700,
    value: (item) => Fmt.money(item.unitCost),
  ),
  DataColumnSpec(
    label: 'Status',
    field: InventorySort.status,
    role: ColumnRole.status,
    width: 132,
    value: (item) => item.status.label,
    cellBuilder: (context, item) => StatusBadge(
      label: item.status.label,
      tone: item.status.tone,
      icon: item.status.badgeIcon,
      dense: true,
    ),
  ),
];

class _ItemCell extends StatelessWidget {
  const _ItemCell({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          alignment: Alignment.center,
          // An uploaded photo replaces the emoji placeholder, so a picture
          // chosen in the item form is visible back on the list.
          child: item.image != null
              ? Image.memory(
                  item.image!.bytes,
                  fit: BoxFit.cover,
                  width: 36,
                  height: 36,
                )
              : Text(item.emoji, style: const TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: Insets.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                item.sku,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StockCell extends StatelessWidget {
  const _StockCell({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final short = item.status != StockStatus.inStock;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            '${item.stock}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              // A number below the reorder level is the thing a manager is
              // scanning for, so it carries the warning colour itself.
              color: short ? context.semantic.warning : null,
            ),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          item.unit,
          maxLines: 1,
          style: context.text.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
