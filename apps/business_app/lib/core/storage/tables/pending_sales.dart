import 'package:drift/drift.dart';

@DataClassName('PendingSale')
class PendingSales extends Table {
  TextColumn get clientSaleId => text()();
  TextColumn get businessId => text()();
  TextColumn get userId => text()();
  IntColumn get deviceSequence => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {clientSaleId};
}
