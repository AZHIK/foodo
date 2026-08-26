import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_finance.dart';
import '../../models/other_income.dart';
import '../../providers/other_incomes_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../../widgets/data_page/data_column_spec.dart';
import '../../widgets/data_page/data_page_scaffold.dart';
import '../../widgets/data_page/data_table_toolbar.dart';
import '../../widgets/data_page/export_actions.dart';
import '../../widgets/data_page/reusable_data_table.dart';
import '../../widgets/data_page/summary_metric_card.dart';
import '../../widgets/finance/finance_tab_bar.dart';
import 'other_income_filter_panel.dart';
import '../../widgets/dialogs/other_income_form_dialog.dart';

class OtherIncomesScreen extends ConsumerWidget {
  const OtherIncomesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(otherIncomesQueryProvider);
    final slice = ref.watch(otherIncomesSliceProvider);
    final summary = ref.watch(otherIncomesSummaryProvider);
    final filters = ref.watch(otherIncomeFiltersProvider);
    final notifier = ref.read(otherIncomesQueryProvider.notifier);

    return Column(
      children: [
        const FinanceTabBar(active: FinanceTab.incomes),
        Expanded(
          child: DataPageScaffold(
            title: 'Other incomes',
            subtitle: 'Ad-hoc revenue outside point-of-sale transactions',
            actions: dataPageExportActions<OtherIncome>(
              context: context,
              columns: otherIncomeColumns,
              rows: ref.watch(filteredOtherIncomesProvider),
              title: 'Other incomes',
              subtitle: _exportSubtitle(filters, query.search),
            ),
            primaryAction: context.isMobile
                ? SizedBox(
                    height: 40,
                    width: 40,
                    child: Tooltip(
                      message: 'Add income',
                      child: Material(
                        color: context.colors.primary,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 20,
                          onPressed: () => showOtherIncomeFormDialog(context),
                          icon: const Icon(Icons.add_rounded),
                          color: context.colors.onPrimary,
                        ),
                      ),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: () => showOtherIncomeFormDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add income'),
                  ),
            metrics: [
              SummaryMetricCard(
                label: 'Total other income',
                value: Fmt.moneyCompact(summary.total),
                trend: 'In current view',
                icon: Icons.arrow_downward_rounded,
              ),
              SummaryMetricCard(
                label: 'Entries',
                value: '${summary.entryCount}',
                trend: 'Tracked in view',
                icon: Icons.receipt_long_rounded,
                accent: context.colors.tertiary,
              ),
              SummaryMetricCard(
                label: 'Average entry',
                value: Fmt.money(summary.average),
                trend: summary.entryCount == 0 ? 'No entries' : '${summary.entryCount} sources',
                icon: Icons.trending_up_rounded,
                accent: context.semantic.success,
              ),
            ],
            toolbar: DataTableToolbar(
              searchHint: 'Search description, source or category',
              searchValue: query.search,
              onSearchChanged: notifier.setSearch,
              activeFilterCount: filters.activeCount,
              onClearFilters: ref.read(otherIncomeFiltersProvider.notifier).clear,
              filterBuilder: (_) => const OtherIncomeFilterPanel(),
              sortOptions: const [
                SortOption(label: 'Date', field: OtherIncomeSort.date),
                SortOption(label: 'Category', field: OtherIncomeSort.category),
                SortOption(label: 'Description', field: OtherIncomeSort.description),
                SortOption(label: 'Amount', field: OtherIncomeSort.amount),
                SortOption(label: 'Payment', field: OtherIncomeSort.payment),
              ],
              sortField: query.sortField,
              sortAscending: query.ascending,
              onSortChanged: (field, ascending) => notifier.setSort(field, ascending: ascending),
            ),
            table: ReusableDataTable<OtherIncome>(
              columns: otherIncomeColumns,
              slice: slice,
              query: query,
              onSort: notifier.toggleSort,
              onPageChanged: notifier.setPage,
              rowActions: [
                DataRowAction(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  onSelected: (c, i) {},
                ),
                DataRowAction(
                  label: 'Delete',
                  icon: Icons.delete_outline_rounded,
                  isDestructive: true,
                  onSelected: (c, i) => _confirmDelete(c, ref, i),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, OtherIncome income) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${income.description}?'),
        content: const Text('This income entry will be removed and cannot be recovered.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ref.read(otherIncomesProvider.notifier).delete(income.id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${income.description} deleted')));
    }
  }

  static String _exportSubtitle(OtherIncomeFilters filters, String search) {
    final parts = <String>[
      if (filters.categoryIds.isNotEmpty) filters.categoryIds.map((id) => MockFinance.incomeCategoryLabel(id)).join(', '),
      if (filters.payments.isNotEmpty) filters.payments.map((p) => p.label).join(', '),
      if (filters.dateRange != null) 'between ${filters.dateRange!.start.month}/${filters.dateRange!.start.day} and ${filters.dateRange!.end.month}/${filters.dateRange!.end.day}',
      if (search.trim().isNotEmpty) 'matching "$search"',
    ];
    return parts.isEmpty ? 'All entries' : parts.join(' · ');
  }
}

final otherIncomeColumns = <DataColumnSpec<OtherIncome>>[
  DataColumnSpec(label: 'Date', field: OtherIncomeSort.date, flex: 2, value: (i) => Fmt.dayMonth(i.date)),
  DataColumnSpec(label: 'Description', field: OtherIncomeSort.description, role: ColumnRole.primary, flex: 5, value: (i) => i.description, cellBuilder: (c, i) => _DescriptionCell(income: i)),
  DataColumnSpec(label: 'Category', field: OtherIncomeSort.category, flex: 3, minTableWidth: 700, value: (i) => MockFinance.incomeCategoryLabel(i.categoryId)),
  DataColumnSpec(label: 'Payment', field: OtherIncomeSort.payment, flex: 2, minTableWidth: 860, value: (i) => i.paymentType.label),
  DataColumnSpec(label: 'Amount', field: OtherIncomeSort.amount, flex: 2, numeric: true, value: (i) => Fmt.money(i.amount)),
];

class _DescriptionCell extends StatelessWidget {
  const _DescriptionCell({required this.income});
  final OtherIncome income;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: Text(income.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w700))),
            if (income.receipt != null) ...[const SizedBox(width: 8), Icon(Icons.attach_file_rounded, size: 14, color: context.colors.onSurfaceVariant)],
          ],
        ),
        Text(income.source.isNotEmpty ? income.source : '—', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
      ],
    );
  }
}
