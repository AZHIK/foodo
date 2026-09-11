import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/inventory_item.dart';
import '../../providers/categories_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/data_page/filter_controls.dart';

/// The Inventory-specific contents of the shared filter popover/sheet.
///
/// Knows nothing about where it is rendered — [DataTableToolbar] decides
/// whether that is a desktop popover or a mobile bottom sheet.
class InventoryFilterPanel extends ConsumerWidget {
  const InventoryFilterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(inventoryFiltersProvider);
    final notifier = ref.read(inventoryFiltersProvider.notifier);
    final ceiling = ref.watch(inventoryStockCeilingProvider);
    // Only categories actually present among grocery items — a menu-only
    // category (Mains, Desserts, …) would just be a chip that always empties
    // the table.
    final presentCategoryIds = {
      for (final item in ref.watch(groceryItemsProvider)) item.categoryId,
    };
    final categories = ref.watch(categoriesListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FilterSection(
          title: 'Category',
          child: FilterChipGroup<String>(
            options: [
              for (final c in categories)
                if (presentCategoryIds.contains(c.id)) c.id,
            ],
            selected: filters.categoryIds,
            labelOf: (id) => categoryLabelFrom(categories, id),
            iconOf: (id) => categoryByIdFrom(categories, id)?.icon,
            onToggle: notifier.toggleCategory,
          ),
        ),
        const SizedBox(height: Insets.xl),
        FilterSection(
          title: 'Stock status',
          child: FilterChipGroup<StockStatus>(
            options: StockStatus.values,
            selected: filters.statuses,
            labelOf: (status) => status.label,
            onToggle: notifier.toggleStatus,
          ),
        ),
        const SizedBox(height: Insets.xl),
        FilterSection(
          title: 'Stock quantity',
          child: NumberRangeField(
            min: filters.minStock,
            max: filters.maxStock,
            ceiling: ceiling,
            onChanged: notifier.setStockRange,
          ),
        ),
      ],
    );
  }
}
