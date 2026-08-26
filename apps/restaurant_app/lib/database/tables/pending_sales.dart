/// Sales awaiting sync to POS Service.
///
/// `PendingSales` mirrors the backend's `SaleSyncInput` schema (from
/// `services/pos-service/app/schemas/sales.py`) with additional local sync
/// bookkeeping: `syncStatus`, `syncError`, `syncAttemptCount`, etc.
///
/// The `clientSaleId` (a UUID v4 generated when the sale is completed locally)
/// is the idempotency key: the backend uses it to deduplicate across retries,
/// ensuring that retrying a failed sync does not create duplicate `Sale` rows.
/// The `syncStatus` tracks local progress: `pending` (never synced yet),
/// `syncing` (currently in-flight, a row-claim marker for concurrency safety),
/// `failed` (sync failed, will retry), `synced` (backend accepted it).
///
/// Synced rows are **never deleted**; they double as offline-readable local
/// sale history, allowing receipts to work forever offline.
library;

import 'package:drift/drift.dart';
import '../converters/decimal_converter.dart';

/// Sales awaiting sync to POS Service.
class PendingSales extends Table {
  /// Local row ID (autoincrement).
  IntColumn get id => integer().autoIncrement()();

  /// Client-side idempotency key (UUID v4, unique).
  TextColumn get clientSaleId => text().unique()();

  /// Sale status: `completed`, `voided`, or `refunded`.
  /// The sale arrives in its final state; there is no "open/in-progress".
  TextColumn get status => text()(); // completed|voided|refunded

  /// Location this sale belongs to.
  TextColumn get businessLocationId => text()();

  /// Discount applied to the whole sale.
  TextColumn get discountAmount =>
      text().map(const DecimalConverter()).withDefault(const Constant('0'))();

  /// Payment method used.
  TextColumn get paymentMethod =>
      text()(); // cash|mobile_money|card|other

  /// When the sale occurred (device time, UTC).
  DateTimeColumn get occurredAt => dateTime()();

  /// Optional monotonic device counter for the sale.
  IntColumn get deviceSequence => integer().nullable()();

  /// Reason for voiding or refunding (required app-side iff status is
  /// voided/refunded, mirroring the backend's Pydantic validator).
  TextColumn get voidOrRefundReason => text().nullable()();

  /// Joins back to the existing UI `Order.id` (e.g., "ORD-0042") so the receipt
  /// can find both local and synced records without data duplication.
  /// No enforced FK (different ID space from `PendingSales.id`).
  TextColumn get localOrderId => text().nullable()();

  /// Local sync state: `pending`, `syncing`, `failed`, `synced`.
  /// `syncing` is a row-claim marker used for cross-isolate concurrency safety.
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();

  /// Error message from the last sync attempt, if any.
  TextColumn get syncError => text().nullable()();

  /// Number of times this sale has been attempted.
  IntColumn get syncAttemptCount => integer().withDefault(const Constant(0))();

  /// Timestamp of the last sync attempt.
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  /// When the sale was successfully synced to the backend.
  DateTimeColumn get syncedAt => dateTime().nullable()();

  /// Local row creation timestamp.
  DateTimeColumn get createdAt => dateTime()();
}
