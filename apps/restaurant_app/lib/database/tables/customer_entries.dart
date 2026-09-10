/// Customers created on-device, awaiting sync to POS Service.
///
/// `CustomerEntries` diverges from the other outbox tables
/// (`ExpenseEntries`, `PendingSales`) in one structural way: `customerId`
/// is not a separate client-side idempotency key paired with a
/// server-assigned id — it IS the customer's real primary key, generated
/// on-device and sent as-is to the server (see
/// `services/pos-service/app/models/customers.py`'s module docstring for
/// why). There is no `serverId` column here; once synced, `customerId`
/// already equals the server's row id.
///
/// Business-scoped, not store-scoped — a customer is shared across a
/// business's stores, unlike `ExpenseEntries`/`OtherIncomeEntries`.
///
/// A row here CAN be edited or deleted after creation (via
/// `CustomerSyncService`/`CustomerApiService`), mirroring the finance
/// outbox tables — the shipped UI has real Edit/Delete actions and no
/// offsetting-entry correction workflow.
library;

import 'package:drift/drift.dart';

/// Customers created on-device, awaiting sync to POS Service.
class CustomerEntries extends Table {
  /// Local row ID (autoincrement).
  IntColumn get id => integer().autoIncrement()();

  /// The customer's real, permanent id (UUID v4, generated on-device) —
  /// unique locally, and becomes the server's primary key on sync.
  TextColumn get customerId => text().unique()();

  /// Business this customer belongs to.
  TextColumn get businessId => text()();

  TextColumn get name => text()();
  TextColumn get phone => text()();
  TextColumn get email => text().nullable()();
  TextColumn get addressLine1 => text().nullable()();

  /// When the customer was added (device time, UTC).
  DateTimeColumn get joinedAt => dateTime()();

  /// Staff member who added the customer.
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
