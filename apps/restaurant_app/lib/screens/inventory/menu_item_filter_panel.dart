import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/categories_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/data_page/filter_controls.dart';

/// The Menu Items-specific contents of the shared filter popover/sheet.
///
/// Lighter than [InventoryFilterPanel]: a till item has no stock status or
/// stock-quantity range worth filtering on, so category is the only facet.
class MenuItemFilterPanel extends ConsumerWidget {
  const MenuItemFilterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(menuItemFiltersProvider);
    final notifier = ref.read(menuItemFiltersProvider.notifier);
    // Only categories actually present among menu items — a grocery-only
    // category (Meat & Fish, Dry goods, …) would just be a chip that always
    // empties the table.
    final presentCategoryIds = {
      for (final item in ref.watch(menuCatalogItemsProvider)) item.categoryId,
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
      ],
    );
  }
}
