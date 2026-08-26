/// Type converter for Decimal values stored as TEXT in SQLite.
///
/// Money and quantity fields throughout the sync layer use the `decimal`
/// package's [Decimal] type instead of `double` to avoid float-rounding
/// mismatches that would surface as spurious "sync failed" results when
/// comparing against the backend's own Pydantic `Decimal`-typed fields.
/// This converter bridges them: Dart app code reads/writes [Decimal],
/// SQLite stores them as TEXT, and the round-trip is lossless.
library;

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

class DecimalConverter extends TypeConverter<Decimal, String> {
  const DecimalConverter();

  @override
  Decimal fromSql(String fromDb) => Decimal.parse(fromDb);

  @override
  String toSql(Decimal value) => value.toString();
}
