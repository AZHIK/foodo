/// Source of reorders, backed by Inventory Service once a store context
/// exists.
///
/// Same no-outbox, stale-while-revalidate contract as
/// `InventoryNotifier`/`SuppliersNotifier` — see `suppliers_provider.dart`'s
/// doc comment. Store-scoped (unlike `SuppliersNotifier`, which is
/// business-scoped): receiving a reorder credits a specific store's stock,
/// the same reasoning `InventoryNotifier` itself keys off
/// `currentStoreIdProvider`.
library;

import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_reorders.dart';
import '../models/reorder.dart';
import '../sync/purchasing_mapper.dart';
import 'database_providers.dart';
import 'inventory_api_provider.dart';
import 'permissions_provider.dart';

/// Sort/filter field keys for the reorders list, if a table view is added
/// later — kept for symmetry with `CustomerSort`/`InventorySort` even
/// though today's `ReordersScreen` is a grouped list, not a data table.
abstract final class ReorderSort {
  static const orderedAt = 'orderedAt';
  static const expectedAt = 'expectedAt';
}

class ReordersNotifier extends AsyncNotifier<List<Reorder>> {
  @override
  Future<List<Reorder>> build() async {
    final storeId = ref.watch(currentStoreIdProvider);
    if (storeId == null) return List.of(MockReorders.list);

    var disposed = false;
    ref.onDispose(() => disposed = true);
    unawaited(_refreshFromApi(storeId, isDisposed: () => disposed));

    return _loadFromCache(storeId);
  }

  Future<void> _refreshFromApi(String storeId, {required bool Function() isDisposed}) async {
    try {
      await ref.read(purchasingSyncServiceProvider).syncReorders(storeId: storeId);
      if (!isDisposed()) {
        state = AsyncData(await _loadFromCache(storeId));
      }
    } catch (_) {
      // Offline, no permission, or a transient failure — the cached read
      // from `build()` already reflects the last known-good state.
    }
  }

  Future<List<Reorder>> _loadFromCache(String storeId) async {
    final db = ref.read(appDatabaseProvider);
    final rows =
        await (db.select(db.cachedReorders)..where((row) => row.storeId.equals(storeId))).get();
    final reorders = rows.map(reorderFromCachedRow).toList();
    reorders.sort((a, b) => b.orderedAt.compareTo(a.orderedAt));
    return reorders;
  }

  /// Re-runs sync and waits for it — for a manual refresh action. A no-op
  /// with no store context (demo mode has nothing to pull).
  Future<void> refresh() async {
    final storeId = ref.read(currentStoreIdProvider);
    if (storeId == null) return;
    state = const AsyncLoading<List<Reorder>>().copyWithPrevious(state);
    await ref.read(purchasingSyncServiceProvider).syncReorders(storeId: storeId);
    state = AsyncData(await _loadFromCache(storeId));
  }

  /// Places a new reorder for [itemId] from [supplierId].
  Future<Reorder> create({
    required String itemId,
    required String supplierId,
    required double quantity,
    required String unit,
    required double unitCost,
    String? notes,
    DateTime? expectedAt,
  }) async {
    final storeId = ref.read(currentStoreIdProvider);
    final current = state.valueOrNull ?? const <Reorder>[];

    if (storeId == null) {
      final reorder = Reorder(
        id: MockReorders.nextId(current),
        storeId: 'store-demo',
        inventoryItemId: itemId,
        quantity: quantity,
        unit: unit,
        unitCost: unitCost,
        supplierId: supplierId,
        orderedAt: DateTime.now(),
        expectedAt: expectedAt,
        notes: notes,
      );
      state = AsyncData([reorder, ...current]);
      return reorder;
    }

    final businessId = ref.read(currentBusinessIdProvider)!;
    final created = await ref.read(reorderApiServiceProvider).createReorder(
          businessId: businessId,
          storeId: storeId,
          itemId: itemId,
          supplierId: supplierId,
          quantity: Decimal.parse(quantity.toString()),
          unitCost: Decimal.parse(unitCost.toString()),
          notes: notes,
          expectedAt: expectedAt,
        );
    await refresh();
    return (state.valueOrNull ?? const <Reorder>[])
        .firstWhere((r) => r.id == created.id);
  }

  /// Marks [reorder] received — adds its quantity to stock. Demo mode has
  /// no stock engine to run, so it just flips the local status.
  Future<Reorder> receive(Reorder reorder) async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null) {
      final updated = reorder.copyWith(
        status: ReorderStatus.received,
        receivedAt: DateTime.now(),
      );
      _replaceInState(updated);
      return updated;
    }

    await ref.read(reorderApiServiceProvider).receiveReorder(
          businessId: businessId,
          reorderId: reorder.id,
        );
    await refresh();
    return (state.valueOrNull ?? const <Reorder>[]).firstWhere((r) => r.id == reorder.id);
  }

  /// Cancels [reorder]. Demo mode just flips the local status.
  Future<Reorder> cancel(Reorder reorder) async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null) {
      final updated = reorder.copyWith(
        status: ReorderStatus.cancelled,
        cancelledAt: DateTime.now(),
      );
      _replaceInState(updated);
      return updated;
    }

    await ref.read(reorderApiServiceProvider).cancelReorder(
          businessId: businessId,
          reorderId: reorder.id,
        );
    await refresh();
    return (state.valueOrNull ?? const <Reorder>[]).firstWhere((r) => r.id == reorder.id);
  }

  void _replaceInState(Reorder reorder) {
    final current = state.valueOrNull ?? const <Reorder>[];
    state = AsyncData([
      for (final r in current) if (r.id == reorder.id) reorder else r,
    ]);
  }
}

final reordersProvider =
    AsyncNotifierProvider<ReordersNotifier, List<Reorder>>(ReordersNotifier.new);

/// The list, unwrapped.
final reordersListProvider = Provider<List<Reorder>>(
  (ref) => ref.watch(reordersProvider).valueOrNull ?? const [],
);

/// Active (pending) reorders sorted by expected arrival.
final activeReordersProvider = Provider<List<Reorder>>((ref) {
  final all = ref.watch(reordersListProvider);
  final active = all.where((r) => r.status == ReorderStatus.pending).toList();
  active.sort((a, b) {
    final aExp = a.expectedAt ?? DateTime(2099);
    final bExp = b.expectedAt ?? DateTime(2099);
    return aExp.compareTo(bExp);
  });
  return active;
});

/// Lookup reorders by inventory item id.
final reordersByItemProvider = Provider.family<List<Reorder>, String>((ref, itemId) {
  return ref
      .watch(reordersListProvider)
      .where((r) => r.inventoryItemId == itemId)
      .toList();
});
