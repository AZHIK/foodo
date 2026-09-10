/// Completed sales cached from POS Service, for the Sales screen's ledger.
///
/// `CachedSales` mirrors the backend's `SaleRead`/`SaleListItem` schemas
/// (from `services/pos-service/app/schemas/sales.py`) — a pull-only read
/// cache, the sales-side analogue of `CachedItems`. Unlike `CachedItems`,
/// rows here are never soft-deleted: a sale is immutable history once it
/// exists, and a void/refund updates the same row's `status`/`voidedAt`/
/// `refundedAt` rather than retiring it.
///
/// `id` is the server-assigned `Sale.id` (UUID) — the primary key here is
/// the real backend identity, not the client-generated `clientSaleId` (kept
/// alongside it only as the idempotency key that produced this row).
library;

import 'package:drift/drift.dart';
import '../converters/decimal_converter.dart';

/// Completed sales cached from POS Service.
class CachedSales extends Table {
  /// Sale UUID, assigned by POS Service (primary key).
  TextColumn get id => text()();

  /// Business this sale belongs to.
  TextColumn get businessId => text()();

  /// Store/location this sale was rung up at.
  TextColumn get storeId => text()();

  /// Client-generated idempotency key this sale was created from.
  TextColumn get clientSaleId => text()();

  /// Sale status: `completed`, `voided`, or `refunded`.
  TextColumn get status => text()(); // completed|voided|refunded

  TextColumn get subtotal => text().map(const DecimalConverter())();

  TextColumn get discountAmount => text().map(const DecimalConverter())();

  TextColumn get taxAmount => text().map(const DecimalConverter())();

  TextColumn get total => text().map(const DecimalConverter())();

  /// Payment method: `cash`, `mobile_money`, `card`, or `other`.
  TextColumn get paymentMethod => text()();

  /// Staff member who rang up the sale, if known.
  TextColumn get actorId => text().nullable()();

  /// When the sale occurred (device-reported time, UTC) — the timestamp the
  /// backend sorts and filters the ledger by.
  DateTimeColumn get occurredAt => dateTime()();

  /// When POS Service accepted this sale.
  DateTimeColumn get syncedAt => dateTime()();

  DateTimeColumn get voidedAt => dateTime().nullable()();

  DateTimeColumn get refundedAt => dateTime().nullable()();

  TextColumn get voidOrRefundReason => text().nullable()();

  /// Backend creation timestamp.
  DateTimeColumn get createdAt => dateTime()();

  /// Local timestamp of the most recent pull that included this row.
  DateTimeColumn get lastSyncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
