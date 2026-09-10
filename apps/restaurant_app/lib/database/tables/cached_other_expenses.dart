/// Other-expense entries cached from POS Service, for offline reads and
/// cross-device propagation of edits/deletes.
///
/// `CachedOtherExpenses` mirrors the backend's `OtherExpenseRead` schema
/// (from `services/pos-service/app/schemas/finance.py`) — a pull-only read
/// cache, the finance-side analogue of `CachedSales`. Unlike `CachedSales`,
/// rows here CAN be soft-deleted server-side (`isDeleted`); the pull always
/// requests `include_deleted=true` so a delete made on one device removes
/// the entry from every other device's list on next sync
/// (`FinanceLedgerSyncService` mirrors `isDeleted` into this column rather
/// than dropping the row, and the UI filters `isDeleted` rows out).
///
/// `id` is the server-assigned `OtherExpense.id` (UUID) — the primary key
/// here is the real backend identity, not the client-generated
/// `clientExpenseId` (kept alongside it only as the idempotency key that
/// produced this row).
library;

import 'package:drift/drift.dart';
import '../converters/decimal_converter.dart';

/// Other-expense entries cached from POS Service.
class CachedOtherExpenses extends Table {
  /// Expense UUID, assigned by POS Service (primary key).
  TextColumn get id => text()();

  /// Business this expense belongs to.
  TextColumn get businessId => text()();

  /// Store/location this expense belongs to.
  TextColumn get storeId => text()();

  /// Client-generated idempotency key this expense was created from.
  TextColumn get clientExpenseId => text()();

  TextColumn get category => text()();

  TextColumn get amount => text().map(const DecimalConverter())();

  TextColumn get description => text()();

  TextColumn get payee => text().nullable()();

  TextColumn get note => text().nullable()();

  /// Payment method: `cash`, `mobile_money`, `card`, or `other`.
  TextColumn get paymentMethod => text()();

  TextColumn get receiptAttachmentId => text().nullable()();

  /// Staff member who recorded the expense, if known.
  TextColumn get actorId => text().nullable()();

  /// When the expense occurred (device-reported time, UTC).
  DateTimeColumn get occurredAt => dateTime()();

  /// When POS Service accepted this expense.
  DateTimeColumn get syncedAt => dateTime()();

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
