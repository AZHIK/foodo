/// Other-income entries cached from POS Service. Mirror of
/// `CachedOtherExpenses` — see that file's doc comment for the pull/
/// soft-delete-propagation design.
library;

import 'package:drift/drift.dart';
import '../converters/decimal_converter.dart';

/// Other-income entries cached from POS Service.
class CachedOtherIncomes extends Table {
  /// Income UUID, assigned by POS Service (primary key).
  TextColumn get id => text()();

  TextColumn get businessId => text()();

  TextColumn get storeId => text()();

  /// Client-generated idempotency key this income was created from.
  TextColumn get clientIncomeId => text()();

  TextColumn get category => text()();

  TextColumn get amount => text().map(const DecimalConverter())();

  TextColumn get description => text()();

  TextColumn get source => text().nullable()();

  TextColumn get note => text().nullable()();

  /// Payment method: `cash`, `mobile_money`, `card`, or `other`.
  TextColumn get paymentMethod => text()();

  TextColumn get receiptAttachmentId => text().nullable()();

  /// Staff member who recorded the income, if known.
  TextColumn get actorId => text().nullable()();

  DateTimeColumn get occurredAt => dateTime()();

  DateTimeColumn get syncedAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();

  /// Local timestamp of the most recent pull that included this row.
  DateTimeColumn get lastSyncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
