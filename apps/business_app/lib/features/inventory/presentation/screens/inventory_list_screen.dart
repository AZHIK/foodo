import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/fakes/fake_data_service.dart';
import '../../../../shared/widgets/widgets.dart';

/// Main Inventory management screen — the Inventory tab destination.
///
/// Everything is driven by the shared [AppDataTable] widget:
/// - **Columns** for name, category, unit-of-measure, current stock
///   (with a [StatusBadge] for in-stock / low / out-of-stock), selling
///   price (TZS via [MoneyField.formatDisplay]) and active status.
/// - **Search / sort / export (Excel + PDF)** come for free from the
///   table's built-in toolbar — no extra logic here beyond declaring
///   columns correctly.
/// - The table's own adaptive fallback renders a card list on phone
///   widths, proving the previous stage's adaptive decision is reused
///   rather than reinvented.
///
/// The "Add Item" entry point switches form-factor: an [AppPrimaryButton]
/// in the app bar on tablet/desktop widths, and an [AppFab] on phones.
///
/// Data comes from [fakeInventoryProvider] — an in-memory Riverpod
/// state-holder over the fake service. No backend calls are made yet.
class InventoryListScreen extends ConsumerWidget {
  const InventoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(fakeInventoryProvider);
    final isWide =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointTablet;

    final columns = <AppDataColumn<FakeInventoryItem>>[
      AppDataColumn<FakeInventoryItem>(
        key: 'name',
        label: 'Item Name',
        isPrimary: true,
        valueExtractor: (item) => item.name,
        cellBuilder: (context, item, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.name,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              item.sku,
              style: AppTextStyles.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      AppDataColumn<FakeInventoryItem>(
        key: 'category',
        label: 'Category',
        valueExtractor: (item) => item.category,
      ),
      AppDataColumn<FakeInventoryItem>(
        key: 'unit',
        label: 'Unit',
        valueExtractor: (item) => item.unit,
      ),
      AppDataColumn<FakeInventoryItem>(
        key: 'stock',
        label: 'Stock Level',
        valueExtractor: (item) => item.stockLevel,
        cellBuilder: (context, item, _) {
          if (item.isOutOfStock) {
            return const StatusBadge(
              label: 'Out of Stock',
              variant: StatusBadgeVariant.danger,
            );
          }
          if (item.isLowStock) {
            return StatusBadge(
              label: '${item.stockLevel} ${item.unit} (Low)',
              variant: StatusBadgeVariant.warning,
            );
          }
          return StatusBadge(
            label: '${item.stockLevel} ${item.unit}',
            variant: StatusBadgeVariant.success,
          );
        },
      ),
      AppDataColumn<FakeInventoryItem>(
        key: 'price',
        label: 'Selling Price',
        valueExtractor: (item) => item.priceSenti,
        cellBuilder: (context, item, _) => Text(
          MoneyField.formatDisplay(item.priceSenti),
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      AppDataColumn<FakeInventoryItem>(
        key: 'status',
        label: 'Status',
        valueExtractor: (item) => item.isActive ? 'Active' : 'Inactive',
        cellBuilder: (context, item, _) => item.isActive
            ? const StatusBadge(
                label: 'Active',
                variant: StatusBadgeVariant.success,
              )
            : const StatusBadge(
                label: 'Inactive',
                variant: StatusBadgeVariant.info,
              ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        actions: [
          if (isWide)
            Padding(
              padding: const EdgeInsets.only(right: AppDimensions.spaceMD),
              child: AppPrimaryButton(
                label: 'Add Item',
                icon: Icons.add,
                expanded: false,
                onPressed: () => context.go(AppRoutes.inventoryNew),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceMD),
        child: AppDataTable<FakeInventoryItem>(
          rows: items,
          columns: columns,
          showSearch: true,
          showExport: true,
          showPagination: true,
          emptyStateIcon: Icons.inventory_2_outlined,
          emptyStateTitle: 'No Inventory Items',
          emptyStateSubtitle:
              'Tap "+ Add Item" to create your first stock item.',
          rowOnTap: (item) => context.go('${AppRoutes.inventory}/${item.id}'),
        ),
      ),
      floatingActionButton: !isWide
          ? AppFab(
              icon: Icons.add,
              label: 'Add Item',
              onPressed: () => context.go(AppRoutes.inventoryNew),
            )
          : null,
    );
  }
}
