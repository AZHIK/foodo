import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_durations.dart';
import '../../constants/app_strings.dart';
import '../../theme/breakpoints.dart';
import '../../utils/export_helper.dart';
import 'data_column_spec.dart';

/// Uniform height for every data-page header action: export buttons, refresh
/// icons, the period selector and Filled/Outlined primary actions (which use
/// the M3 default of 40) all sit on one even bar.
const double kDataPageActionHeight = 40.0;

/// Fixed width of each export button. Identical for PDF and Excel so the pair
/// always matches, whatever the labels say. Fits "Export Excel" / "Pakua
/// Excel" comfortably; the label auto-shrinks via [FittedBox] rather than
/// clipping if a larger text scale ever overflows it.
const double kExportButtonWidth = 140.0;

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
        height: kDataPageActionHeight,
        width: kDataPageActionHeight,
        child: IconButton(
          tooltip: AppStrings.exportPdf,
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
        height: kDataPageActionHeight,
        width: kDataPageActionHeight,
        child: IconButton(
          tooltip: AppStrings.exportExcel,
          padding: EdgeInsets.zero,
          iconSize: 20,
          onPressed: busy ? null : onExportExcel,
          icon: const Icon(Icons.table_view_outlined),
        ),
      ),
    ];
  }

  // Compact, paired buttons: the short "Pakua" labels plus tight padding
  // keep the pair narrow so the header's Wrap rarely needs a second run.
  // Grouped in one Row so the Wrap can never split PDF and Excel across two
  // rows — the pair moves as a unit. Both share one fixed size, so they
  // always match each other and the buttons beside them.
  final style = OutlinedButton.styleFrom(
    fixedSize: const Size(kExportButtonWidth, kDataPageActionHeight),
    padding: const EdgeInsets.symmetric(horizontal: 10),
    // Without this M3 pads every button to a 48px touch target, which would
    // silently undo the uniform bar height.
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w600,
    ),
  );
  // No Expanded/Flexible here: OutlinedButton.icon already wraps the label
  // in its own Flexible (which bounds the width), and a second flex widget
  // would fight it for the same parent data. FittedBox alone shrinks the
  // text instead of clipping if a large text scale ever overflows.
  Widget label(String text) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(text, maxLines: 1),
      );
  return [
    Row(
      mainAxisSize: MainAxisSize.min,
      spacing: Insets.sm,
      children: [
        OutlinedButton.icon(
          style: style,
          onPressed: busy ? null : onExportPdf,
          icon: busy
              ? const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.picture_as_pdf_outlined, size: 16),
          label: label(AppStrings.exportPdf),
        ),
        OutlinedButton.icon(
          style: style,
          onPressed: busy ? null : onExportExcel,
          icon: const Icon(Icons.table_view_outlined, size: 16),
          label: label(AppStrings.exportExcel),
        ),
      ],
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
      duration: result.ok
          ? AppDurations.exportSnackbarOk
          : AppDurations.exportSnackbarError,
      action: path == null
          ? null
          : SnackBarAction(
              label: AppStrings.copyPath,
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
