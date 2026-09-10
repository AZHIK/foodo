import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inventory_item.dart';
import '../models/menu_item.dart';
import 'inventory_provider.dart';

/// Turns a raw category id ("dry_goods", "uncategorized") into a label fit
/// for a pill — real categories are whatever free text a business typed into
/// Inventory Service, so there is no curated label list to look up.
String _humanizeCategoryLabel(String id) => id
    .split(RegExp('[_-]'))
    .where((word) => word.isNotEmpty)
    .map((word) => word[0].toUpperCase() + word.substring(1))
    .join(' ');

/// Maps a local inventory item onto the till's `MenuItem` shape. Every
/// sellable item already lives in the same local database the rest of the
/// app reads from — a menu item is just an inventory item with a price, not
/// a separate thing to curate — so no field here is invented.
MenuItem _toMenuItem(InventoryItem item) {
  // Untracked items (service charges, bottomless condiments) are always
  // available; tracked items are only sellable while there's stock to sell.
  final available = !item.trackStock || item.stock > 0;
  return MenuItem(
    id: item.id,
    name: item.name,
    description: item.description,
    price: item.sellingPrice ?? 0,
    categoryId: item.categoryId,
    emoji: item.emoji,
    isAvailable: available,
    linkedInventoryItemId: item.id,
  );
}

/// The full, unfiltered menu — every local inventory item marked sellable and
/// not archived, mapped onto the POS's `MenuItem` shape.
///
/// Derived from [inventoryItemsListProvider] rather than owning its own list:
/// the local database (synced from Inventory Service, or the shared demo
/// catalog when there's no store context yet) is the single source of truth,
/// so a stock edit on the Inventory screen shows up here without a separate
/// sync.
final menuItemsProvider = Provider<List<MenuItem>>((ref) {
  final items = ref.watch(inventoryItemsListProvider);
  return items
      .where((item) => item.isSellable && !item.isArchived)
      .map(_toMenuItem)
      .toList();
});

/// Menu categories, with the synthetic "All" tab in front. Derived from
/// whatever category strings are actually present among sellable items, so
/// there is nothing to keep in sync with a curated list.
final menuCategoriesProvider = Provider<List<MenuCategory>>((ref) {
  final categoryIds = <String>{
    for (final item in ref.watch(menuItemsProvider)) item.categoryId,
  }.toList()..sort();

  return [
    MenuCategory.all,
    for (final id in categoryIds)
      MenuCategory(
        id: id,
        label: _humanizeCategoryLabel(id),
        icon: Icons.local_offer_outlined,
      ),
  ];
});

/// Currently selected category tab. Defaults to "All".
final selectedCategoryProvider = StateProvider<String>(
  (ref) => MenuCategory.all.id,
);

/// Live text from the POS search field.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Hides items the kitchen has 86'd (out of stock).
final hideUnavailableProvider = StateProvider<bool>((ref) => false);

/// The menu after category, search and availability filters are applied.
///
/// Derived rather than stored, so the grid rebuilds from a single source of
/// truth and no filter state can drift out of sync.
final filteredMenuItemsProvider = Provider<List<MenuItem>>((ref) {
  final items = ref.watch(menuItemsProvider);
  final categoryId = ref.watch(selectedCategoryProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final hideUnavailable = ref.watch(hideUnavailableProvider);

  return items.where((item) {
    if (hideUnavailable && !item.isAvailable) return false;
    if (categoryId != MenuCategory.all.id && item.categoryId != categoryId) {
      return false;
    }
    if (query.isEmpty) return true;
    return item.name.toLowerCase().contains(query) ||
        item.description.toLowerCase().contains(query);
  }).toList();
});

/// Number of items in each category, for the badge on the category tabs.
final categoryCountsProvider = Provider<Map<String, int>>((ref) {
  final items = ref.watch(menuItemsProvider);
  final counts = <String, int>{MenuCategory.all.id: items.length};
  for (final item in items) {
    counts.update(item.categoryId, (n) => n + 1, ifAbsent: () => 1);
  }
  return counts;
});

/// Lookup by id — used by the cart and by order detail to resolve a line back
/// to its menu item.
final menuItemByIdProvider = Provider.family<MenuItem?, String>((ref, id) {
  for (final item in ref.watch(menuItemsProvider)) {
    if (item.id == id) return item;
  }
  return null;
});
