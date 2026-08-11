import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink_business/shared/widgets/data_table/export_service.dart';

class _Row {
  const _Row(this.name, this.age, this.score, this.active);
  final String name;
  final int age;
  final double score;
  final bool active;
}

void main() {
  final columns = <ExportColumn>[
    ExportColumn(
      key: 'name',
      label: 'Name',
      valueExtractor: (r) => (r as _Row).name,
    ),
    ExportColumn(
      key: 'age',
      label: 'Age',
      valueExtractor: (r) => (r as _Row).age,
    ),
    ExportColumn(
      key: 'score',
      label: 'Score',
      valueExtractor: (r) => (r as _Row).score,
    ),
    ExportColumn(
      key: 'active',
      label: 'Active',
      valueExtractor: (r) => (r as _Row).active,
    ),
  ];

  const rows = <_Row>[
    _Row('Alice', 30, 92.5, true),
    _Row('Bob', 25, 78.0, false),
    _Row('Carol', 42, 88.25, true),
  ];

  group('ExportService.generateExcel', () {
    test('produces non-empty bytes', () {
      final svc = ExportService();
      final bytes = svc.generateExcel(columns: columns, rows: rows);
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });

    test('Excel has expected header row + 3 data rows + right columns', () {
      final svc = ExportService();
      final bytes = svc.generateExcel(columns: columns, rows: rows);
      final excel = Excel.decodeBytes(bytes);
      expect(excel.sheets.keys.length, greaterThanOrEqualTo(1));
      final sheet = excel.sheets.values.first;
      // Header row + 3 data rows
      expect(sheet.rows.length, equals(rows.length + 1));
      // Header labels
      final headerTexts = sheet.rows[0]
          .map((c) => c?.value?.toString() ?? '')
          .toList();
      expect(headerTexts, containsAll(['Name', 'Age', 'Score', 'Active']));
      // First data row contains Alice / 30 / 92.5 / true
      final row1 = sheet.rows[1].map((c) => c?.value?.toString() ?? '').toList();
      expect(row1[0], contains('Alice'));
      expect(row1.any((s) => s.contains('30')), isTrue);
      // Third data row has Carol
      final row3 = sheet.rows[3].map((c) => c?.value?.toString() ?? '').toList();
      expect(row3[0], contains('Carol'));
    });

    test('empty rows still yields valid non-empty Excel bytes', () {
      final svc = ExportService();
      final bytes = svc.generateExcel(columns: columns, rows: const []);
      expect(bytes, isNotEmpty);
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.sheets.values.first;
      // Only the header row
      expect(sheet.rows.length, equals(1));
    });

    test('column count matches definition', () {
      final svc = ExportService();
      final bytes = svc.generateExcel(columns: columns, rows: rows);
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.sheets.values.first;
      for (final row in sheet.rows) {
        expect(row.length, greaterThanOrEqualTo(columns.length));
      }
    });
  });

  group('ExportService.generatePdf', () {
    test('produces non-empty bytes', () async {
      final svc = ExportService();
      final bytes = await svc.generatePdf(columns: columns, rows: rows);
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(500));
    });

    test('PDF bytes start with valid %PDF- magic header', () async {
      final svc = ExportService();
      final bytes = await svc.generatePdf(columns: columns, rows: rows);
      final header = String.fromCharCodes(bytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('PDF declares at least 1 page', () async {
      final svc = ExportService();
      final bytes = await svc.generatePdf(columns: columns, rows: rows);
      final text = String.fromCharCodes(bytes);
      final pageObjects =
          RegExp(r'/Type\s*/Page[^s]').allMatches(text).length;
      expect(pageObjects, greaterThanOrEqualTo(1));
    });

    test('empty rows yields valid PDF with header', () async {
      final svc = ExportService();
      final bytes = await svc.generatePdf(columns: columns, rows: const []);
      expect(bytes, isNotEmpty);
      final header = String.fromCharCodes(bytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });
  });
}
