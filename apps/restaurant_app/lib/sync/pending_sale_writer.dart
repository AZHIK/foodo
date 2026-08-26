/// Writes completed orders to the PendingSales table for sync.
///
/// After `orders_provider.dart`'s `placeOrder()` creates an Order,
/// `PendingSaleWriter` converts it to a `PendingSales` + `PendingSaleLineItems`
/// row so it can be synced to the backend. If the order's items don't resolve
/// to valid catalog items, the entire sale is skipped (never partial/wrong).
library;

import 'package:decimal/decimal.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/order.dart';

/// Writes orders to the pending-sales sync table.
class PendingSaleWriter {
  final AppDatabase _db;

  PendingSaleWriter(this._db);

  /// Converts an Order to PendingSales + LineItems if all items resolve.
  ///
  /// Returns true if written, false if skipped (items couldn't resolve).
  /// Skipped orders remain in memory as local Orders (visible on screens)
  /// but don't get synced — intentional until the id-chain is real.
  Future<bool> writeIfMappable(Order order) async {
    // For this MVP: placeholder logic that doesn't write yet.
    // Real implementation: resolve order.lines[].itemId → inventoryItem.catalogItemId
    // If all resolve, write. If any fail, return false (skip whole order).
    //
    // Actual sync will be triggered once the MenuItem→InventoryItem→CachedItems
    // id chain is populated in mock data.

    return false; // Placeholder: skip all writes for now.
  }
}
