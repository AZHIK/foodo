/// Source of the unit-of-measure taxonomy, backed by Inventory Service's
/// global `/units` endpoint once a business context exists.
///
/// Same stale-while-revalidate contract as `CategoriesNotifier`: `build()`
/// never blocks on the network, a background pull refreshes the cache, and
/// there is no create/update/delete here — units are read-only from the
/// app's perspective for now (see
/// `services/inventory-service/app/api/v1/endpoints/units.py`).
library;

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_inventory.dart';
import 'database_providers.dart';
import 'inventory_api_provider.dart';
import 'permissions_provider.dart';

/// A pickable unit of measure — `abbreviation` is what the item form shows
/// and what ends up stored on `InventoryItem.unit`; `id` is what gets sent
/// to the backend as `unit_id` on save.
class InventoryUnit {
  const InventoryUnit({
    required this.id,
    required this.abbreviation,
  });

  final String id;
  final String abbreviation;
}

class UnitsNotifier extends AsyncNotifier<List<InventoryUnit>> {
  @override
  Future<List<InventoryUnit>> build() async {
    final businessId = ref.watch(currentBusinessIdProvider);
    if (businessId == null) {
      // Demo mode has no backend units to resolve against — the id doubles
      // as the abbreviation since it is never sent anywhere.
      return [
        for (final unit in MockInventory.units)
          InventoryUnit(id: unit, abbreviation: unit),
      ];
    }

    var disposed = false;
    ref.onDispose(() => disposed = true);
    unawaited(_refreshFromApi(isDisposed: () => disposed));

    return _loadFromCache();
  }

  Future<void> _refreshFromApi({required bool Function() isDisposed}) async {
    if (ref.read(currentBusinessIdProvider) == null) return;
    try {
      await ref.read(unitsSyncServiceProvider).syncUnits();
      if (!isDisposed()) {
        state = AsyncData(await _loadFromCache());
      }
    } catch (_) {
      // Offline, no permission, or a transient failure — the cached read
      // from `build()` already reflects the last known-good state.
    }
  }

  Future<List<InventoryUnit>> _loadFromCache() async {
    final db = ref.read(appDatabaseProvider);
    final rows = await (db.select(db.cachedUnits)
          ..where((row) => row.isActive.equals(true))
          ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
        .get();
    return [
      for (final row in rows) InventoryUnit(id: row.id, abbreviation: row.abbreviation),
    ];
  }

  /// Re-runs sync and waits for it — for a manual refresh action. A no-op
  /// with no business context (demo mode has nothing to pull).
  Future<void> refresh() async {
    if (ref.read(currentBusinessIdProvider) == null) return;
    state = const AsyncLoading<List<InventoryUnit>>().copyWithPrevious(state);
    await ref.read(unitsSyncServiceProvider).syncUnits();
    state = AsyncData(await _loadFromCache());
  }
}

final unitsProvider =
    AsyncNotifierProvider<UnitsNotifier, List<InventoryUnit>>(UnitsNotifier.new);

/// The list, unwrapped.
final unitsListProvider = Provider<List<InventoryUnit>>(
  (ref) => ref.watch(unitsProvider).valueOrNull ?? const [],
);

/// Resolves a picked abbreviation back to its unit id for the write API —
/// `null` when the abbreviation isn't (or is no longer) a known unit, e.g.
/// stale local state after a taxonomy change.
String? unitIdForAbbreviation(List<InventoryUnit> units, String abbreviation) {
  for (final unit in units) {
    if (unit.abbreviation == abbreviation) return unit.id;
  }
  return null;
}
