/// Suppliers cached from Inventory Service, for the Suppliers screen and
/// the reorder dialog's supplier picker.
///
/// `CachedSuppliers` mirrors the backend's `SupplierRead` schema (from
/// `services/inventory-service/app/schemas/suppliers.py`) — a pull-only read
/// cache. Unlike `CachedCustomers`/`CachedItems`, supplier writes go direct
/// to the API (no offline outbox) — see `suppliers_provider.dart`'s doc
/// comment for why, mirroring `InventoryNotifier`'s own no-outbox
/// convention rather than the Finance/Customers pattern.
///
/// Rows CAN be soft-deleted server-side (`isDeleted`); the pull always
/// requests `include_deleted=true` so a delete made on one device removes
/// the supplier from every other device's list on next sync — a past
/// `Reorder`'s `supplierId` still resolves via this table even after that.
library;

import 'package:drift/drift.dart';

/// Suppliers cached from Inventory Service.
class CachedSuppliers extends Table {
  /// Supplier UUID (primary key), server-assigned.
  TextColumn get id => text()();

  /// Business this supplier belongs to.
  TextColumn get businessId => text()();

  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get addressLine1 => text().nullable()();
  TextColumn get notes => text().nullable()();

  /// Last-edited timestamp (server-computed).
  DateTimeColumn get updatedAt => dateTime()();

  /// Soft-delete flag — see class doc for why deleted rows are still pulled.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// Backend creation timestamp.
  DateTimeColumn get createdAt => dateTime()();

  /// Local timestamp of the most recent pull that included this row.
  DateTimeColumn get lastSyncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
