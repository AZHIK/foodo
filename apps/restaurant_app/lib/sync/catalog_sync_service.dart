/// Syncs the item catalog from Inventory Service and caches it locally.
///
/// `CatalogSyncService` pulls the full item list for the current business location,
/// upserts into `CachedItems` (insert new, update changed), and soft-deletes items
/// no longer in the source (marking `isActive = false` rather than row-deleting,
/// to preserve references from completed sales).
library;

import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'inventory_catalog_api.dart';

/// Syncs the inventory catalog into local cache.
class CatalogSyncService {
  final AppDatabase _db;
  final InventoryCatalogApi _api;

  /// Timestamp of the last successful catalog sync.
  DateTime? lastSyncTime;

  /// Error from the last sync attempt, if any.
  String? lastSyncError;

  CatalogSyncService({
    required this._db,
    required InventoryCatalogApi api,
  })  : _api = api;

  /// Pulls the full catalog for a business location and upserts into cache.
  ///
  /// - Fetches all items from the API.
  /// - Upserts each: insert if new id, update if `updatedAtServer` changed.
  /// - Marks items not in the new pull as inactive (soft-delete).
  Future<void> syncCatalog({required String businessLocationId}) async {
    final runStartedAt = DateTime.now();
    lastSyncError = null;

    try {
      // Fetch the full catalog.
      final items = await _api.fetchItems(
        businessLocationId: businessLocationId,
      );

      // Track which item IDs we saw in this pull.
      final seenIds = <String>{};

      // Upsert all fetched items.
      for (final item in items) {
        seenIds.add(item.id);
        await _db.into(_db.cachedItems).insertOnConflictUpdate(
          CachedItemsCompanion(
            id: Value(item.id),
            businessId: Value(item.businessId),
            businessLocationId: Value(item.businessLocationId),
            name: Value(item.name),
            unitOfMeasure: Value(item.unitOfMeasure),
            category: Value(item.category),
            reorderThreshold: Value(item.reorderThreshold),
            reorderQuantity: Value(item.reorderQuantity),
            sellingPrice: Value(item.sellingPrice),
            allowNegativeStock: Value(item.allowNegativeStock),
            itemType: Value(item.itemType),
            createdAtServer: Value(item.createdAt),
            updatedAtServer: Value(item.updatedAt),
            lastSeenAt: Value(runStartedAt),
            lastSyncedAt: Value(runStartedAt),
          ),
        );
      }

      // Soft-delete items not in this pull (mark inactive).
      final allItems = await _db.select(_db.cachedItems).get();
      for (final item in allItems) {
        if (!seenIds.contains(item.id) && item.isActive) {
          await (_db.update(_db.cachedItems)
                ..where((row) => row.id.equals(item.id)))
              .write(const CachedItemsCompanion(isActive: Value(false)));
        }
      }

      lastSyncTime = DateTime.now();
    } catch (e) {
      lastSyncError = e.toString();
    }
  }
}
