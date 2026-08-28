/// Void/refund requests for already-synced sales, awaiting sync.
///
/// `PendingVoidsRefunds` follows the same outbox shape as `PendingSales`:
/// an autoincrement local `id` plus a client-generated `clientActionId`
/// idempotency key. Rows are immutable once created; only the sync
/// bookkeeping columns change locally.
///
/// ⚠️ BACKEND-BLOCKED: POS Service's void/refund endpoint does not
/// currently accept a client-generated idempotency key the way
/// `/sales/sync` does, so nothing in `lib/sync` pushes these rows yet.
/// The table exists so the local schema shape is in place; wiring the
/// push sync is deferred until that endpoint exists.
///
/// `saleId` references `PendingSales.clientSaleId` (not the local
/// autoincrement `id`): a void/refund only ever targets a sale that has
/// already been synced and is therefore permanent.
library;

import 'package:drift/drift.dart';
import 'pending_sales.dart';

/// Void/refund requests for already-synced sales, awaiting sync.
class PendingVoidsRefunds extends Table {
  /// Local row ID (autoincrement).
  IntColumn get id => integer().autoIncrement()();

  /// Client-side idempotency key (UUID v4, unique).
  TextColumn get clientActionId => text().unique()();

  /// The already-synced sale this action applies to.
  TextColumn get saleId => text().references(PendingSales, #clientSaleId)();

  /// Requested new status: `voided` or `refunded`.
  TextColumn get newStatus => text()(); // voided|refunded

  /// Reason for the void/refund.
  TextColumn get reason => text()();

  /// Staff member who performed the action.
  /// Soft-references `LocalUserProfiles.id` without an FK constraint: a
  /// profile that is later remotely revoked and deleted should not block
  /// or cascade-delete a historical void/refund record.
  TextColumn get actorUserId => text()();

  /// When the void/refund occurred (device time, UTC).
  DateTimeColumn get occurredAt => dateTime()();

  /// Local sync state: `pending`, `syncing`, `failed`, `synced`.
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();

  /// Error message from the last sync attempt, if any.
  TextColumn get syncError => text().nullable()();

  /// Number of times this action has been attempted.
  IntColumn get syncAttemptCount => integer().withDefault(const Constant(0))();

  /// Timestamp of the last sync attempt.
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  /// When the action was successfully synced to the backend.
  DateTimeColumn get syncedAt => dateTime().nullable()();

  /// Local row creation timestamp.
  DateTimeColumn get createdAt => dateTime()();
}
