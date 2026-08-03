import 'package:drift/drift.dart';

@DataClassName('LocalUserProfile')
class LocalUserProfiles extends Table {
  TextColumn get userId => text()();
  TextColumn get phone => text()();
  TextColumn get displayName => text()();
  TextColumn get pinHash => text()();
  TextColumn? get activeBusinessId => text().nullable()();
  DateTimeColumn get lastLoginAt => dateTime()();
  BoolColumn get isCurrentlyActive => boolean().withDefault(const Constant(false))();
  IntColumn get pinAttemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get pinLockedUntil => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {userId};
}
