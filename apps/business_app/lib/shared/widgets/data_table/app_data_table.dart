import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../app_responsive_layout.dart';
import '../cards/app_card.dart';
import '../feedback/empty_state.dart';
import '../buttons/app_secondary_button.dart';
import '../forms/app_search_field.dart';
import 'export_service.dart';

class AppDataColumn<T> {
  const AppDataColumn({
    required this.key,
    required this.label,
    required this.valueExtractor,
    this.sortable = true,
    this.searchable = true,
    this.isPrimary = false,
    this.width,
    this.flex = 1,
    this.cellBuilder,
  });

  final String key;
  final String label;
  final dynamic Function(T row) valueExtractor;
  final bool sortable;
  final bool searchable;
  final bool isPrimary;
  final double? width;
  final int flex;
  final Widget Function(BuildContext context, T row, dynamic value)?
  cellBuilder;
}

class AppDataTable<T> extends StatefulWidget {
  const AppDataTable({
    super.key,
    required this.rows,
    required this.columns,
    this.pageSizes = const [10, 25, 50, 100],
    this.initialPageSize = 25,
    this.showSearch = true,
    this.showExport = true,
    this.showPagination = true,
    this.emptyStateIcon = Icons.inbox_outlined,
    this.emptyStateTitle = 'Nothing here yet',
    this.emptyStateSubtitle,
    this.emptyStateAction,
    this.rowOnTap,
    this.rowOnLongPress,
    this.exportFilenamePrefix = 'export',
    /// When true, the table sizes itself to its content instead of expanding
    /// to fill available space. Required when the table is placed inside
    /// another scrollable (e.g. a [SingleChildScrollView]).
    this.shrinkWrap = false,
  });

  final List<T> rows;
  final List<AppDataColumn<T>> columns;
  final List<int> pageSizes;
  final int initialPageSize;
  final bool showSearch;
  final bool showExport;
  final bool showPagination;
  final IconData emptyStateIcon;
  final String emptyStateTitle;
  final String? emptyStateSubtitle;
  final Widget? emptyStateAction;
  final void Function(T row)? rowOnTap;
  final void Function(T row)? rowOnLongPress;
  final String exportFilenamePrefix;
  final bool shrinkWrap;

  @override
  State<AppDataTable<T>> createState() => _AppDataTableState<T>();
}

class _AppDataTableState<T> extends State<AppDataTable<T>> {
  String _searchQuery = '';
  Timer? _searchDebounce;
  late int _pageSize;
  int _currentPage = 0;
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _pageSize = widget.initialPageSize;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  List<T> get _sortedFiltered {
    var out = widget.rows.toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      final searchable = widget.columns.where((c) => c.searchable).toList();
      out = out.where((row) {
        return searchable.any((c) {
          final v = c.valueExtractor(row);
          return v?.toString().toLowerCase().contains(q) ?? false;
        });
      }).toList();
    }
    final sortIdx = _sortColumnIndex;
    if (sortIdx != null) {
      final col = widget.columns[sortIdx];
      if (col.sortable) {
        int compare(T a, T b) {
          final av = col.valueExtractor(a);
          final bv = col.valueExtractor(b);
          final int cmp;
          if (av is Comparable && bv is Comparable) {
            cmp = av.compareTo(bv);
          } else {
            cmp = av.toString().compareTo(bv.toString());
          }
          return _sortAscending ? cmp : -cmp;
        }

        out.sort(compare);
      }
    }
    return out;
  }

  int get _totalRows => _sortedFiltered.length;
  int get _totalPages {
    if (_totalRows == 0) return 0;
    return (_totalRows / _pageSize).ceil();
  }

  List<T> get _paged {
    final all = _sortedFiltered;
    if (!widget.showPagination) return all;
    final start = _currentPage * _pageSize;
    if (start >= all.length) return const [];
    final end = (start + _pageSize).clamp(0, all.length);
    return all.sublist(start, end);
  }

  void _onSearchChanged(String v) {
    // AppSearchField already debounces its onChanged callback, so we
    // update state directly here to avoid a second, stacked delay.
    if (!mounted) return;
    setState(() {
      _searchQuery = v.trim();
      _currentPage = 0;
    });
  }

  void _onSort(int index) {
    final col = widget.columns[index];
    if (!col.sortable) return;
    setState(() {
      if (_sortColumnIndex == index) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = index;
        _sortAscending = true;
      }
    });
  }

  Future<void> _export(ExportFormat format) async {
    final service = ExportService();
    final colDefs = widget.columns
        .map(
          (c) => ExportColumn(
            key: c.key,
            label: c.label,
            valueExtractor: (r) => c.valueExtractor(r as T),
          ),
        )
        .toList();
    final all = _sortedFiltered;
    try {
      if (format == ExportFormat.excel) {
        await service.exportExcel(
          context: context,
          columns: colDefs,
          rows: all.cast<dynamic>(),
          filename: '${widget.exportFilenamePrefix}_${_timestamp()}.xlsx',
        );
      } else {
        await service.exportPdf(
          context: context,
          columns: colDefs,
          rows: all.cast<dynamic>(),
          filename: '${widget.exportFilenamePrefix}_${_timestamp()}.pdf',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

@override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final isNarrow = AppResponsiveLayout.isMobileWidth(width);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showSearch || widget.showExport)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppDimensions.spaceMD,
                  right: AppDimensions.spaceMD,
                  top: AppDimensions.spaceMD,
                  bottom: AppDimensions.spaceSM,
                ),
                child: _buildToolbar(isNarrow),
              ),
            if (widget.shrinkWrap)
              _sortedFiltered.isEmpty
                  ? AppEmptyState(
                      icon: widget.emptyStateIcon,
                      title: widget.emptyStateTitle,
                      subtitle: widget.emptyStateSubtitle ??
                          (_searchQuery.isNotEmpty
                              ? 'No results for "$_searchQuery".'
                              : null),
                      action: widget.emptyStateAction,
                      compact: true,
                    )
                  : isNarrow
                      ? _buildCardList()
                      : _buildDesktopTable()
            else
              Expanded(
                child: _sortedFiltered.isEmpty
                    ? AppEmptyState(
                        icon: widget.emptyStateIcon,
                        title: widget.emptyStateTitle,
                        subtitle: widget.emptyStateSubtitle ??
                            (_searchQuery.isNotEmpty
                                ? 'No results for "$_searchQuery".'
                                : null),
                        action: widget.emptyStateAction,
                        compact: true,
                      )
                    : isNarrow
                        ? _buildCardList()
                        : _buildDesktopTable(),
              ),
            if (widget.showPagination && _sortedFiltered.isNotEmpty)
              _buildPagination(),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(bool isNarrow) {
    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showSearch)
            AppSearchField(onChanged: _onSearchChanged, hintText: 'Search...'),
          if (widget.showSearch && widget.showExport)
            const SizedBox(height: AppDimensions.spaceSM),
          if (widget.showExport)
            Align(
              alignment: Alignment.centerRight,
              child: _ExportMenu(onSelected: _export),
            ),
        ],
      );
    }
    return Row(
      children: [
        if (widget.showSearch)
          Expanded(
            child: AppSearchField(
              onChanged: _onSearchChanged,
              hintText: 'Search...',
            ),
          ),
        if (widget.showSearch && widget.showExport)
          const SizedBox(width: AppDimensions.spaceMD),
        if (widget.showExport) _ExportMenu(onSelected: _export),
      ],
    );
  }

  Widget _buildDesktopTable() {
    final cs = Theme.of(context).colorScheme;
    final cols = widget.columns.map((c) {
      final idx = widget.columns.indexOf(c);
      return DataColumn(
        label: Text(
          c.label,
          style: AppTextStyles.labelLarge.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onSort: c.sortable ? (_, _) => _onSort(idx) : null,
        numeric: false,
      );
    }).toList();
    final rows = _paged.asMap().entries.map((e) {
      final rowIdx = e.key;
      final row = e.value;
      final cells = widget.columns.map((c) {
        final val = c.valueExtractor(row);
        return DataCell(
          c.cellBuilder != null
              ? c.cellBuilder!(context, row, val)
              : Text(
                  _formatValue(val),
                  style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
          onTap: widget.rowOnTap != null ? () => widget.rowOnTap!(row) : null,
          onLongPress: widget.rowOnLongPress != null
              ? () => widget.rowOnLongPress!(row)
              : null,
        );
      }).toList();
      return DataRow.byIndex(
        index: rowIdx,
        cells: cells,
        color: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return cs.primary.withValues(alpha: 0.08);
          }
          return rowIdx.isEven
              ? cs.surface
              : cs.surfaceContainerLowest.withValues(alpha: 0.5);
        }),
        onSelectChanged: widget.rowOnTap == null
            ? null
            : (_) => widget.rowOnTap!(row),
      );
    }).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = (constraints.maxWidth - AppDimensions.spaceSM * 2).clamp(
          0.0,
          double.infinity,
        );
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceSM),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: tableWidth,
                maxWidth: tableWidth,
              ),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                ),
                clipBehavior: Clip.antiAlias,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerTheme: DividerThemeData(
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                      thickness: 0.5,
                      space: 0,
                    ),
                    dataTableTheme: DataTableThemeData(
                      headingRowColor: WidgetStatePropertyAll(
                        cs.surfaceContainerHighest,
                      ),
                      dataRowMaxHeight: 56,
                      headingRowHeight: 52,
                      columnSpacing: AppDimensions.spaceMD,
                      horizontalMargin: AppDimensions.spaceMD,
                    ),
                  ),
                  child: DataTable(
                    showCheckboxColumn: false,
                    showBottomBorder: false,
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    columns: cols,
                    rows: rows,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardList() {
    final primaryCols = widget.columns.where((c) => c.isPrimary).toList();
    final secondaryCols = widget.columns.where((c) => !c.isPrimary).toList();
    final effectivePrimary = primaryCols.isEmpty
        ? widget.columns.take(2).toList()
        : primaryCols;
    final effectiveSecondary = secondaryCols.isEmpty
        ? widget.columns.skip(2).take(4).toList()
        : secondaryCols.take(4).toList();
    return ListView.separated(
      shrinkWrap: widget.shrinkWrap,
      physics: widget.shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMD,
        vertical: AppDimensions.spaceSM,
      ),
      itemCount: _paged.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: AppDimensions.spaceSM),
      itemBuilder: (ctx, i) {
        final row = _paged[i];
        return AppCard.elevated(
          onTap: widget.rowOnTap != null ? () => widget.rowOnTap!(row) : null,
          onLongPress: widget.rowOnLongPress != null
              ? () => widget.rowOnLongPress!(row)
              : null,
          padding: const EdgeInsets.all(AppDimensions.spaceMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (effectivePrimary.isNotEmpty)
                          _PrimaryCell(
                            label: effectivePrimary.first.label,
                            value: effectivePrimary.first.valueExtractor(row),
                            builder: effectivePrimary.first.cellBuilder,
                            row: row,
                          ),
                      ],
                    ),
                  ),
                  if (effectivePrimary.length >= 2)
                    const SizedBox(width: AppDimensions.spaceMD),
                  if (effectivePrimary.length >= 2)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _PrimaryCell(
                          label: effectivePrimary[1].label,
                          value: effectivePrimary[1].valueExtractor(row),
                          builder: effectivePrimary[1].cellBuilder,
                          row: row,
                          alignRight: true,
                        ),
                      ],
                    ),
                ],
              ),
              if (effectiveSecondary.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.spaceSM),
                Wrap(
                  spacing: AppDimensions.spaceMD,
                  runSpacing: AppDimensions.spaceXS,
                  children: [
                    for (final col in effectiveSecondary)
                      _SecondaryCell(
                        label: col.label,
                        value: col.valueExtractor(row),
                        builder: col.cellBuilder,
                        row: row,
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

Widget _buildPagination() {
    final cs = Theme.of(context).colorScheme;
    final total = _totalRows;
    final totalPages = _totalPages;
    final canPrev = _currentPage > 0;
    final canNext = _currentPage < totalPages - 1;
    final start = total == 0 ? 0 : _currentPage * _pageSize + 1;
    final end = (_currentPage * _pageSize + _pageSize).clamp(0, total);
    final showPageSize = widget.pageSizes.length > 1;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 400;
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceMD,
            vertical: AppDimensions.spaceSM,
          ),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: cs.outlineVariant)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '$start\u2013$end of $total',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showPageSize && !compact) ...[
                const SizedBox(width: AppDimensions.spaceMD),
                _PageSizeSelector(
                  value: _pageSize,
                  options: widget.pageSizes,
                  onChanged: (v) {
                    setState(() {
                      _pageSize = v;
                      _currentPage = 0;
                    });
                  },
                ),
                const SizedBox(width: AppDimensions.spaceMD),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: canPrev
                        ? () => setState(() {
                              _currentPage--;
                            })
                        : null,
                    icon: const Icon(Icons.chevron_left),
                    visualDensity: VisualDensity.compact,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceSM,
                    ),
                    child: Text(
                      '${_currentPage + 1} / ${totalPages == 0 ? 1 : totalPages}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: canNext
                        ? () => setState(() {
                              _currentPage++;
                            })
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrimaryCell<T> extends StatelessWidget {
  const _PrimaryCell({
    required this.label,
    required this.value,
    required this.builder,
    required this.row,
    this.alignRight = false,
  });
  final String label;
  final dynamic value;
  final Widget Function(BuildContext, T, dynamic)? builder;
  final T row;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final child = builder != null
        ? builder!(context, row, value)
        : Text(
            _formatValue(value),
            style: AppTextStyles.titleMedium.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: alignRight ? TextAlign.right : TextAlign.left,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: AppDimensions.spaceXXS),
        if (alignRight)
          Align(alignment: Alignment.centerRight, child: child)
        else
          child,
      ],
    );
  }
}

class _SecondaryCell<T> extends StatelessWidget {
  const _SecondaryCell({
    required this.label,
    required this.value,
    required this.builder,
    required this.row,
  });
  final String label;
  final dynamic value;
  final Widget Function(BuildContext, T, dynamic)? builder;
  final T row;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inner = builder != null
        ? builder!(context, row, value)
        : Text(
            _formatValue(value),
            style: AppTextStyles.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          );
    return RichText(
      text: TextSpan(
        style: AppTextStyles.bodySmall,
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
          ),
          WidgetSpan(child: inner, alignment: PlaceholderAlignment.middle),
        ],
      ),
    );
  }
}

class _ExportMenu extends StatelessWidget {
  const _ExportMenu({required this.onSelected});
  final void Function(ExportFormat) onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ExportFormat>(
      onSelected: onSelected,
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: ExportFormat.excel,
          child: Row(
            children: [
              Icon(Icons.table_chart_outlined, size: 18),
              SizedBox(width: AppDimensions.spaceSM),
              Text('Export to Excel', style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
        const PopupMenuItem(
          value: ExportFormat.pdf,
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf_outlined, size: 18),
              SizedBox(width: AppDimensions.spaceSM),
              Text('Export to PDF', style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
      child: const AppSecondaryButton(
        label: 'Export',
        icon: Icons.download_outlined,
        expanded: false,
      ),
    );
  }
}

class _PageSizeSelector extends StatelessWidget {
  const _PageSizeSelector({
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final effectiveOptions = options.contains(value)
        ? options
        : ([...options, value]..sort());
    return SizedBox(
      width: 140,
      child: InputDecorator(
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceSM,
            vertical: AppDimensions.spaceXS,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: value,
            isDense: true,
            isExpanded: true,
            style: AppTextStyles.bodyMedium,
            items: effectiveOptions
                .map(
                  (n) => DropdownMenuItem(
                    value: n,
                    child: Text(
                      '$n / page',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => v != null ? onChanged(v) : null,
          ),
        ),
      ),
    );
  }
}

String _formatValue(dynamic v) {
  if (v == null) return '\u2014';
  if (v is DateTime) return _formatDate(v);
  return v.toString();
}

String _formatDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final mo = d.month.toString().padLeft(2, '0');
  final dy = d.day.toString().padLeft(2, '0');
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  if (d.hour == 0 && d.minute == 0) return '$y-$mo-$dy';
  return '$y-$mo-$dy $hh:$mm';
}

String _timestamp() {
  final n = DateTime.now();
  final y = n.year.toString();
  final mo = _pad2(n.month);
  final dy = _pad2(n.day);
  final hh = _pad2(n.hour);
  final mm = _pad2(n.minute);
  return '$y$mo${dy}_$hh$mm';
}

String _pad2(int v) => v.toString().padLeft(2, '0');
