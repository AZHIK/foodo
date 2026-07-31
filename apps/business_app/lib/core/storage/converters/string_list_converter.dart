import 'dart:convert';
import 'package:drift/drift.dart';

class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    final list = jsonDecode(fromDb) as List;
    return list.cast<String>();
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}
