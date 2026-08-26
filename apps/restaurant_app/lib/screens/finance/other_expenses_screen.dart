import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_finance.dart';
import '../../models/other_expense.dart';
import '../../providers/other_expenses_provider.dart';
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
import 'other_expense_filter_panel.dart';
import '../../widgets/dialogs/other_expense_form_dialog.dart';

class OtherExpensesScreen extends ConsumerWidget {
  const OtherExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(otherExpensesQueryProvider);
    final slice = ref.watch(otherExpensesSliceProvider);
    final summary = ref.watch(otherExpensesSummaryProvider);
    final filters = ref.watch(otherExpenseFiltersProvider);
    final notifier = ref.read(otherExpensesQueryProvider.notifier);

    return Column(
      children: [
        const FinanceTabBar(active: FinanceTab.expenses),
        Expanded(
          child: DataPageScaffold(
            title: 'Other expenses',
            subtitle: 'Ad-hoc costs outside inventory purchases and payroll',
            actions: dataPageExportActions<OtherExpense>(
              context: context,
              columns: otherExpenseColumns,
              rows: ref.watch(filteredOtherExpensesProvider),
              title: 'Other expenses',
              subtitle: _exportSubtitle(filters, query.search),
            ),
            primaryAction: context.isMobile
                ? SizedBox(
                    height: 40,
                    width: 40,
                    child: Tooltip(
                      message: 'Add expense',
                      child: Material(
                        color: context.colors.primary,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 20,
                          onPressed: () => showOtherExpenseFormDialog(context),
                          icon: const Icon(Icons.add_rounded),
                          color: context.colors.onPrimary,
                        ),
                      ),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: () => showOtherExpenseFormDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add expense'),
                  ),
            metrics: [
              SummaryMetricCard(
                label: 'Total expenses',
                value: Fmt.moneyCompact(summary.total),
                trend: 'In current view',
                icon: Icons.arrow_upward_rounded,
              ),
              SummaryMetricCard(
                label: 'Entries',
                value: '${summary.entryCount}',
                trend: 'Tracked in view',
                icon: Icons.receipt_long_rounded,
                accent: context.colors.tertiary,
              ),
              SummaryMetricCard(
                label: 'Largest category',
                value: summary.largestCategoryLabel,
                trend: Fmt.moneyCompact(summary.largestCategoryAmount),
                icon: Icons.category_rounded,
                accent: context.semantic.warning,
              ),
            ],
            toolbar: DataTableToolbar(
              searchHint: 'Search description, payee or category',
              searchValue: query.search,
              onSearchChanged: notifier.setSearch,
              activeFilterCount: filters.activeCount,
              onClearFilters: ref.read(otherExpenseFiltersProvider.notifier).clear,
              filterBuilder: (_) => const OtherExpenseFilterPanel(),
              sortOptions: const [
                SortOption(label: 'Date', field: OtherExpenseSort.date),
                SortOption(label: 'Category', field: OtherExpenseSort.category),
                SortOption(label: 'Description', field: OtherExpenseSort.description),
                SortOption(label: 'Amount', field: OtherExpenseSort.amount),
                SortOption(label: 'Payment', field: OtherExpenseSort.payment),
              ],
              sortField: query.sortField,
              sortAscending: query.ascending,
              onSortChanged: (field, ascending) => notifier.setSort(field, ascending: ascending),
            ),
            table: ReusableDataTable<OtherExpense>(
              columns: otherExpenseColumns,
              slice: slice,
              query: query,
              onSort: notifier.toggleSort,
              onPageChanged: notifier.setPage,
              rowActions: [
                DataRowAction(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  onSelected: (c, e) {},
                ),
                DataRowAction(
                  label: 'Delete',
                  icon: Icons.delete_outline_rounded,
                  isDestructive: true,
                  onSelected: (c, e) => _confirmDelete(c, ref, e),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, OtherExpense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${expense.description}?'),
        content: const Text('This expense will be removed and cannot be recovered.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ref.read(otherExpensesProvider.notifier).delete(expense.id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${expense.description} deleted')));
    }
  }

  static String _exportSubtitle(OtherExpenseFilters filters, String search) {
    final parts = <String>[
      if (filters.categoryIds.isNotEmpty) filters.categoryIds.map((id) => MockFinance.expenseCategoryLabel(id)).join(', '),
      if (filters.payments.isNotEmpty) filters.payments.map((p) => p.label).join(', '),
      if (filters.dateRange != null) 'between ${filters.dateRange!.start.month}/${filters.dateRange!.start.day} and ${filters.dateRange!.end.month}/${filters.dateRange!.end.day}',
      if (search.trim().isNotEmpty) 'matching "$search"',
    ];
    return parts.isEmpty ? 'All entries' : parts.join(' · ');
  }
}

final otherExpenseColumns = <DataColumnSpec<OtherExpense>>[
  DataColumnSpec(label: 'Date', field: OtherExpenseSort.date, flex: 2, value: (e) => Fmt.dayMonth(e.date)),
  DataColumnSpec(label: 'Description', field: OtherExpenseSort.description, role: ColumnRole.primary, flex: 5, value: (e) => e.description, cellBuilder: (c, e) => _DescriptionCell(expense: e)),
  DataColumnSpec(label: 'Category', field: OtherExpenseSort.category, flex: 3, minTableWidth: 700, value: (e) => MockFinance.expenseCategoryLabel(e.categoryId)),
  DataColumnSpec(label: 'Payment', field: OtherExpenseSort.payment, flex: 2, minTableWidth: 860, value: (e) => e.paymentType.label),
  DataColumnSpec(label: 'Amount', field: OtherExpenseSort.amount, flex: 2, numeric: true, value: (e) => Fmt.money(e.amount)),
];

class _DescriptionCell extends StatelessWidget {
  const _DescriptionCell({required this.expense});
  final OtherExpense expense;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: Text(expense.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w700))),
            if (expense.receipt != null) ...[const SizedBox(width: 8), Icon(Icons.attach_file_rounded, size: 14, color: context.colors.onSurfaceVariant)],
          ],
        ),
        Text(expense.payee.isNotEmpty ? expense.payee : '—', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
      ],
    );
  }
}
