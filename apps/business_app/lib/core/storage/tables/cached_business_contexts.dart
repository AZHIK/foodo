import 'package:drift/drift.dart';
import '../converters/string_list_converter.dart';

@DataClassName('CachedBusinessContext')
class CachedBusinessContexts extends Table {
  TextColumn get businessId => text()();
  TextColumn get businessName => text()();
  TextColumn get displayName => text()();
  TextColumn get phone => text()();
  TextColumn get email => text()();
  TextColumn get address => text()();
  TextColumn get currencyCode => text()();
  TextColumn get roleNames =>
      text().map(const StringListConverter()).withDefault(const Constant('[]'))();
  TextColumn get permissions =>
      text().map(const StringListConverter()).withDefault(const Constant('[]'))();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {businessId};
}
