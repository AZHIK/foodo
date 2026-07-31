import 'package:drift/drift.dart';

@DataClassName('CachedItem')
class CachedItems extends Table {
  TextColumn get itemId => text()();
  TextColumn get businessId => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get unit => text()();

  /// BACKEND-GAP FLAG (Stage-2): The POS Service API returns
  /// BigDecimal/numeric for unit_price, but we store it as Int64
  /// micro-units (smallest currency unit, e.g. pesewas for GHS).
  ///
  /// This cast is SAFE while ALL supported currencies use 0 or 2
  /// decimal places AND unit_price is always a whole number of
  /// micro-units.  If the backend ever transmits fractional amounts
  /// (e.g. 0.350 GHS per piece) the repository layer MUST apply a
  /// scaling cast — or we add a redundant TEXT/decimal column here.
  IntColumn get unitPrice => integer()();

  IntColumn get stockOnHand => integer().withDefault(const Constant(0))();
  DateTimeColumn get cachedAt => dateTime()();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {itemId};
}
