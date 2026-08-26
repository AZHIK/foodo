import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_inventory.dart';
import '../models/inventory_item.dart';
import '../models/table_query.dart';
import 'table_query_provider.dart';

/// Sortable column keys. Kept as constants rather than raw strings at the call
/// sites so the column config and the sort switch cannot drift apart.
abstract final class InventorySort {
  static const name = 'name';
  static const category = 'category';
  static const stock = 'stock';
  static const cost = 'cost';
  static const value = 'value';
  static const status = 'status';
}

// ---------------------------------------------------------------------------
// Raw data
// ---------------------------------------------------------------------------

/// Owns the stock list. Mutable because the page can add, edit, adjust and
/// delete — a read-only Provider would not survive the first "Add item".
class InventoryNotifier extends Notifier<List<InventoryItem>> {
  @override
  List<InventoryItem> build() => List.of(MockInventory.items);

  /// Inserts a new item or replaces an existing one with the same id.
  void upsert(InventoryItem item) {
    final index = state.indexWhere((i) => i.id == item.id);
    if (index == -1) {
      state = [item, ...state];
      return;
    }
    final next = [...state];
    next[index] = item;
    state = next;
  }

  void delete(String id) =>
      state = state.where((item) => item.id != id).toList();

  /// Applies a relative change, clamped at zero — stock can run out, but it
  /// cannot go negative.
  void adjustStock(String id, int delta) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(
            stock: (item.stock + delta).clamp(0, 1 << 31),
            lastCountedAt: DateTime.now(),
          )
        else
          item,
    ];
  }

  void setStock(String id, int value) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(
            stock: value < 0 ? 0 : value,
            lastCountedAt: DateTime.now(),
          )
        else
          item,
    ];
  }

  /// Continues the inv-## sequence from the highest existing id.
  String nextId() {
    var highest = 0;
    for (final item in state) {
      final n = int.tryParse(item.id.split('-').last);
      if (n != null && n > highest) highest = n;
    }
    return 'inv-${(highest + 1).toString().padLeft(2, '0')}';
  }
}

final inventoryItemsProvider =
    NotifierProvider<InventoryNotifier, List<InventoryItem>>(
      InventoryNotifier.new,
    );

// ---------------------------------------------------------------------------
// Search / sort / pagination
// ---------------------------------------------------------------------------

final inventoryQueryProvider = NotifierProvider<TableQueryNotifier, TableQuery>(
  () => TableQueryNotifier(
    const TableQuery(sortField: InventorySort.name, pageSize: 8),
  ),
);

// ---------------------------------------------------------------------------
// Filters
// ---------------------------------------------------------------------------

/// The Inventory filter panel's state. An empty set means "no constraint",
/// which keeps "nothing ticked" and "everything ticked" from behaving
/// differently for the user.
@immutable
class InventoryFilters {
  const InventoryFilters({
    this.categoryIds = const {},
    this.statuses = const {},
    this.minStock,
    this.maxStock,
  });

  final Set<String> categoryIds;
  final Set<StockStatus> statuses;
  final int? minStock;
  final int? maxStock;

  bool get hasStockRange => minStock != null || maxStock != null;

  /// Drives the count badge on the Filter button. The stock range counts once
  /// however many ends are set.
  int get activeCount =>
      categoryIds.length + statuses.length + (hasStockRange ? 1 : 0);

  bool matches(InventoryItem item) {
    if (categoryIds.isNotEmpty && !categoryIds.contains(item.categoryId)) {
      return false;
    }
    if (statuses.isNotEmpty && !statuses.contains(item.status)) return false;
    if (minStock != null && item.stock < minStock!) return false;
    if (maxStock != null && item.stock > maxStock!) return false;
    return true;
  }

  InventoryFilters copyWith({
    Set<String>? categoryIds,
    Set<StockStatus>? statuses,
    int? minStock,
    int? maxStock,
    bool clearRange = false,
  }) {
    return InventoryFilters(
      categoryIds: categoryIds ?? this.categoryIds,
      statuses: statuses ?? this.statuses,
      minStock: clearRange ? null : (minStock ?? this.minStock),
      maxStock: clearRange ? null : (maxStock ?? this.maxStock),
    );
  }
}

class InventoryFiltersNotifier extends Notifier<InventoryFilters> {
  @override
  InventoryFilters build() => const InventoryFilters();

  void toggleCategory(String id) {
    final next = Set<String>.of(state.categoryIds);
    next.contains(id) ? next.remove(id) : next.add(id);
    state = state.copyWith(categoryIds: next);
    _resetPage();
  }

  void toggleStatus(StockStatus status) {
    final next = Set<StockStatus>.of(state.statuses);
    next.contains(status) ? next.remove(status) : next.add(status);
    state = state.copyWith(statuses: next);
    _resetPage();
  }

  void setStockRange(int? min, int? max) {
    state = min == null && max == null
        ? state.copyWith(clearRange: true)
        : state.copyWith(minStock: min, maxStock: max);
    _resetPage();
  }

  void clear() {
    state = const InventoryFilters();
    _resetPage();
  }

  /// Narrowing the result set must send the user back to page one, or they
  /// can be stranded on a page that no longer exists.
  void _resetPage() => ref.read(inventoryQueryProvider.notifier).resetPage();
}

final inventoryFiltersProvider =
    NotifierProvider<InventoryFiltersNotifier, InventoryFilters>(
      InventoryFiltersNotifier.new,
    );

/// Highest stock count in the data, so the range filter can bound its inputs
/// instead of guessing a maximum.
final inventoryStockCeilingProvider = Provider<int>((ref) {
  var highest = 0;
  for (final item in ref.watch(inventoryItemsProvider)) {
    if (item.stock > highest) highest = item.stock;
  }
  return highest;
});

// ---------------------------------------------------------------------------
// Derived views
// ---------------------------------------------------------------------------

/// Search + filters + sort, composed in one place. The screen never sees an
/// unfiltered list, and no filtering logic lives in the widget tree.
final filteredInventoryProvider = Provider<List<InventoryItem>>((ref) {
  final items = ref.watch(inventoryItemsProvider);
  final query = ref.watch(inventoryQueryProvider);
  final filters = ref.watch(inventoryFiltersProvider);
  final search = query.search.trim().toLowerCase();

  final rows = items.where((item) {
    if (!filters.matches(item)) return false;
    if (search.isEmpty) return true;
    return item.name.toLowerCase().contains(search) ||
        item.sku.toLowerCase().contains(search) ||
        MockInventory.categoryLabel(item.categoryId)
            .toLowerCase()
            .contains(search) ||
        item.supplier.toLowerCase().contains(search);
  }).toList();

  final direction = query.ascending ? 1 : -1;
  rows.sort((a, b) {
    final cmp = switch (query.sortField) {
      InventorySort.category => MockInventory.categoryLabel(
        a.categoryId,
      ).compareTo(MockInventory.categoryLabel(b.categoryId)),
      InventorySort.stock => a.stock.compareTo(b.stock),
      InventorySort.cost => a.unitCost.compareTo(b.unitCost),
      InventorySort.value => a.totalValue.compareTo(b.totalValue),
      // In stock → low → out, so ascending reads as "least urgent first".
      InventorySort.status => a.status.index.compareTo(b.status.index),
      _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    };
    // Stable tiebreak keeps rows from shuffling between equal values.
    return cmp != 0 ? cmp * direction : a.id.compareTo(b.id);
  });

  return rows;
});

final inventorySliceProvider = Provider<PageSlice<InventoryItem>>(
  (ref) => PageSlice.of(
    ref.watch(filteredInventoryProvider),
    ref.watch(inventoryQueryProvider),
  ),
);

@immutable
class InventorySummary {
  const InventorySummary({
    required this.totalItems,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.totalValue,
  });

  final int totalItems;
  final int lowStockCount;
  final int outOfStockCount;
  final double totalValue;

  /// Low and out-of-stock together — everything that needs a purchase order.
  int get needsAttention => lowStockCount + outOfStockCount;
}

/// Computed over the whole stockroom, not the current filter, so the header
/// stays a stable "how are we doing" readout while the user filters below it.
final inventorySummaryProvider = Provider<InventorySummary>((ref) {
  final items = ref.watch(inventoryItemsProvider);

  var low = 0;
  var out = 0;
  var value = 0.0;
  for (final item in items) {
    value += item.totalValue;
    switch (item.status) {
      case StockStatus.lowStock:
        low++;
      case StockStatus.outOfStock:
        out++;
      case StockStatus.inStock:
        break;
    }
  }

  return InventorySummary(
    totalItems: items.length,
    lowStockCount: low,
    outOfStockCount: out,
    totalValue: value,
  );
});
