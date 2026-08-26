import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_inventory.dart';
import '../../models/inventory_item.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FilterSection(
          title: 'Category',
          child: FilterChipGroup<String>(
            options: [for (final c in MockInventory.categories) c.id],
            selected: filters.categoryIds,
            labelOf: MockInventory.categoryLabel,
            iconOf: (id) => MockInventory.categoryById(id)?.icon,
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
