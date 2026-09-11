/// Source of the product-category taxonomy, backed by Inventory Service's
/// global `/categories` endpoint once a business context exists.
///
/// Same stale-while-revalidate contract as `SuppliersNotifier`: `build()`
/// never blocks on the network, a background pull refreshes the cache, and
/// there is no create/update/delete here — categories are read-only from the
/// app's perspective for now (see
/// `services/inventory-service/app/api/v1/endpoints/categories.py`).
library;

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_inventory.dart';
import '../models/inventory_item.dart';
import 'database_providers.dart';
import 'inventory_api_provider.dart';
import 'permissions_provider.dart';

/// Icons have no backend equivalent — this is a purely local, decorative
/// lookup by the seeded taxonomy's stable `code`. Falls back to a generic
/// icon for anything the app doesn't recognise (e.g. a category added later
/// that this build predates).
const _iconsByCode = <String, IconData>{
  'produce': Icons.eco_outlined,
  'meat': Icons.set_meal_outlined,
  'dairy': Icons.egg_outlined,
  'dry': Icons.grain_outlined,
  'drinks': Icons.local_bar_outlined,
  'supplies': Icons.inventory_2_outlined,
  'starters': Icons.tapas_outlined,
  'mains': Icons.dinner_dining_outlined,
  'sides': Icons.rice_bowl_outlined,
  'desserts': Icons.icecream_outlined,
};

IconData _iconForCode(String code) => _iconsByCode[code] ?? Icons.category_outlined;

/// Last-known category list, mirrored here so the handful of call sites with
/// no `ref` in scope — `DataColumnSpec.value`, a plain `String Function(T
/// row)` used by table cells, search and exports across the whole app, with
/// no room to thread a `WidgetRef` through its signature — can still resolve
/// a label/icon synchronously. [CategoriesNotifier] keeps this current on
/// every state change; it starts as the demo list so these call sites work
/// correctly even before any widget has read a categories provider yet.
List<InventoryCategory> _latestCategories = List.of(MockInventory.categories);

class CategoriesNotifier extends AsyncNotifier<List<InventoryCategory>> {
  @override
  Future<List<InventoryCategory>> build() async {
    final businessId = ref.watch(currentBusinessIdProvider);
    if (businessId == null) return _publish(List.of(MockInventory.categories));

    var disposed = false;
    ref.onDispose(() => disposed = true);
    unawaited(_refreshFromApi(isDisposed: () => disposed));

    return _publish(await _loadFromCache());
  }

  Future<void> _refreshFromApi({required bool Function() isDisposed}) async {
    if (ref.read(currentBusinessIdProvider) == null) return;
    try {
      await ref.read(categoriesSyncServiceProvider).syncCategories();
      if (!isDisposed()) {
        state = AsyncData(_publish(await _loadFromCache()));
      }
    } catch (_) {
      // Offline, no permission, or a transient failure — the cached read
      // from `build()` already reflects the last known-good state.
    }
  }

  Future<List<InventoryCategory>> _loadFromCache() async {
    final db = ref.read(appDatabaseProvider);
    final rows = await (db.select(db.cachedCategories)
          ..where((row) => row.isActive.equals(true))
          ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
        .get();
    return [
      for (final row in rows)
        InventoryCategory(id: row.id, label: row.name, icon: _iconForCode(row.code)),
    ];
  }

  List<InventoryCategory> _publish(List<InventoryCategory> categories) {
    _latestCategories = categories;
    return categories;
  }

  /// Re-runs sync and waits for it — for a manual refresh action. A no-op
  /// with no business context (demo mode has nothing to pull).
  Future<void> refresh() async {
    if (ref.read(currentBusinessIdProvider) == null) return;
    state = const AsyncLoading<List<InventoryCategory>>().copyWithPrevious(state);
    await ref.read(categoriesSyncServiceProvider).syncCategories();
    state = AsyncData(_publish(await _loadFromCache()));
  }
}

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<InventoryCategory>>(CategoriesNotifier.new);

/// The list, unwrapped.
final categoriesListProvider = Provider<List<InventoryCategory>>(
  (ref) => ref.watch(categoriesProvider).valueOrNull ?? const [],
);

/// Lookup by id — mirrors `MockInventory.categoryById`'s ergonomics so
/// widget call sites change minimally.
InventoryCategory? categoryByIdFrom(List<InventoryCategory> categories, String id) {
  for (final category in categories) {
    if (category.id == id) return category;
  }
  return null;
}

/// Resolves a category id to its display label, falling back to the id
/// itself when unknown — mirrors `MockInventory.categoryLabel`.
String categoryLabelFrom(List<InventoryCategory> categories, String id) =>
    categoryByIdFrom(categories, id)?.label ?? id;

/// Lookup by id, for widgets — `ref.watch(categoryByIdProvider(id))`.
final categoryByIdProvider = Provider.family<InventoryCategory?, String>(
  (ref, id) => categoryByIdFrom(ref.watch(categoriesListProvider), id),
);

/// Synchronous, non-reactive label lookup for call sites with no `ref` in
/// scope — see [_latestCategories]'s doc comment for why this exists
/// alongside [categoryLabelFrom] rather than instead of it.
String categoryLabelForId(String id) => categoryLabelFrom(_latestCategories, id);

/// Synchronous, non-reactive icon lookup — the [categoryLabelForId]
/// counterpart for `DataColumnSpec.cellBuilder`-less table cells that also
/// want an icon.
IconData? categoryIconForId(String id) => categoryByIdFrom(_latestCategories, id)?.icon;
