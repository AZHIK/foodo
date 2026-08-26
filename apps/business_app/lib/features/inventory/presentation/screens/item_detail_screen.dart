import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/fakes/fake_data_service.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/stock_operations_sheets.dart';

/// Screen displaying comprehensive details and movement history for an
/// inventory item.
///
/// Top section: item header (name, SKU, category, stock [StatusBadge]) plus
/// a row of [InfoCard] summaries (selling/cost price, stock vs reorder
/// threshold, item type) and quick stock-operation buttons.
///
/// Bottom section: a **second** [AppDataTable] — this time typed
/// [AppDataTable<FakeMovement>] — rendering the item's stock-movement log
/// (date, operation, quantity delta, reason, actor). Reusing the exact same
/// widget for two unrelated data shapes is what proves the data table is
/// genuinely generic rather than a hand-rolled list.
///
/// All data reads [fakeInventoryProvider] / [fakeMovementsProvider]; stock
/// operations mutate them via [StockOperations].
class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({required this.itemId, super.key});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(fakeInventoryProvider);
    final item = items.where((i) => i.id == itemId).firstOrNull;

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Item Details')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Item not found.'),
              const SizedBox(height: AppDimensions.spaceMD),
              AppSecondaryButton(
                label: 'Back to Inventory',
                expanded: false,
                onPressed: () => context.go(AppRoutes.inventory),
              ),
            ],
          ),
        ),
      );
    }

    final movements = ref.watch(fakeMovementsProvider(item.id));

    final movementColumns = <AppDataColumn<FakeMovement>>[
      AppDataColumn<FakeMovement>(
        key: 'date',
        label: 'Date & Time',
        isPrimary: true,
        valueExtractor: (m) => m.createdAt.toIso8601String(),
        cellBuilder: (context, m, _) =>
            Text(_formatDateTime(m.createdAt), style: AppTextStyles.bodyMedium),
      ),
      AppDataColumn<FakeMovement>(
        key: 'type',
        label: 'Operation',
        valueExtractor: (m) => m.type,
      ),
      AppDataColumn<FakeMovement>(
        key: 'delta',
        label: 'Delta',
        valueExtractor: (m) => m.quantityDelta,
        cellBuilder: (context, m, _) {
          final isPositive = m.quantityDelta >= 0;
          return Text(
            '${isPositive ? '+' : ''}${m.quantityDelta} ${item.unit}',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: isPositive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
            ),
          );
        },
      ),
      AppDataColumn<FakeMovement>(
        key: 'reason',
        label: 'Reason',
        valueExtractor: (m) => m.reason,
      ),
      AppDataColumn<FakeMovement>(
        key: 'actor',
        label: 'Performed By',
        valueExtractor: (m) => m.actor,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Item',
            onPressed: () =>
                context.go('${AppRoutes.inventory}/${item.id}/edit'),
          ),
          const SizedBox(width: AppDimensions.spaceSM),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard.elevated(
              padding: const EdgeInsets.all(AppDimensions.spaceMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: AppTextStyles.headlineMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spaceXS),
                            Text(
                              'SKU: ${item.sku} • Category: ${item.category}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceMD),
                      if (item.isOutOfStock)
                        const StatusBadge(
                          label: 'Out of Stock',
                          variant: StatusBadgeVariant.danger,
                        )
                      else if (item.isLowStock)
                        StatusBadge(
                          label: '${item.stockLevel} ${item.unit} (Low)',
                          variant: StatusBadgeVariant.warning,
                        )
                      else
                        StatusBadge(
                          label: '${item.stockLevel} ${item.unit}',
                          variant: StatusBadgeVariant.success,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),
                  Divider(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.75),
                    height: AppDimensions.spaceLG,
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 600;
                      final cardWidth = isWide
                          ? 220.0
                          : (constraints.maxWidth - AppDimensions.spaceMD) / 2;
                      return Wrap(
                        spacing: AppDimensions.spaceMD,
                        runSpacing: AppDimensions.spaceMD,
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: InfoCard(
                              label: 'Selling Price',
                              value: MoneyField.formatDisplay(item.priceSenti),
                              leading: const Icon(Icons.payments_outlined),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: InfoCard(
                              label: 'Cost Price',
                              value: MoneyField.formatDisplay(
                                item.costPriceSenti,
                              ),
                              leading: const Icon(Icons.receipt_long_outlined),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: InfoCard(
                              label: 'Stock / Reorder',
                              value:
                                  '${item.stockLevel} / ${item.reorderThreshold} ${item.unit}',
                              leading: const Icon(Icons.inventory_outlined),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: InfoCard(
                              label: 'Item Type',
                              value: _itemTypeLabel(item.itemType),
                              leading: const Icon(Icons.category_outlined),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppDimensions.spaceLG),
                  Wrap(
                    spacing: AppDimensions.spaceSM,
                    runSpacing: AppDimensions.spaceSM,
                    children: [
                      AppSecondaryButton(
                        label: 'Adjust Stock',
                        icon: Icons.tune,
                        expanded: false,
                        onPressed: () =>
                            StockOperations.showAdjustStock(context, ref, item),
                      ),
                      AppSecondaryButton(
                        label: 'Record Waste',
                        icon: Icons.delete_outline,
                        expanded: false,
                        onPressed: () =>
                            StockOperations.showRecordWaste(context, ref, item),
                      ),
                      AppSecondaryButton(
                        label: 'Transfer Stock',
                        icon: Icons.swap_horiz,
                        expanded: false,
                        onPressed: () => StockOperations.showTransferStock(
                          context,
                          ref,
                          item,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spaceLG),
            Text(
              'Stock Movement Log',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceSM),
            AppDataTable<FakeMovement>(
              rows: movements,
              columns: movementColumns,
              showSearch: false,
              showExport: false,
              showPagination: true,
              exportFilenamePrefix: 'movements_${item.id}',
              emptyStateIcon: Icons.history,
              emptyStateTitle: 'No Movements Recorded',
              emptyStateSubtitle:
                  'Stock movement activities for this item will appear here.',
              shrinkWrap: true,
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final mo = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$y-$mo-$day $hh:$mm';
  }

  static String _itemTypeLabel(String type) => switch (type) {
    'prepared_item' => 'Prepared Item',
    'raw_ingredient' => 'Raw Ingredient',
    'resellable' => 'Resellable Item',
    'variant_parent' => 'Variant Parent',
    _ => type,
  };
}
