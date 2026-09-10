/// Recorded expenses (money going out), unrelated to a POS sale.
///
/// `ExpenseEntries` follows the same outbox shape as `PendingSales`: an
/// autoincrement local `id` plus a client-generated `expenseId`
/// idempotency key. Unlike a sale, a row here CAN be edited or deleted
/// after creation (via `FinanceSyncService`/`FinanceApiService` — see
/// `lib/providers/other_expenses_provider.dart`), mirroring POS Service's
/// `other_expenses` table, which supports PATCH/soft-delete for the same
/// reason: the shipped UI has real Edit/Delete row actions and no
/// offsetting-entry correction workflow.
library;

import 'package:drift/drift.dart';
import '../converters/decimal_converter.dart';

/// Recorded expenses (money going out), unrelated to a POS sale.
class ExpenseEntries extends Table {
  /// Local row ID (autoincrement).
  IntColumn get id => integer().autoIncrement()();

  /// Client-side idempotency key (UUID v4, unique).
  TextColumn get expenseId => text().unique()();

  /// Business this expense belongs to.
  TextColumn get businessId => text()();

  /// Store/location this expense belongs to. Matches POS Service's
  /// `other_expenses.store_id` field (renamed from `businessLocationId`
  /// by schema v6, mirroring `PendingSales`'s own v5 rename).
  TextColumn get storeId => text()();

  /// Expense category. Controlled list, not free text, so reporting stays
  /// meaningful — canonical list (mirrors
  /// `services/pos-service/app/models/finance.py::ExpenseCategory`):
  /// rent|utilities|salaries|repairs|supplies|marketing|insurance|
  /// professional_fees|other.
  TextColumn get category => text()();

  /// Expense amount.
  TextColumn get amount => text().map(const DecimalConverter())();

  /// Free-text description.
  TextColumn get description => text().nullable()();

  /// Who the expense was paid to.
  TextColumn get payee => text().nullable()();

  /// Optional free-text note.
  TextColumn get note => text().nullable()();

  /// Payment method used: cash|mobile_money|card|other.
  TextColumn get paymentMethod =>
      text().withDefault(const Constant('other'))();

  /// Server-assigned id of the uploaded receipt (`FinanceAttachment.id`),
  /// set once `FinanceSyncService` has successfully uploaded `localReceiptPath`.
  TextColumn get receiptAttachmentId => text().nullable()();

  /// Device-local path to a receipt file awaiting upload. Cleared once
  /// `receiptAttachmentId` is set. See `finance_sync_service.dart`'s
  /// upload-before-sync ordering.
  TextColumn get localReceiptPath => text().nullable()();

  /// When the expense occurred (device time, UTC).
  DateTimeColumn get occurredAt => dateTime()();

  /// Staff member who recorded the expense.
  /// Soft-references `LocalUserProfiles.id` without an FK constraint: a
  /// profile that is later remotely revoked and deleted should not block
  /// or cascade-delete a historical expense record.
  TextColumn get actorUserId => text()();

  /// Server-assigned id (`OtherExpense.id`), set once this row has synced.
  /// A row with a non-null `serverId` is edited/deleted via direct API
  /// calls (`FinanceApiService`), not the outbox.
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
