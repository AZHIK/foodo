import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/inventory_item.dart';
import '../../constants/app_strings.dart';
import '../../providers/categories_provider.dart';
import '../../providers/dashboard_metrics_provider.dart';
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
import '../../widgets/inventory/inventory_tab_bar.dart';
import '../../widgets/item_photo.dart';
import 'menu_item_filter_panel.dart';
import 'stock_adjust_dialog.dart';
import 'stock_transfer_dialog.dart';
import 'waste_log_dialog.dart';

/// Sellable items — everything a customer can order at the till.
///
/// One of the Inventory section's two views (see [InventoryTabBar]). Query
/// filters to `item_type IN (sellable, both)` via [menuCatalogItemsProvider]
/// — a `both` item (a bottled drink bought and resold unchanged) appears
/// here *and* on [InventoryGroceriesScreen], not one or the other, since it
/// genuinely belongs in both.
class InventoryMenuItemsScreen extends ConsumerWidget {
  const InventoryMenuItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(menuItemsQueryProvider);
    final slice = ref.watch(menuItemsSliceProvider);
    final totalItems = ref.watch(menuCatalogItemsProvider).length;
    final filters = ref.watch(menuItemFiltersProvider);
    final notifier = ref.read(menuItemsQueryProvider.notifier);
    final demoSales = ref.watch(_menuDemoSalesProvider);

    return Column(
      children: [
        const InventoryTabBar(active: InventoryTab.menuItems),
        Expanded(
          child: DataPageScaffold(
            title: AppStrings.menuItemsTitle,
            subtitle: AppStrings.menuItemsSubtitle(totalItems),
            actions: dataPageExportActions<InventoryItem>(
              context: context,
              columns: menuItemColumns,
              rows: ref.watch(filteredMenuCatalogProvider),
              title: AppStrings.menuItemsTitle,
              subtitle: _exportSubtitle(filters, query.search),
            ),
            // On phones the scaffold moves this to the FAB, so no mobile-only
            // icon variant is needed here.
            primaryAction: FilledButton.icon(
              onPressed: () => showItemFormDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(AppStrings.addItem),
            ),
            onRefresh: () =>
                ref.read(inventoryItemsProvider.notifier).refresh(),
            fab: DataPageFab(
              icon: Icons.add_rounded,
              label: AppStrings.addMenuItem,
              onPressed: () => showItemFormDialog(context),
            ),
            // Three cards, matching the Groceries screen's stat row. The
            // last two are demo/placeholder data: no real Sales Service
            // integration reaches this screen yet, and the only sales
            // history in the app today (`dashboardMetricsProvider`) is
            // synthesised from a separate mock catalog whose item ids do not
            // line up with these real inventory items — showing it against
            // a specific real row would misattribute sales to the wrong
            // item, which is worse than not showing it at all. An aggregate,
            // clearly-labelled demo figure does not have that problem, so it
            // stands in here until real per-item sales are wired up — at
            // which point this card slots in unchanged.
            metrics: [
              SummaryMetricCard(
                label: AppStrings.menuItemsTitle,
                value: '$totalItems',
                trend: AppStrings.availableAtTill,
                icon: Icons.restaurant_menu_rounded,
              ),
              SummaryMetricCard(
                label: AppStrings.topSeller,
                value: demoSales.topSellerName ?? AppStrings.emDash,
                trend: demoSales.topSellerName == null
                    ? AppStrings.noDemoSales
                    : AppStrings.demoTopSeller(demoSales.topSellerUnits),
                icon: Icons.trending_up_rounded,
                accent: context.colors.tertiary,
              ),
              SummaryMetricCard(
                label: AppStrings.menuRevenue,
                value: Fmt.moneyCompact(demoSales.totalRevenue),
                trend: AppStrings.last7DaysDemo,
                icon: Icons.payments_outlined,
                accent: context.semantic.success,
              ),
            ],
            toolbar: DataTableToolbar(
              searchHint: AppStrings.searchItemsCategory,
              searchValue: query.search,
              onSearchChanged: notifier.setSearch,
              activeFilterCount: filters.activeCount,
              onClearFilters: ref.read(menuItemFiltersProvider.notifier).clear,
              filterBuilder: (_) => const MenuItemFilterPanel(),
              sortOptions: [
                SortOption(
                  label: AppStrings.nameColumn,
                  field: MenuItemSort.name,
                ),
                SortOption(
                  label: AppStrings.categoryColumn,
                  field: MenuItemSort.category,
                ),
                SortOption(
                  label: AppStrings.priceColumn,
                  field: MenuItemSort.price,
                ),
              ],
              sortField: query.sortField,
              sortAscending: query.ascending,
              onSortChanged: (field, ascending) =>
                  notifier.setSort(field, ascending: ascending),
            ),
            table: ReusableDataTable<InventoryItem>(
              columns: menuItemColumns,
              slice: slice,
              query: query,
              onSort: notifier.toggleSort,
              onPageChanged: notifier.setPage,
              onRowTap: (item) => context.pushNamed(
                AppRoute.itemDetailName,
                pathParameters: {'itemId': item.id},
              ),
              rowActions: _actions(ref),
            ),
          ),
        ),
      ],
    );
  }

  List<DataRowAction<InventoryItem>> _actions(WidgetRef ref) => [
    DataRowAction(
      label: AppStrings.viewDetail,
      icon: Icons.open_in_new_rounded,
      onSelected: (context, item) => context.pushNamed(
        AppRoute.itemDetailName,
        pathParameters: {'itemId': item.id},
      ),
    ),
    DataRowAction(
      label: AppStrings.editItem,
      icon: Icons.edit_outlined,
      onSelected: (context, item) =>
          showItemFormDialog(context, existingItem: item),
    ),
    DataRowAction(
      label: AppStrings.adjustStock,
      icon: Icons.tune_rounded,
      isEnabled: (item) => item.trackStock,
      onSelected: (context, item) => showStockAdjustDialog(context, item),
    ),
    DataRowAction(
      label: AppStrings.createReorder,
      icon: Icons.shopping_cart_outlined,
      // A sellable-only item can never be purchase-received (see
      // `services/inventory-service/app/services/stock_movement_service.py`'s
      // `_COMPATIBILITY_RULES`) — reordering it would always fail at
      // receive time, so it's disabled here rather than offered.
      isEnabled: (item) => item.trackStock && item.itemType != 'sellable',
      onSelected: (context, item) => showReorderDialog(context, item),
    ),
    DataRowAction(
      label: AppStrings.logWaste,
      icon: Icons.delete_sweep_outlined,
      isEnabled: (item) => item.trackStock && item.stock > 0,
      onSelected: (context, item) => showWasteLogDialog(context, item),
    ),
    DataRowAction(
      label: AppStrings.transferStock,
      icon: Icons.swap_horiz_rounded,
      isEnabled: (item) => item.trackStock && item.stock > 0,
      onSelected: (context, item) => showStockTransferDialog(context, item),
    ),
    DataRowAction(
      label: AppStrings.deleteAction,
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
        title: Text(AppStrings.deleteItemTitle(item.name)),
        content: Text(AppStrings.deleteMenuItemBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(AppStrings.deleteAction),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(inventoryItemsProvider.notifier).delete(item.id);
      ref.read(stockMovementsProvider.notifier).clearForItem(item.id);
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.itemDeleted(item.name))),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.deleteFailed(e))),
      );
    }
  }

  static String _exportSubtitle(MenuItemFilters filters, String search) {
    final parts = <String>[
      if (filters.categoryIds.isNotEmpty)
        AppStrings.exportCategories(filters.categoryIds.length),
      if (search.trim().isNotEmpty)
        AppStrings.exportMatching(search.trim()),
    ];
    return parts.isEmpty
        ? AppStrings.exportAllMenuItems
        : AppStrings.exportFiltered(parts.join(' · '));
  }
}

// ---------------------------------------------------------------------------
// Demo sales — see the doc comment on the metrics row above for why this is
// clearly labelled rather than presented as real per-item sales data.
// ---------------------------------------------------------------------------

class _MenuDemoSales {
  const _MenuDemoSales({
    required this.topSellerName,
    required this.topSellerUnits,
    required this.totalRevenue,
  });

  final String? topSellerName;
  final int topSellerUnits;
  final double totalRevenue;
}

final _menuDemoSalesProvider = Provider<_MenuDemoSales>((ref) {
  final topItems = ref.watch(dashboardMetricsProvider).topItems;
  final top = topItems.isEmpty ? null : topItems.first;
  final total = topItems.fold<double>(0, (sum, item) => sum + item.revenue);

  return _MenuDemoSales(
    topSellerName: top?.name,
    topSellerUnits: top?.units ?? 0,
    totalRevenue: total,
  );
});

// ---------------------------------------------------------------------------
// Columns
// ---------------------------------------------------------------------------

/// Column config for the Menu Items table.
///
/// No units-sold/revenue columns: per-row sales data would need the same
/// mock-catalog join the demo stat cards above avoid for exactly the reason
/// explained there — showing it against a specific real row would name the
/// wrong item's numbers. Once real per-item sales reach this screen, add
/// them here without restructuring anything else.
final menuItemColumns = <DataColumnSpec<InventoryItem>>[
  DataColumnSpec(
    label: AppStrings.itemColumn,
    field: MenuItemSort.name,
    role: ColumnRole.primary,
    flex: 5,
    value: (item) => item.name,
    cellBuilder: (context, item) => _ItemCell(item: item),
  ),
  DataColumnSpec(
    label: AppStrings.categoryColumn,
    field: MenuItemSort.category,
    flex: 3,
    minTableWidth: 700,
    value: (item) => categoryLabelForId(item.categoryId),
  ),
  DataColumnSpec(
    label: AppStrings.priceColumn,
    field: MenuItemSort.price,
    flex: 2,
    numeric: true,
    value: (item) => item.sellingPrice == null
        ? AppStrings.notForSale
        : Fmt.money(item.sellingPrice!),
  ),
  DataColumnSpec(
    label: AppStrings.activeColumn,
    field: 'isActive',
    sortable: false,
    role: ColumnRole.status,
    width: 110,
    value: (item) =>
        item.isArchived ? AppStrings.archivedBadge : AppStrings.activeBadge,
    cellBuilder: (context, item) => StatusBadge(
      label: item.isArchived ? AppStrings.archivedBadge : AppStrings.activeBadge,
      tone: item.isArchived ? StatusTone.neutral : StatusTone.positive,
      icon: item.isArchived ? Icons.archive_outlined : Icons.check_circle_rounded,
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
          child: ItemPhoto(
            emoji: item.emoji,
            emojiSize: 18,
            bytes: item.image?.bytes,
            imageUrl: item.imageUrl,
            catalogItemId: item.catalogItemId,
          ),
        ),
        const SizedBox(width: Insets.md),
        Expanded(
          child: Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
