import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_menu.dart';
import '../models/menu_item.dart';

/// Menu categories, with the synthetic "All" tab in front.
///
/// Backend swap: replace the body with a `FutureProvider` reading your API and
/// have consumers handle the `AsyncValue`.
final menuCategoriesProvider = Provider<List<MenuCategory>>((ref) {
  return [MenuCategory.all, ...MockMenu.categories];
});

/// The source of truth for menu items.
class MenuNotifier extends Notifier<List<MenuItem>> {
  @override
  List<MenuItem> build() => MockMenu.items;

  void upsert(MenuItem item) {
    final index = state.indexWhere((m) => m.id == item.id);
    if (index == -1) {
      state = [item, ...state];
      return;
    }
    final next = [...state];
    next[index] = item;
    state = next;
  }

  void delete(String id) => state = state.where((m) => m.id != id).toList();

  String nextId() {
    var highest = 0;
    for (final item in state) {
      final n = int.tryParse(item.id.split('-').last);
      if (n != null && n > highest) highest = n;
    }
    return 'mn-${(highest + 1).toString().padLeft(2, '0')}';
  }
}

/// The full, unfiltered menu.
final menuItemsProvider =
    NotifierProvider<MenuNotifier, List<MenuItem>>(MenuNotifier.new);

/// Currently selected category tab. Defaults to "All".
final selectedCategoryProvider = StateProvider<String>(
  (ref) => MenuCategory.all.id,
);

/// Live text from the POS search field.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Hides items the kitchen has 86'd.
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
    // Archived items never appear in the POS grid.
    if (item.isArchived) return false;
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

/// Reverse lookup: find all menu items linked to an inventory item.
final menuItemsByInventoryIdProvider =
    Provider.family<List<MenuItem>, String>((ref, inventoryItemId) {
  return ref
      .watch(menuItemsProvider)
      .where((item) => item.linkedInventoryItemId == inventoryItemId)
      .toList();
});
