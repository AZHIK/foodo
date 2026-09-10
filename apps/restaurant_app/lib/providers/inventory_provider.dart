import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_inventory.dart';
import '../models/inventory_item.dart';
import '../models/table_query.dart';
import '../services/inventory_api_service.dart';
import '../sync/catalog_sync_service.dart';
import '../sync/inventory_item_mapper.dart';
import 'database_providers.dart';
import 'inventory_api_provider.dart';
import 'permissions_provider.dart';
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
  static const reorderLevel = 'reorderLevel';
}

// ---------------------------------------------------------------------------
// Raw data
// ---------------------------------------------------------------------------

/// Owns the stock list, backed by Inventory Service (catalog + stock-level
/// cache) once a store context exists.
///
/// The UI always reads from the local cache — `build()` never blocks on the
/// network. A live fetch runs in the background on every read to keep that
/// cache current; if it fails (no permission, offline, a 401 whose
/// retry-with-refresh-token also fails) the screen just keeps showing
/// whatever was last cached instead of going blank or erroring — same
/// stale-while-revalidate contract as `RolesNotifier`.
///
/// With no store context at all (no session yet — e.g. a fresh
/// `ProviderContainer` in a test that hasn't seeded one), this falls back to
/// [MockInventory] rather than an empty list, so screens/tests that don't
/// care about backend wiring still see a populated demo catalog.
class InventoryNotifier extends AsyncNotifier<List<InventoryItem>> {
  CatalogSyncService get _sync => ref.read(catalogSyncServiceProvider);
  InventoryApiService get _api => ref.read(inventoryApiServiceProvider);

  String get _businessId {
    final id = ref.read(currentBusinessIdProvider);
    if (id == null) throw StateError('No active business context');
    return id;
  }

  @override
  Future<List<InventoryItem>> build() async {
    final storeId = ref.watch(currentStoreIdProvider);
    if (storeId == null) return List.of(MockInventory.items);

    var disposed = false;
    ref.onDispose(() => disposed = true);
    unawaited(_refreshFromApi(storeId, isDisposed: () => disposed));

    return _loadFromCache(storeId);
  }

  Future<void> _refreshFromApi(String storeId, {required bool Function() isDisposed}) async {
    try {
      await _sync.syncCatalog(storeId: storeId);
      await _sync.syncStockLevels(storeId: storeId);
      if (!isDisposed()) {
        state = AsyncData(await _loadFromCache(storeId));
      }
    } catch (_) {
      // No permission, offline, or a transient failure — the cached read
      // from `build()` is what the UI already shows; nothing more to do.
    }
  }

  Future<List<InventoryItem>> _loadFromCache(String storeId) async {
    final db = ref.read(appDatabaseProvider);
    final items = await (db.select(db.cachedItems)
          ..where((row) => row.businessLocationId.equals(storeId) & row.isActive.equals(true)))
        .get();
    final stockLevels = await (db.select(db.cachedStockLevels)
          ..where((row) => row.businessLocationId.equals(storeId)))
        .get();
    final stockByItemId = {for (final level in stockLevels) level.itemId: level};

    return items
        .map((item) => inventoryItemFromCachedRow(
              catalogRow: item,
              stockRow: stockByItemId[item.id],
            ))
        .toList();
  }

  /// Re-runs the background sync and waits for it — for pull-to-refresh,
  /// where the user expects the spinner to reflect real completion rather
  /// than an instant, still-stale return.
  Future<void> refresh() async {
    final storeId = ref.read(currentStoreIdProvider);
    if (storeId == null) return;
    state = const AsyncLoading<List<InventoryItem>>().copyWithPrevious(state);
    await _sync.syncCatalog(storeId: storeId);
    await _sync.syncStockLevels(storeId: storeId);
    state = AsyncData(await _loadFromCache(storeId));
  }

  /// Creates a new item via the API, then refreshes. Falls back to a purely
  /// local insert when there's no store context (demo/mock mode) so the
  /// "Add item" form keeps working in that mode too.
  Future<void> upsert(InventoryItem item) async {
    final storeId = ref.read(currentStoreIdProvider);
    if (storeId == null) {
      final current = state.valueOrNull ?? const <InventoryItem>[];
      final index = current.indexWhere((i) => i.id == item.id);
      final next = [...current];
      if (index == -1) {
        next.insert(0, item);
      } else {
        next[index] = item;
      }
      state = AsyncData(next);
      return;
    }

    final sellingPrice = item.sellingPrice == null
        ? null
        : Decimal.parse(item.sellingPrice.toString());

    if (item.catalogItemId == null) {
      await _api.createItem(
        businessId: _businessId,
        storeId: storeId,
        name: item.name,
        unitOfMeasure: _unitOfMeasureCode(item.unit),
        itemType: item.itemType,
        reorderThreshold: Decimal.parse(item.reorderLevel.toString()),
        reorderQuantity: Decimal.parse(item.reorderQuantity.toString()),
        category: item.categoryId,
        unitCost: Decimal.parse(item.unitCost.toString()),
        sellingPrice: sellingPrice,
        allowNegativeStock: item.allowNegativeStock,
      );
    } else {
      await _api.updateItem(
        businessId: _businessId,
        itemId: item.catalogItemId!,
        name: item.name,
        unitOfMeasure: _unitOfMeasureCode(item.unit),
        category: item.categoryId,
        reorderThreshold: Decimal.parse(item.reorderLevel.toString()),
        reorderQuantity: Decimal.parse(item.reorderQuantity.toString()),
        unitCost: Decimal.parse(item.unitCost.toString()),
        sellingPrice: sellingPrice,
        allowNegativeStock: item.allowNegativeStock,
        itemType: item.itemType,
      );
    }
    await refresh();
  }

  Future<void> delete(String id) async {
    final storeId = ref.read(currentStoreIdProvider);
    final item = byId(id);
    if (storeId == null || item?.catalogItemId == null) {
      state = AsyncData(
        (state.valueOrNull ?? const <InventoryItem>[]).where((i) => i.id != id).toList(),
      );
      return;
    }
    await _api.deactivateItem(businessId: _businessId, itemId: item!.catalogItemId!);
    await refresh();
  }

  /// Applies a relative change via a manual stock adjustment. [reason] must
  /// be at least 3 characters (the backend rejects anything shorter).
  Future<void> adjustStock(String id, double delta, {String reason = 'Manual count'}) async {
    final storeId = ref.read(currentStoreIdProvider);
    final item = byId(id);
    if (storeId == null || item?.catalogItemId == null) {
      _applyLocalDelta(id, delta);
      return;
    }
    await _api.adjustStock(
      businessId: _businessId,
      itemId: item!.catalogItemId!,
      quantityDelta: Decimal.parse(delta.toString()),
      reason: reason,
    );
    await refresh();
  }

  /// Sets stock to an absolute value by adjusting the delta from the current
  /// count — Inventory Service only exposes a relative adjustment endpoint.
  Future<void> setStock(String id, double value, {String reason = 'Manual count'}) async {
    final current = byId(id)?.stock ?? 0;
    await adjustStock(id, value - current, reason: reason);
  }

  /// Records wasted/spoiled stock. Requires `inventory.waste.record`.
  Future<void> recordWaste(String id, double quantity, {required String reason}) async {
    final storeId = ref.read(currentStoreIdProvider);
    final item = byId(id);
    if (storeId == null || item?.catalogItemId == null) {
      _applyLocalDelta(id, -quantity);
      return;
    }
    await _api.recordWaste(
      businessId: _businessId,
      itemId: item!.catalogItemId!,
      quantity: Decimal.parse(quantity.toString()),
      reason: reason,
    );
    await refresh();
  }

  /// Transfers stock from the current store to [destinationStoreId]. Requires
  /// `inventory.transfer`.
  Future<void> transferStock(
    String id,
    double quantity, {
    required String destinationStoreId,
  }) async {
    final storeId = ref.read(currentStoreIdProvider);
    final item = byId(id);
    if (storeId == null || item?.catalogItemId == null) {
      _applyLocalDelta(id, -quantity);
      return;
    }
    await _api.transferStock(
      businessId: _businessId,
      itemId: item!.catalogItemId!,
      sourceStoreId: storeId,
      destinationStoreId: destinationStoreId,
      quantity: Decimal.parse(quantity.toString()),
    );
    await refresh();
  }

  void _applyLocalDelta(String id, double delta) {
    state = AsyncData([
      for (final item in state.valueOrNull ?? const <InventoryItem>[])
        if (item.id == id)
          item.copyWith(
            stock: (item.stock + delta).clamp(0, double.infinity),
            lastCountedAt: DateTime.now(),
          )
        else
          item,
    ]);
  }

  String _unitOfMeasureCode(String displayUnit) => switch (displayUnit) {
        'kg' => 'kg',
        'g' => 'g',
        'L' => 'l',
        'ml' => 'ml',
        'pack' => 'pack',
        _ => 'unit',
      };

  InventoryItem? byId(String id) {
    for (final item in state.valueOrNull ?? const <InventoryItem>[]) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Continues the inv-## sequence from the highest existing id — only
  /// meaningful in demo/mock mode; real items get their id from the server.
  String nextId() {
    var highest = 0;
    for (final item in state.valueOrNull ?? const <InventoryItem>[]) {
      final n = int.tryParse(item.id.split('-').last);
      if (n != null && n > highest) highest = n;
    }
    return 'inv-${(highest + 1).toString().padLeft(2, '0')}';
  }
}

final inventoryItemsProvider =
    AsyncNotifierProvider<InventoryNotifier, List<InventoryItem>>(
      InventoryNotifier.new,
    );

/// The list, unwrapped for widgets that only ever want to render what's
/// currently known (cached or demo data) without handling loading/error
/// states themselves — mirrors the idiom used for roles/staff.
final inventoryItemsListProvider = Provider<List<InventoryItem>>(
  (ref) => ref.watch(inventoryItemsProvider).valueOrNull ?? const [],
);

/// The Groceries view's source list — every item except a pure `sellable`
/// one. This is the UI/query-level split the Inventory section is built on:
/// the backend items table and its `item_type` column are untouched, only
/// this filter decides what each of the two screens shows.
final groceryItemsProvider = Provider<List<InventoryItem>>(
  (ref) => [
    for (final item in ref.watch(inventoryItemsListProvider))
      if (item.isGroceryItem) item,
  ],
);

/// The Menu Items view's source list — every item except a pure
/// `raw_material` one. A `both` item (bought and resold unchanged) appears
/// here *and* in [groceryItemsProvider] — that duplication is intentional,
/// not a bug: the item genuinely belongs in both views.
final menuCatalogItemsProvider = Provider<List<InventoryItem>>(
  (ref) => [
    for (final item in ref.watch(inventoryItemsListProvider))
      if (item.isMenuCatalogItem) item,
  ],
);

// ---------------------------------------------------------------------------
// Search / sort / pagination — Groceries
// ---------------------------------------------------------------------------

final inventoryQueryProvider = NotifierProvider<TableQueryNotifier, TableQuery>(
  () => TableQueryNotifier(
    const TableQuery(sortField: InventorySort.name, pageSize: 8),
  ),
);

// ---------------------------------------------------------------------------
// Filters — Groceries
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
  final double? minStock;
  final double? maxStock;

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
    double? minStock,
    double? maxStock,
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

  void setStockRange(double? min, double? max) {
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

/// Highest stock count among grocery items, so the range filter can bound its
/// inputs instead of guessing a maximum.
final inventoryStockCeilingProvider = Provider<double>((ref) {
  var highest = 0.0;
  for (final item in ref.watch(groceryItemsProvider)) {
    if (item.stock > highest) highest = item.stock;
  }
  return highest;
});

// ---------------------------------------------------------------------------
// Derived views — Groceries
// ---------------------------------------------------------------------------

/// Search + filters + sort over [groceryItemsProvider], composed in one
/// place. The screen never sees an unfiltered list, and no filtering logic
/// lives in the widget tree.
final filteredInventoryProvider = Provider<List<InventoryItem>>((ref) {
  final items = ref.watch(groceryItemsProvider);
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
      InventorySort.reorderLevel => a.reorderLevel.compareTo(b.reorderLevel),
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

/// Computed over the whole grocery list, not the current filter, so the
/// header stays a stable "how are we doing" readout while the user filters
/// below it. [InventorySummary.totalValue] sums `stock × unitCost` — the
/// last-known cost basis already carried on every item — so the "total
/// estimated stock value" stat is real data, not a placeholder.
final inventorySummaryProvider = Provider<InventorySummary>((ref) {
  final items = ref.watch(groceryItemsProvider);

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

// ---------------------------------------------------------------------------
// Search / sort / pagination — Menu Items
// ---------------------------------------------------------------------------

abstract final class MenuItemSort {
  static const name = 'name';
  static const category = 'category';
  static const price = 'price';
}

final menuItemsQueryProvider = NotifierProvider<TableQueryNotifier, TableQuery>(
  () => TableQueryNotifier(
    const TableQuery(sortField: MenuItemSort.name, pageSize: 8),
  ),
);

// ---------------------------------------------------------------------------
// Filters — Menu Items
// ---------------------------------------------------------------------------

/// Menu Items' filter state. Deliberately lighter than [InventoryFilters] —
/// stock status and stock-quantity range describe a stockroom line, not a
/// till item, so only category applies here.
@immutable
class MenuItemFilters {
  const MenuItemFilters({this.categoryIds = const {}});

  final Set<String> categoryIds;

  int get activeCount => categoryIds.length;

  bool matches(InventoryItem item) =>
      categoryIds.isEmpty || categoryIds.contains(item.categoryId);

  MenuItemFilters copyWith({Set<String>? categoryIds}) =>
      MenuItemFilters(categoryIds: categoryIds ?? this.categoryIds);
}

class MenuItemFiltersNotifier extends Notifier<MenuItemFilters> {
  @override
  MenuItemFilters build() => const MenuItemFilters();

  void toggleCategory(String id) {
    final next = Set<String>.of(state.categoryIds);
    next.contains(id) ? next.remove(id) : next.add(id);
    state = state.copyWith(categoryIds: next);
    ref.read(menuItemsQueryProvider.notifier).resetPage();
  }

  void clear() {
    state = const MenuItemFilters();
    ref.read(menuItemsQueryProvider.notifier).resetPage();
  }
}

final menuItemFiltersProvider =
    NotifierProvider<MenuItemFiltersNotifier, MenuItemFilters>(
      MenuItemFiltersNotifier.new,
    );

// ---------------------------------------------------------------------------
// Derived views — Menu Items
// ---------------------------------------------------------------------------

final filteredMenuCatalogProvider = Provider<List<InventoryItem>>((ref) {
  final items = ref.watch(menuCatalogItemsProvider);
  final query = ref.watch(menuItemsQueryProvider);
  final filters = ref.watch(menuItemFiltersProvider);
  final search = query.search.trim().toLowerCase();

  final rows = items.where((item) {
    if (!filters.matches(item)) return false;
    if (search.isEmpty) return true;
    return item.name.toLowerCase().contains(search) ||
        item.sku.toLowerCase().contains(search) ||
        MockInventory.categoryLabel(item.categoryId)
            .toLowerCase()
            .contains(search);
  }).toList();

  final direction = query.ascending ? 1 : -1;
  rows.sort((a, b) {
    final cmp = switch (query.sortField) {
      MenuItemSort.category => MockInventory.categoryLabel(
        a.categoryId,
      ).compareTo(MockInventory.categoryLabel(b.categoryId)),
      MenuItemSort.price => (a.sellingPrice ?? 0).compareTo(
        b.sellingPrice ?? 0,
      ),
      _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    };
    return cmp != 0 ? cmp * direction : a.id.compareTo(b.id);
  });

  return rows;
});

final menuItemsSliceProvider = Provider<PageSlice<InventoryItem>>(
  (ref) => PageSlice.of(
    ref.watch(filteredMenuCatalogProvider),
    ref.watch(menuItemsQueryProvider),
  ),
);
