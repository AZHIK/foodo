/// Syncs suppliers and reorders from Inventory Service and caches them
/// locally.
///
/// `PurchasingSyncService` pulls the supplier directory and a store's
/// reorders, upserting into `CachedSuppliers`/`CachedReorders`. Mirrors
/// `CatalogSyncService`'s shape but kept as its own class rather than
/// folded into it — that class's constructor is keyed to a single
/// `InventoryCatalogApi`, and adding two more unrelated API dependencies to
/// it would widen every existing call site for a feature that doesn't need
/// them.
library;

import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'reorders_catalog_api.dart';
import 'suppliers_catalog_api.dart';

class PurchasingSyncService {
  final AppDatabase _db;
  final SuppliersCatalogApi _suppliersApi;
  final ReordersCatalogApi _reordersApi;

  DateTime? lastSyncTime;
  String? lastSyncError;

  PurchasingSyncService({
    required AppDatabase db,
    required SuppliersCatalogApi suppliersApi,
    required ReordersCatalogApi reordersApi,
  })  : _db = db,
        _suppliersApi = suppliersApi,
        _reordersApi = reordersApi;

  /// Pulls the full supplier directory and upserts into cache. Suppliers
  /// have no soft-delete-on-missing logic to run here — deletion is a
  /// server-side flag (`isDeleted`) already present on every pulled row,
  /// always requested via `include_deleted=true`.
  Future<void> syncSuppliers() async {
    final runStartedAt = DateTime.now();
    lastSyncError = null;

    try {
      final suppliers = await _suppliersApi.fetchSuppliers();

      for (final supplier in suppliers) {
        await _db.into(_db.cachedSuppliers).insertOnConflictUpdate(
          CachedSuppliersCompanion(
            id: Value(supplier.id),
            businessId: Value(supplier.businessId),
            name: Value(supplier.name),
            phone: Value(supplier.phone),
            email: Value(supplier.email),
            addressLine1: Value(supplier.addressLine1),
            notes: Value(supplier.notes),
            updatedAt: Value(supplier.updatedAt),
            isDeleted: Value(supplier.isDeleted),
            createdAt: Value(supplier.createdAt),
            lastSyncedAt: Value(runStartedAt),
          ),
        );
      }

      lastSyncTime = DateTime.now();
    } catch (e) {
      lastSyncError = e.toString();
    }
  }

  /// Pulls all reorders for a store and upserts into cache. No missing-row
  /// handling either — a reorder is never deleted server-side (see
  /// `models/reorders.py`'s module docstring), only transitions status.
  Future<void> syncReorders({required String storeId}) async {
    final runStartedAt = DateTime.now();
    lastSyncError = null;

    try {
      final reorders = await _reordersApi.fetchReorders(storeId: storeId);

      for (final reorder in reorders) {
        await _db.into(_db.cachedReorders).insertOnConflictUpdate(
          CachedReordersCompanion(
            id: Value(reorder.id),
            businessId: Value(reorder.businessId),
            storeId: Value(reorder.storeId),
            itemId: Value(reorder.itemId),
            supplierId: Value(reorder.supplierId),
            quantity: Value(reorder.quantity),
            unit: Value(reorder.unit),
            unitCost: Value(reorder.unitCost),
            status: Value(reorder.status),
            notes: Value(reorder.notes),
            orderedAt: Value(reorder.orderedAt),
            orderedBy: Value(reorder.orderedBy),
            expectedAt: Value(reorder.expectedAt),
            receivedAt: Value(reorder.receivedAt),
            receivedBy: Value(reorder.receivedBy),
            cancelledAt: Value(reorder.cancelledAt),
            cancelledBy: Value(reorder.cancelledBy),
            createdAt: Value(reorder.createdAt),
            lastSyncedAt: Value(runStartedAt),
          ),
        );
      }

      lastSyncTime = DateTime.now();
    } catch (e) {
      lastSyncError = e.toString();
    }
  }
}
