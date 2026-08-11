import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Describes a column for [ExportService].  Mirrors the data-carrying
/// fields of [AppDataColumn] so the two widgets share the same mental
/// model — tests exercise both against identical column definitions.
class ExportColumn {
  const ExportColumn({
    required this.key,
    required this.label,
    required this.valueExtractor,
  });

  final String key;
  final String label;
  final dynamic Function(dynamic row) valueExtractor;
}

/// Output formats supported by [ExportService].
enum ExportFormat { excel, pdf }

/// Plain service class that turns a list of rows + column definitions
/// into Excel or PDF bytes, then hands them off to [FileSaver] (or
/// [Printing.sharePdf] for PDFs, which previews before saving on
/// platforms that support it).
///
/// Decoupled from [AppDataTable] and the Flutter widget tree so it can
/// be unit-tested without pumping widgets.
class ExportService {
  ExportService();

  // ── Public API ──────────────────────────────────────────────────

  /// Generates Excel bytes for `rows` using the same [valueExtractor]
  /// contract the data table uses — each column becomes a sheet column
  /// whose header is [ExportColumn.label].
  Uint8List generateExcel({
    required List<ExportColumn> columns,
    required List<dynamic> rows,
  }) {
    final excel = Excel.createExcel();
    const sheetName = 'Sheet1';
    if (excel.sheets.isNotEmpty && !excel.sheets.containsKey(sheetName)) {
      excel.rename(excel.sheets.keys.first, sheetName);
    }
    final sheet = excel[sheetName];

    final headerStyle = CellStyle(
      bold: true,
      fontSize: 12,
      verticalAlign: VerticalAlign.Center,
    );

    for (var c = 0; c < columns.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(
        columnIndex: c,
        rowIndex: 0,
      ));
      cell.value = TextCellValue(columns[c].label);
      cell.cellStyle = headerStyle;
    }

    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < columns.length; c++) {
        final raw = columns[c].valueExtractor(rows[r]);
        final cell = sheet.cell(CellIndex.indexByColumnRow(
          columnIndex: c,
          rowIndex: r + 1,
        ));
        cell.value = _toExcelCellValue(raw);
      }
    }

    return Uint8List.fromList(excel.encode() ?? const []);
  }

  /// Generates PDF bytes for `rows` as a simple table layout with a
  /// title header row and a page footer showing row count / generation
  /// timestamp.
  Future<Uint8List> generatePdf({
    required List<ExportColumn> columns,
    required List<dynamic> rows,
    String title = 'Export',
  }) async {
    final pdf = pw.Document();

    pw.Widget cellText(String s, {required bool header}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 4,
          ),
          child: pw.Text(
            s,
            style: pw.TextStyle(
              fontSize: header ? 10 : 9,
              fontWeight:
                  header ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        );

    final headers = columns
        .map((c) => cellText(c.label, header: true))
        .toList();

    final dataRows = rows.map((row) {
      return columns
          .map((c) => cellText(_formatValue(c.valueExtractor(row)), header: false))
          .toList();
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  _formatDateTime(DateTime.now()),
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColors.grey300,
              width: 0.5,
            ),
            columnWidths: {
              for (var i = 0; i < columns.length; i++)
                i: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                children: headers,
              ),
              ...dataRows.map((cells) => pw.TableRow(children: cells)),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            '${rows.length} row${rows.length == 1 ? '' : 's'}',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ── Flutter-integrated save / share ─────────────────────────────

  /// Generates Excel bytes and saves them via [FileSaver].
  Future<void> exportExcel({
    required BuildContext context,
    required List<ExportColumn> columns,
    required List<dynamic> rows,
    required String filename,
  }) async {
    final bytes = generateExcel(columns: columns, rows: rows);
    if (bytes.isEmpty) {
      throw StateError('Excel encoder returned empty bytes.');
    }
    await FileSaver.instance.saveFile(
      name: filename,
      bytes: bytes,
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  /// Generates PDF bytes, then on mobile/web uses [Printing.sharePdf]
  /// for a native preview/share sheet, and on desktop falls through to
  /// [FileSaver] so "save to disk" works on Windows/macOS/Linux.
  Future<void> exportPdf({
    required BuildContext context,
    required List<ExportColumn> columns,
    required List<dynamic> rows,
    required String filename,
    String title = 'Export',
  }) async {
    final platform = Theme.of(context).platform;
    final bytes = await generatePdf(
      columns: columns,
      rows: rows,
      title: title,
    );
    if (bytes.isEmpty) {
      throw StateError('PDF encoder returned empty bytes.');
    }

    final isDesktop = platform == TargetPlatform.linux ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.windows;

    if (isDesktop) {
      await FileSaver.instance.saveFile(
        name: filename,
        bytes: bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
    } else {
      await Printing.sharePdf(
        bytes: bytes,
        filename: filename,
      );
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────

  CellValue _toExcelCellValue(dynamic raw) {
    if (raw == null) return TextCellValue('');
    if (raw is int) return IntCellValue(raw);
    if (raw is double) return DoubleCellValue(raw);
    if (raw is bool) return BoolCellValue(raw);
    if (raw is DateTime) return DateTimeCellValue.fromDateTime(raw);
    return TextCellValue(_formatValue(raw));
  }

  String _formatValue(dynamic v) {
    if (v == null) return '';
    if (v is DateTime) return _formatDateTime(v);
    if (v is double) {
      return v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
    }
    return v.toString();
  }

  static String _formatDateTime(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    final ss = d.second.toString().padLeft(2, '0');
    return '$y-$m-$day $hh:$mm:$ss';
  }
}
