/// Source of suppliers, backed by Inventory Service once a business context
/// exists.
///
/// Same stale-while-revalidate contract as `InventoryNotifier`: `build()`
/// never blocks on the network, a background pull refreshes the cache, and
/// writes go straight to the API with no offline outbox — Inventory
/// Service's writes have always worked this way (see
/// `InventoryNotifier`'s doc comment in `inventory_provider.dart`), and
/// Suppliers/Reorders follow that same convention rather than the
/// Finance/Customers outbox pattern used elsewhere in this app.
library;

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_suppliers.dart';
import '../models/supplier.dart';
import '../sync/purchasing_mapper.dart';
import 'database_providers.dart';
import 'inventory_api_provider.dart';
import 'permissions_provider.dart';

class SuppliersNotifier extends AsyncNotifier<List<Supplier>> {
  @override
  Future<List<Supplier>> build() async {
    final businessId = ref.watch(currentBusinessIdProvider);
    if (businessId == null) return List.of(MockSuppliers.list);

    var disposed = false;
    ref.onDispose(() => disposed = true);
    unawaited(_refreshFromApi(isDisposed: () => disposed));

    return _loadFromCache(businessId);
  }

  Future<void> _refreshFromApi({required bool Function() isDisposed}) async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null) return;
    try {
      await ref.read(purchasingSyncServiceProvider).syncSuppliers();
      if (!isDisposed()) {
        state = AsyncData(await _loadFromCache(businessId));
      }
    } catch (_) {
      // Offline, no permission, or a transient failure — the cached read
      // from `build()` already reflects the last known-good state.
    }
  }

  Future<List<Supplier>> _loadFromCache(String businessId) async {
    final db = ref.read(appDatabaseProvider);
    final rows = await (db.select(db.cachedSuppliers)
          ..where((row) => row.businessId.equals(businessId) & row.isDeleted.equals(false)))
        .get();
    final suppliers = rows.map(supplierFromCachedRow).toList();
    suppliers.sort((a, b) => a.name.compareTo(b.name));
    return suppliers;
  }

  /// Re-runs sync and waits for it — for a manual refresh action. A no-op
  /// with no business context (demo mode has nothing to pull).
  Future<void> refresh() async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null) return;
    state = const AsyncLoading<List<Supplier>>().copyWithPrevious(state);
    await ref.read(purchasingSyncServiceProvider).syncSuppliers();
    state = AsyncData(await _loadFromCache(businessId));
  }

  Future<Supplier> create({
    required String name,
    String? phone,
    String? email,
    String? addressLine1,
    String? notes,
  }) async {
    final businessId = ref.read(currentBusinessIdProvider);
    final current = state.valueOrNull ?? const <Supplier>[];

    if (businessId == null) {
      final supplier = Supplier(
        id: MockSuppliers.nextId(current),
        name: name,
        phone: phone,
        email: email,
        addressLine1: addressLine1,
        notes: notes,
        createdAt: DateTime.now(),
      );
      state = AsyncData([supplier, ...current]);
      return supplier;
    }

    final dto = await ref.read(supplierApiServiceProvider).createSupplier(
          businessId: businessId,
          name: name,
          phone: phone,
          email: email,
          addressLine1: addressLine1,
          notes: notes,
        );
    await refresh();
    return Supplier(
      id: dto.id,
      name: dto.name,
      phone: dto.phone,
      email: dto.email,
      addressLine1: dto.addressLine1,
      notes: dto.notes,
      createdAt: dto.createdAt,
    );
  }

  Future<Supplier> edit(
    Supplier existing, {
    required String name,
    String? phone,
    String? email,
    String? addressLine1,
    String? notes,
  }) async {
    final businessId = ref.read(currentBusinessIdProvider);
    final updated = existing.copyWith(
      name: name,
      phone: phone,
      clearPhone: phone == null,
      email: email,
      clearEmail: email == null,
      addressLine1: addressLine1,
      clearAddressLine1: addressLine1 == null,
      notes: notes,
      clearNotes: notes == null,
    );

    if (businessId == null) {
      _replaceInState(updated);
      return updated;
    }

    await ref.read(supplierApiServiceProvider).updateSupplier(
          businessId: businessId,
          supplierId: existing.id,
          name: name,
          phone: phone,
          email: email,
          addressLine1: addressLine1,
          notes: notes,
        );
    await refresh();
    return updated;
  }

  Future<void> delete(String id) async {
    final businessId = ref.read(currentBusinessIdProvider);
    final current = state.valueOrNull ?? const <Supplier>[];

    if (businessId == null) {
      state = AsyncData(current.where((s) => s.id != id).toList());
      return;
    }

    await ref.read(supplierApiServiceProvider).deleteSupplier(
          businessId: businessId,
          supplierId: id,
        );
    await refresh();
  }

  void _replaceInState(Supplier supplier) {
    final current = state.valueOrNull ?? const <Supplier>[];
    state = AsyncData([
      for (final s in current) if (s.id == supplier.id) supplier else s,
    ]);
  }
}

final suppliersProvider =
    AsyncNotifierProvider<SuppliersNotifier, List<Supplier>>(SuppliersNotifier.new);

/// The list, unwrapped.
final suppliersListProvider = Provider<List<Supplier>>(
  (ref) => ref.watch(suppliersProvider).valueOrNull ?? const [],
);

/// Lookup by id.
final supplierByIdProvider = Provider.family<Supplier?, String>((ref, id) {
  for (final supplier in ref.watch(suppliersListProvider)) {
    if (supplier.id == id) return supplier;
  }
  return null;
});
