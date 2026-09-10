/// Customers cached from POS Service, for the Customers screen and the
/// checkout picker.
///
/// `CachedCustomers` mirrors the backend's `CustomerRead`/`CustomerListItem`
/// schemas (from `services/pos-service/app/schemas/customers.py`) — a
/// pull-only read cache, the customer-side analogue of `CachedOtherExpenses`.
/// `id` is the server-assigned primary key, which for a customer is the
/// SAME value the device generated when it was created (see
/// `customer_entries.dart`'s doc comment) — there is no separate client id
/// to reconcile.
///
/// `totalOrders`/`totalSpent`/`lastOrderAt` are server-computed
/// aggregates, never derived locally — see
/// `services/pos-service/app/services/customer_service.py`. They reflect
/// whatever was true as of the last successful pull.
///
/// Rows CAN be soft-deleted server-side (`isDeleted`); the pull always
/// requests `include_deleted=true` so a delete made on one device removes
/// the customer from every other device's list on next sync.
library;

import 'package:drift/drift.dart';
import '../converters/decimal_converter.dart';

/// Customers cached from POS Service.
class CachedCustomers extends Table {
  /// Customer UUID — server-assigned, but identical to the id the device
  /// generated when this customer was first created (primary key).
  TextColumn get id => text()();

  /// Business this customer belongs to.
  TextColumn get businessId => text()();

  TextColumn get name => text()();
  TextColumn get phone => text()();
  TextColumn get email => text().nullable()();
  TextColumn get addressLine1 => text().nullable()();

  /// Staff member who added the customer, if known.
  TextColumn get actorId => text().nullable()();

  /// When the customer was added (device-reported time, UTC).
  DateTimeColumn get joinedAt => dateTime()();

  /// When POS Service accepted this customer.
  DateTimeColumn get syncedAt => dateTime()();

  /// Last-edited timestamp (server-computed).
  DateTimeColumn get updatedAt => dateTime()();

  /// Soft-delete flag — see class doc for why deleted rows are still pulled.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// Backend creation timestamp.
  DateTimeColumn get createdAt => dateTime()();

  /// Server-computed order count, from completed sales only.
  IntColumn get totalOrders => integer().withDefault(const Constant(0))();

  /// Server-computed lifetime spend, from completed sales only.
  TextColumn get totalSpent => text().map(const DecimalConverter())();

  /// Server-computed most recent completed-sale timestamp.
  DateTimeColumn get lastOrderAt => dateTime().nullable()();

  /// Local timestamp of the most recent pull that included this row.
  DateTimeColumn get lastSyncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
