import 'package:drift/drift.dart';
import 'pending_sales.dart';
import 'cached_items.dart';

@DataClassName('PendingSaleLineItem')
class PendingSaleLineItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientSaleId =>
      text().references(PendingSales, #clientSaleId)();
  TextColumn get itemId =>
      text().references(CachedItems, #itemId)();
  IntColumn get quantity => integer()();
  IntColumn get unitPriceAtSale => integer()();
  DateTimeColumn get createdAt => dateTime()();
}
