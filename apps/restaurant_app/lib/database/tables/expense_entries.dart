/// Recorded expenses (money going out), unrelated to a POS sale.
///
/// `ExpenseEntries` follows the same outbox shape as `PendingSales`: an
/// autoincrement local `id` plus a client-generated `expenseId`
/// idempotency key. Rows are immutable once created — a correction is a
/// new offsetting entry, not an edit, matching the audit-integrity
/// principle used throughout the platform.
///
/// ⚠️ BACKEND-BLOCKED: no service currently owns expense tracking, so
/// nothing in `lib/sync` pushes these rows yet. The table exists so the
/// local schema shape is in place; wiring the push sync is deferred until
/// a backend endpoint exists (either a new module in POS Service or a
/// small Finance-adjacent service).
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

  /// Business location this expense belongs to.
  TextColumn get businessLocationId => text()();

  /// Expense category. Controlled list, not free text, so reporting
  /// stays meaningful: rent|utilities|salaries|repairs|supplies|other.
  TextColumn get category => text()();

  /// Expense amount.
  TextColumn get amount => text().map(const DecimalConverter())();

  /// Optional free-text description.
  TextColumn get description => text().nullable()();

  /// When the expense occurred (device time, UTC).
  DateTimeColumn get occurredAt => dateTime()();

  /// Staff member who recorded the expense.
  /// Soft-references `LocalUserProfiles.id` without an FK constraint: a
  /// profile that is later remotely revoked and deleted should not block
  /// or cascade-delete a historical expense record.
  TextColumn get actorUserId => text()();

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
