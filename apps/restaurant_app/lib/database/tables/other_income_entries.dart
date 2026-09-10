/// Recorded other income (money coming in), not from a POS sale.
///
/// `OtherIncomeEntries` mirrors `ExpenseEntries`'s outbox shape (and, as of
/// schema v6, its edit/delete-after-sync support), but is kept as its own
/// table rather than a signed-amount row in `ExpenseEntries`: income and
/// expense have different category lists and different reporting/
/// permission treatment.
library;

import 'package:drift/drift.dart';
import '../converters/decimal_converter.dart';

/// Recorded other income (money coming in), not from a POS sale.
class OtherIncomeEntries extends Table {
  /// Local row ID (autoincrement).
  IntColumn get id => integer().autoIncrement()();

  /// Client-side idempotency key (UUID v4, unique).
  TextColumn get incomeId => text().unique()();

  /// Business this income belongs to.
  TextColumn get businessId => text()();

  /// Store/location this income belongs to. Matches POS Service's
  /// `other_incomes.store_id` field (renamed from `businessLocationId`
  /// by schema v6, mirroring `PendingSales`'s own v5 rename).
  TextColumn get storeId => text()();

  /// Income category. Controlled list, not free text — canonical list
  /// (mirrors
  /// `services/pos-service/app/models/finance.py::IncomeCategory`):
  /// catering|grants|rebates|space_rental|equipment_rental|other.
  TextColumn get category => text()();

  /// Income amount.
  TextColumn get amount => text().map(const DecimalConverter())();

  /// Free-text description.
  TextColumn get description => text().nullable()();

  /// Who/what the income came from.
  TextColumn get source => text().nullable()();

  /// Optional free-text note.
  TextColumn get note => text().nullable()();

  /// Payment method used: cash|mobile_money|card|other.
  TextColumn get paymentMethod =>
      text().withDefault(const Constant('other'))();

  /// Server-assigned id of the uploaded receipt (`FinanceAttachment.id`).
  TextColumn get receiptAttachmentId => text().nullable()();

  /// Device-local path to a receipt file awaiting upload. See
  /// `ExpenseEntries.localReceiptPath`.
  TextColumn get localReceiptPath => text().nullable()();

  /// When the income occurred (device time, UTC).
  DateTimeColumn get occurredAt => dateTime()();

  /// Staff member who recorded the income.
  /// Soft-references `LocalUserProfiles.id` without an FK constraint, same
  /// rationale as `ExpenseEntries.actorUserId`.
  TextColumn get actorUserId => text()();

  /// Server-assigned id (`OtherIncome.id`), set once this row has synced.
  TextColumn get serverId => text().nullable()();

  /// Local sync state: `pending`, `syncing`, `failed`, `synced`.
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();

  /// Error message from the last sync attempt, if any.
  TextColumn get syncError => text().nullable()();

  /// Number of times this entry has been attempted.
  IntColumn get syncAttemptCount => integer().withDefault(const Constant(0))();

  /// Timestamp of the last sync attempt.
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  /// When the entry was successfully synced to the backend.
  DateTimeColumn get syncedAt => dateTime().nullable()();

  /// Local row creation timestamp.
  DateTimeColumn get createdAt => dateTime()();
}
