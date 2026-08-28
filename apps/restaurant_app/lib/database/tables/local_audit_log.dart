/// Append-only local audit trail, synced to the backend at lowest priority.
///
/// `LocalAuditLog` records notable local events (PIN lockouts, sale
/// completion, expense entries, remote profile revocation, etc.) and feeds
/// the backend's `audit.recorded` stream once synced. It follows the same
/// outbox shape as the other push tables, but is useful-not-critical: it
/// syncs last, after sales and expense/income data.
library;

import 'package:drift/drift.dart';

/// Append-only local audit trail, synced to the backend at lowest priority.
class LocalAuditLog extends Table {
  /// Local row ID (autoincrement).
  IntColumn get id => integer().autoIncrement()();

  /// Staff member (or system) responsible for the action.
  /// Soft-references `LocalUserProfiles.id` without an FK constraint: a
  /// profile that is later remotely revoked and deleted should not block
  /// or cascade-delete a historical audit entry.
  TextColumn get actorUserId => text()();

  /// Event identifier, e.g. `pin.unlock_failed`, `sale.completed`,
  /// `expense.recorded`, `profile.remotely_revoked`.
  TextColumn get action => text()();

  /// Optional type of the resource this event concerns.
  TextColumn get resourceType => text().nullable()();

  /// Optional ID of the resource this event concerns.
  TextColumn get resourceId => text().nullable()();

  /// Optional JSON-encoded event details.
  TextColumn get detailsJson => text().nullable()();

  /// When the event occurred (device time, UTC).
  DateTimeColumn get occurredAt => dateTime()();

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
