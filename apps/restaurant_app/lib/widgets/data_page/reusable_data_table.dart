import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/table_query.dart';
import '../../providers/preferences_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import 'data_column_spec.dart';
import 'data_row_card.dart';

/// A sortable, paginated table that collapses to cards on narrow widths.
///
/// Generic over the row type and given its columns as config, so it holds no
/// knowledge of any particular page. It is also *stateless* with respect to
/// the data: sorting, filtering and paging all happen in the page's provider,
/// and this widget renders the slice it is handed and reports intent back
/// through [onSort] and [onPageChanged].
///
/// The one thing it reads for itself is [tableDensityProvider] — row height is
/// a preference the user sets once in App Preferences and expects to see on
/// every table in the app, so making each page pass it down would only be a
/// way for one page to forget.
class ReusableDataTable<T> extends ConsumerWidget {
  const ReusableDataTable({
    super.key,
    required this.columns,
    required this.slice,
    required this.query,
    required this.onSort,
    required this.onPageChanged,
    this.onRowTap,
    this.rowActions = const [],
    this.emptyState,
    this.forceCards = false,
  });

  final List<DataColumnSpec<T>> columns;
  final PageSlice<T> slice;
  final TableQuery query;

  /// Called with the tapped column's [DataColumnSpec.field].
  final ValueChanged<String> onSort;
  final ValueChanged<int> onPageChanged;

  final void Function(T row)? onRowTap;
  final List<DataRowAction<T>> rowActions;
  final Widget? emptyState;

  /// Forces the card layout regardless of width, for embedding the table in a
  /// narrow container on a wide screen.
  final bool forceCards;

  static const double _actionsWidth = 44;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keyed to the window, not to this box. Page padding differs either side
    // of the breakpoint, so available width is not monotonic across it — a
    // 640px window can hand the table less room than a 599px one, which would
    // flip the layout backwards.
    final asCards = forceCards || context.isMobile;
    final density = ref.watch(tableDensityProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Nothing to page through, so the footer would only be noise.
        if (slice.items.isEmpty) {
          return emptyState ?? const _DefaultEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (asCards)
              _Cards<T>(
                columns: columns,
                rows: slice.items,
                onRowTap: onRowTap,
                rowActions: rowActions,
                density: density,
              )
            else
              _Table<T>(
                columns: _visibleColumns(constraints.maxWidth),
                rows: slice.items,
                query: query,
                onSort: onSort,
                onRowTap: onRowTap,
                rowActions: rowActions,
                density: density,
              ),
            _Pagination(slice: slice, onPageChanged: onPageChanged),
          ],
        );
      },
    );
  }

  List<DataColumnSpec<T>> _visibleColumns(double width) => [
    for (final column in columns)
      if (width >= column.minTableWidth) column,
  ];
}

// ---------------------------------------------------------------------------
// Table form
// ---------------------------------------------------------------------------

class _Table<T> extends StatelessWidget {
  const _Table({
    required this.columns,
    required this.rows,
    required this.query,
    required this.onSort,
    required this.onRowTap,
    required this.rowActions,
    required this.density,
  });

  final List<DataColumnSpec<T>> columns;
  final List<T> rows;
  final TableQuery query;
  final ValueChanged<String> onSort;
  final void Function(T row)? onRowTap;
  final List<DataRowAction<T>> rowActions;
  final TableDensity density;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: Radii.card,
        border: Border.all(color: context.semantic.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _HeaderRow<T>(
            columns: columns,
            query: query,
            onSort: onSort,
            showActions: rowActions.isNotEmpty,
            density: density,
          ),
          for (var i = 0; i < rows.length; i++) ...[
            const Divider(height: 1),
            _BodyRow<T>(
              row: rows[i],
              columns: columns,
              onTap: onRowTap,
              rowActions: rowActions,
              density: density,
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderRow<T> extends StatelessWidget {
  const _HeaderRow({
    required this.columns,
    required this.query,
    required this.onSort,
    required this.showActions,
    required this.density,
  });

  final List<DataColumnSpec<T>> columns;
  final TableQuery query;
  final ValueChanged<String> onSort;
  final bool showActions;
  final TableDensity density;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.surfaceContainerHigh,
      padding: EdgeInsets.symmetric(
        horizontal: Insets.lg,
        vertical: density.headerPadding,
      ),
      child: Row(
        children: [
          for (final column in columns)
            _cell(
              column,
              child: _HeaderCell<T>(
                column: column,
                active: query.sortField == column.field,
                ascending: query.ascending,
                onTap: column.sortable ? () => onSort(column.field) : null,
              ),
            ),
          if (showActions)
            const SizedBox(width: ReusableDataTable._actionsWidth),
        ],
      ),
    );
  }

  Widget _cell(DataColumnSpec<T> column, {required Widget child}) =>
      column.width != null
      ? SizedBox(width: column.width, child: child)
      : Expanded(flex: column.flex, child: child);
}

class _HeaderCell<T> extends StatelessWidget {
  const _HeaderCell({
    required this.column,
    required this.active,
    required this.ascending,
    required this.onTap,
  });

  final DataColumnSpec<T> column;
  final bool active;
  final bool ascending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Insets.xs),
        child: Row(
          mainAxisAlignment: column.numeric
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                column.label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: column.numeric ? TextAlign.right : TextAlign.left,
                style: context.text.labelSmall?.copyWith(
                  color: active ? colors.onSurface : colors.onSurfaceVariant,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            // The arrow's width is reserved on every sortable column, so
            // headings do not shuffle sideways when the sort column changes.
            if (column.sortable)
              SizedBox(
                width: 16,
                child: active
                    ? Icon(
                        ascending
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 13,
                        color: colors.primary,
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _BodyRow<T> extends StatelessWidget {
  const _BodyRow({
    required this.row,
    required this.columns,
    required this.onTap,
    required this.rowActions,
    required this.density,
  });

  final T row;
  final List<DataColumnSpec<T>> columns;
  final void Function(T row)? onTap;
  final List<DataRowAction<T>> rowActions;
  final TableDensity density;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap == null ? null : () => onTap!(row),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: density.rowPadding,
        ),
        child: Row(
          children: [
            for (final column in columns)
              _cell(
                column,
                child: Align(
                  alignment: column.numeric
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: column.hasCustomCell
                      ? column.build(context, row)
                      : Text(
                          column.value(row),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: column.numeric
                              ? TextAlign.right
                              : TextAlign.left,
                          style: context.text.bodyMedium,
                        ),
                ),
              ),
            if (rowActions.isNotEmpty)
              SizedBox(
                width: ReusableDataTable._actionsWidth,
                child: RowActionsMenu<T>(row: row, actions: rowActions),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cell(DataColumnSpec<T> column, {required Widget child}) =>
      column.width != null
      ? SizedBox(width: column.width, child: child)
      : Expanded(
          flex: column.flex,
          child: Padding(
            padding: const EdgeInsets.only(right: Insets.sm),
            child: child,
          ),
        );
}

// ---------------------------------------------------------------------------
// Card form
// ---------------------------------------------------------------------------

class _Cards<T> extends StatelessWidget {
  const _Cards({
    required this.columns,
    required this.rows,
    required this.onRowTap,
    required this.rowActions,
    required this.density,
  });

  final List<DataColumnSpec<T>> columns;
  final List<T> rows;
  final void Function(T row)? onRowTap;
  final List<DataRowAction<T>> rowActions;
  final TableDensity density;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) SizedBox(height: density.cardGap),
          DataRowCard<T>(
            row: rows[i],
            columns: columns,
            actions: rowActions,
            onTap: onRowTap == null ? null : () => onRowTap!(rows[i]),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pagination
// ---------------------------------------------------------------------------

class _Pagination extends StatelessWidget {
  const _Pagination({required this.slice, required this.onPageChanged});

  final PageSlice slice;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final showing = slice.totalCount == 0
        ? 'No results'
        : 'Showing ${slice.firstRow}–${slice.lastRow} of ${slice.totalCount}';

    return Padding(
      padding: const EdgeInsets.only(top: Insets.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final label = Text(
            showing,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          );

          final controls = _PageControls(
            slice: slice,
            onPageChanged: onPageChanged,
            // Numbered buttons need room; below this only the arrows fit.
            compact: constraints.maxWidth < 420,
          );

          if (constraints.maxWidth < 340) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [label, const SizedBox(height: Insets.sm), controls],
            );
          }

          return Row(
            children: [
              Expanded(child: label),
              const SizedBox(width: Insets.md),
              controls,
            ],
          );
        },
      ),
    );
  }
}

class _PageControls extends StatelessWidget {
  const _PageControls({
    required this.slice,
    required this.onPageChanged,
    required this.compact,
  });

  final PageSlice slice;
  final ValueChanged<int> onPageChanged;
  final bool compact;

  /// A window of page numbers around the current page, so a 40-page table
  /// does not render 40 buttons.
  List<int> get _window {
    const span = 5;
    if (slice.pageCount <= span) {
      return [for (var i = 0; i < slice.pageCount; i++) i];
    }
    var start = slice.page - 2;
    if (start < 0) start = 0;
    if (start + span > slice.pageCount) start = slice.pageCount - span;
    return [for (var i = start; i < start + span; i++) i];
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Previous page',
          visualDensity: VisualDensity.compact,
          onPressed: slice.hasPrevious
              ? () => onPageChanged(slice.page - 1)
              : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        if (compact)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.sm),
            child: Text(
              '${slice.page + 1} / ${slice.pageCount}',
              style: context.text.labelLarge,
            ),
          )
        else
          for (final page in _window)
            _PageButton(
              page: page,
              selected: page == slice.page,
              onTap: () => onPageChanged(page),
            ),
        IconButton(
          tooltip: 'Next page',
          visualDensity: VisualDensity.compact,
          onPressed: slice.hasNext ? () => onPageChanged(slice.page + 1) : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.page,
    required this.selected,
    required this.onTap,
  });

  final int page;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: selected ? colors.primary : Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          side: BorderSide(
            color: selected ? colors.primary : context.semantic.hairline,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 32,
            width: 32,
            child: Center(
              child: Text(
                '${page + 1}',
                style: context.text.labelLarge?.copyWith(
                  color: selected ? colors.onPrimary : colors.onSurface,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DefaultEmptyState extends StatelessWidget {
  const _DefaultEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: Insets.xxl),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: Radii.card,
        border: Border.all(color: context.semantic.hairline),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 32,
            color: colors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: Insets.md),
          Text('No results', style: context.text.titleSmall),
          const SizedBox(height: Insets.xs),
          Text(
            'Try a different search or clear your filters.',
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
