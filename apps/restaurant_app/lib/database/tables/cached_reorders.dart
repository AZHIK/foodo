/// Reorders (restock purchase orders) cached from Inventory Service.
///
/// `CachedReorders` mirrors the backend's `ReorderRead` schema (from
/// `services/inventory-service/app/schemas/reorders.py`) — a pull-only read
/// cache, store-scoped like `CachedItems`/`CachedStockLevels`. Writes
/// (create/receive/cancel) go direct to the API — see
/// `cached_suppliers.dart`'s doc comment for why there is no outbox here.
///
/// No soft-delete: a reorder is an append-only purchase record with state
/// transitions (`status` moves pending -> received/cancelled and never
/// moves again, mirroring `CachedSales`, not `CachedCustomers`), so every
/// row a pull returns stays in the cache permanently.
library;

import 'package:drift/drift.dart';
import '../converters/decimal_converter.dart';

/// Reorders cached from Inventory Service.
class CachedReorders extends Table {
  /// Reorder UUID (primary key), server-assigned.
  TextColumn get id => text()();

  TextColumn get businessId => text()();
  TextColumn get storeId => text()();
  TextColumn get itemId => text()();
  TextColumn get supplierId => text()();

  TextColumn get quantity => text().map(const DecimalConverter())();
  TextColumn get unit => text()();
  TextColumn get unitCost => text().map(const DecimalConverter())();

  /// `pending` | `received` | `cancelled`.
  TextColumn get status => text()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get orderedAt => dateTime()();
  TextColumn get orderedBy => text().nullable()();
  DateTimeColumn get expectedAt => dateTime().nullable()();
  DateTimeColumn get receivedAt => dateTime().nullable()();
  TextColumn get receivedBy => text().nullable()();
  DateTimeColumn get cancelledAt => dateTime().nullable()();
  TextColumn get cancelledBy => text().nullable()();

  /// Backend creation timestamp.
  DateTimeColumn get createdAt => dateTime()();

  /// Local timestamp of the most recent pull that included this row.
  DateTimeColumn get lastSyncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
