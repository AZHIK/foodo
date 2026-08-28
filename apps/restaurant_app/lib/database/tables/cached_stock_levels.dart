/// Local cache of item stock quantities, for display only.
///
/// `CachedStockLevels` is a pull-only, deliberately low-trust cache from
/// Inventory Service: it's a display hint (e.g. "12 left" on a POS tile),
/// never a reservation. The authoritative stock check and decrement happen
/// server-side when a sale eventually syncs, so this table is never read
/// to block or validate an offline sale.
///
/// The `itemId` soft-references `CachedItems.id` **without an FK
/// constraint**, matching `PendingSaleLineItems` (see that table's
/// comments for rationale): a stock-level row for an item that has since
/// gone `isActive = false` in the catalog should not be blocked from
/// being written or cleared.
library;

import 'package:drift/drift.dart';
import '../converters/decimal_converter.dart';

/// Local cache of item stock quantities, for display only.
class CachedStockLevels extends Table {
  /// Item UUID from the inventory catalog.
  /// Soft-references `CachedItems.id` without an FK constraint
  /// (see `CachedItems` for rationale).
  TextColumn get itemId => text()();

  /// Business location this stock level applies to.
  TextColumn get businessLocationId => text()();

  /// Current on-hand quantity, as last reported by the server.
  TextColumn get currentQuantity => text().map(const DecimalConverter())();

  /// When this stock level was last refreshed from the server.
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {itemId, businessLocationId};
}
