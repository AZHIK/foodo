/// Recorded other income (money coming in), not from a POS sale.
///
/// `OtherIncomeEntries` mirrors `ExpenseEntries`'s outbox shape and
/// immutability rules, but is kept as its own table rather than a
/// signed-amount row in `ExpenseEntries`: income and expense have
/// different category lists and will likely need different
/// reporting/permission treatment later, not worth conflating now.
///
/// ⚠️ BACKEND-BLOCKED: same as `ExpenseEntries` — no service currently
/// owns this, so nothing in `lib/sync` pushes these rows yet.
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

  /// Business location this income belongs to.
  TextColumn get businessLocationId => text()();

  /// Income category. Controlled list, not free text, same reasoning as
  /// `ExpenseEntries.category`: equipment_rental|catering_deposit|other.
  TextColumn get category => text()();

  /// Income amount.
  TextColumn get amount => text().map(const DecimalConverter())();

  /// Optional free-text description.
  TextColumn get description => text().nullable()();

  /// When the income occurred (device time, UTC).
  DateTimeColumn get occurredAt => dateTime()();

  /// Staff member who recorded the income.
  /// Soft-references `LocalUserProfiles.id` without an FK constraint, same
  /// rationale as `ExpenseEntries.actorUserId`.
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
