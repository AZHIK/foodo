import 'package:drift/drift.dart';

@DataClassName('DeviceConfig')
class DeviceConfigs extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  TextColumn get lockedBusinessId => text().nullable()();

  TextColumn get lockedBusinessName => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}