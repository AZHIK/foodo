import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/export_helper.dart';
import 'data_column_spec.dart';

/// The pair of export buttons every data page carries.
///
/// A function rather than a widget so the buttons drop straight into
/// [DataPageScaffold.actions], which wraps them alongside each page's own
/// actions instead of nesting another Row inside the Wrap.
List<Widget> exportActions({
  required BuildContext context,
  required VoidCallback onExportPdf,
  required VoidCallback onExportExcel,
  bool busy = false,
}) {
  final isMobile = MediaQuery.of(context).size.width < 600;

  if (isMobile) {
    return [
      SizedBox(
        height: 40,
        width: 40,
        child: IconButton(
          tooltip: 'Export PDF',
          padding: EdgeInsets.zero,
          iconSize: 20,
          onPressed: busy ? null : onExportPdf,
          icon: busy
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.picture_as_pdf_outlined),
        ),
      ),
      SizedBox(
        height: 40,
        width: 40,
        child: IconButton(
          tooltip: 'Export Excel',
          padding: EdgeInsets.zero,
          iconSize: 20,
          onPressed: busy ? null : onExportExcel,
          icon: const Icon(Icons.table_view_outlined),
        ),
      ),
    ];
  }

  return [
    OutlinedButton.icon(
      onPressed: busy ? null : onExportPdf,
      icon: busy
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.picture_as_pdf_outlined, size: 18),
      label: const Text('Export PDF'),
    ),
    OutlinedButton.icon(
      onPressed: busy ? null : onExportExcel,
      icon: const Icon(Icons.table_view_outlined, size: 18),
      label: const Text('Export Excel'),
    ),
  ];
}

/// Runs an export and reports the outcome.
///
/// Lives here so both pages share one behaviour: exports never throw at the
/// UI, and success and failure both land in the same place the user is
/// already looking.
Future<void> runExport<T>({
  required BuildContext context,
  required Future<ExportResult> Function() export,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();

  final result = await export();
  if (!context.mounted) return;

  // Dismissing the save dialog is a decision, not a problem worth a banner.
  if (result.cancelled) return;

  final path = result.path;

  messenger.showSnackBar(
    SnackBar(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(result.message),
          if (path != null) ...[
            const SizedBox(height: 2),
            Text(
              // A file path has no spaces to wrap at, so the default line
              // breaking would ellipsise the middle of it and hide the one
              // thing the user needs. Zero-width spaces after each separator
              // give it legal break points without altering the text.
              path.replaceAllMapped(
                RegExp(r'[/\\]'),
                (match) => '${match[0]}​',
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).snackBarTheme.contentTextStyle?.color?.withValues(alpha: 0.8),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
      backgroundColor: result.ok
          ? null
          : Theme.of(context).colorScheme.errorContainer,
      // Long enough to read a path off, and to reach the copy action.
      duration: Duration(seconds: result.ok ? 10 : 6),
      action: path == null
          ? null
          : SnackBarAction(
              label: 'Copy path',
              onPressed: () => Clipboard.setData(ClipboardData(text: path)),
            ),
    ),
  );
}

/// Convenience wrapper binding the two buttons to a page's columns and rows.
///
/// A page passes what it is showing; everything about files stays inside
/// [ExportHelper].
List<Widget> dataPageExportActions<T>({
  required BuildContext context,
  required List<DataColumnSpec<T>> columns,
  required List<T> rows,
  required String title,
  String? subtitle,
}) {
  return exportActions(
    context: context,
    onExportPdf: () => runExport<T>(
      context: context,
      export: () => ExportHelper.exportToPdf(
        columns: columns,
        rows: rows,
        title: title,
        subtitle: subtitle,
      ),
    ),
    onExportExcel: () => runExport<T>(
      context: context,
      export: () => ExportHelper.exportToExcel(
        columns: columns,
        rows: rows,
        title: title,
      ),
    ),
  );
}
