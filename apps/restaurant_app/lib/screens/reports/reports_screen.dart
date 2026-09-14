import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/permission.dart';
import '../../providers/permissions_provider.dart';
import '../../providers/reports_provider.dart';
import '../../services/inventory_api_service.dart';
import '../../services/pos_reports_api_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../../widgets/data_page/data_column_spec.dart';
import '../../widgets/data_page/export_actions.dart';
import '../../widgets/data_page/summary_metric_card.dart';

/// Business reports, computed server-side per the shared date window.
///
/// Every number on this screen comes from an aggregation endpoint — nothing
/// is rolled up from the local cache, so the screen can never disagree with
/// the server about what a day earned. Sections read while empty rather
/// than showing demo figures: invented takings would be worse than blank.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  Future<void> _pickRange(BuildContext context, WidgetRef ref) async {
    final current = ref.read(reportsDateFilterProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: current.from == null && current.to == null
          ? null
          : DateTimeRange(
              start:
                  current.from ??
                  DateTime.now().subtract(const Duration(days: 30)),
              end: current.to ?? DateTime.now(),
            ),
    );
    if (picked == null) return;
    ref
        .read(reportsDateFilterProvider.notifier)
        .setRange(picked.start, picked.end);
    await refreshAllReports(ref);
  }

  Future<void> _clearRange(WidgetRef ref) async {
    ref.read(reportsDateFilterProvider.notifier).clear();
    await refreshAllReports(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(reportsDateFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Filter by date',
            onPressed: () => _pickRange(context, ref),
            icon: Badge(
              isLabelVisible: filter.from != null || filter.to != null,
              child: const Icon(Icons.calendar_month_outlined),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => refreshAllReports(ref),
        child: ListView(
          padding: const EdgeInsets.all(Insets.lg),
          children: [
            if (filter.from != null || filter.to != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Insets.md),
                child: InputChip(
                  label: Text(
                    '${filter.from == null ? '…' : Fmt.dayMonth(filter.from!)}'
                    ' – '
                    '${filter.to == null ? '…' : Fmt.dayMonth(filter.to!)}',
                  ),
                  deleteIcon: const Icon(Icons.clear_rounded, size: 16),
                  onDeleted: () => _clearRange(ref),
                ),
              ),
            const _TakingsSection(),
            const SizedBox(height: Insets.xl),
            const _ItemMixSection(),
            const SizedBox(height: Insets.xl),
            const _StaffSection(),
            const SizedBox(height: Insets.xl),
            const _FinanceSection(),
            const SizedBox(height: Insets.xl),
            const _WasteSection(),
            const SizedBox(height: Insets.xl),
            const _ProductionSection(),
            const SizedBox(height: Insets.xl),
            const _ValuationSection(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared section chrome
// ---------------------------------------------------------------------------

/// A report section: title, optional export buttons, and its body.
///
/// Export buttons appear only for `reports.export` holders; everyone else
/// still reads the numbers. Columns drive the exporters, so the file says
/// what the screen said.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.columns,
    required this.rows,
    required this.exportTitle,
    required this.body,
  });

  final String title;
  final List<DataColumnSpec<dynamic>> columns;
  final List<dynamic> rows;
  final String exportTitle;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: context.text.titleMedium),
              ),
              if (ref.watch(
                hasPermissionProvider(AppPermissions.reportsExport),
              ))
                ...dataPageExportActions<dynamic>(
                  context: context,
                  columns: columns,
                  rows: rows,
                  title: exportTitle,
                  subtitle: title,
                ),
            ],
          ),
          const SizedBox(height: Insets.md),
          body,
        ],
      ),
    );
  }
}

double _d(Decimal value) => double.parse(value.toString());

String _money(Decimal value) => Fmt.money(_d(value));

// ---------------------------------------------------------------------------
// Takings
// ---------------------------------------------------------------------------

final _takingsColumns = <DataColumnSpec<DailyTakingsDayDto>>[
  DataColumnSpec(
    label: 'Date',
    field: 'date',
    value: (r) => r.date.toIso8601String().substring(0, 10),
  ),
  DataColumnSpec(
    label: 'Revenue',
    field: 'revenue',
    numeric: true,
    value: (r) => _money(r.revenue),
  ),
  DataColumnSpec(
    label: 'Orders',
    field: 'count',
    numeric: true,
    value: (r) => '${r.salesCount}',
  ),
  DataColumnSpec(
    label: 'Avg ticket',
    field: 'avg',
    numeric: true,
    value: (r) => _money(r.avgTicket),
  ),
];

class _TakingsSection extends ConsumerWidget {
  const _TakingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(dailyTakingsProvider).valueOrNull ?? const [];
    var revenue = 0.0;
    var orders = 0;
    for (final day in days) {
      revenue += _d(day.revenue);
      orders += day.salesCount;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SummaryMetricCard(
                label: 'Revenue',
                value: Fmt.money(revenue),
                trend: '$orders orders',
                icon: Icons.payments_outlined,
                accent: context.semantic.success,
              ),
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: SummaryMetricCard(
                label: 'Avg ticket',
                value: Fmt.money(orders == 0 ? 0 : revenue / orders),
                trend: 'Per order',
                icon: Icons.receipt_long_outlined,
                accent: context.colors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.md),
        _Section(
          title: 'Daily takings',
          columns: _takingsColumns,
          rows: days,
          exportTitle: 'Daily takings',
          body: days.isEmpty
              ? const _EmptySection(hint: 'No sales in this window')
              : Column(
                  children: [
                    for (final day in days)
                      _KeyValueRow(
                        label: Fmt.dayMonth(day.date),
                        value:
                            '${_money(day.revenue)} · ${day.salesCount} orders',
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Item mix
// ---------------------------------------------------------------------------

final _itemMixColumns = <DataColumnSpec<ResolvedItemMixLine>>[
  DataColumnSpec(
    label: 'Item',
    field: 'name',
    value: (r) => r.name,
  ),
  DataColumnSpec(
    label: 'Qty',
    field: 'qty',
    numeric: true,
    value: (r) => '${_d(r.line.quantity)}',
  ),
  DataColumnSpec(
    label: 'Revenue',
    field: 'revenue',
    numeric: true,
    value: (r) => _money(r.line.revenue),
  ),
];

class _ItemMixSection extends ConsumerWidget {
  const _ItemMixSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(resolvedItemMixProvider);

    return _Section(
      title: 'Item mix',
      columns: _itemMixColumns,
      rows: lines,
      exportTitle: 'Item mix',
      body: lines.isEmpty
          ? const _EmptySection(hint: 'Nothing sold in this window')
          : Column(
              children: [
                for (final line in lines)
                  _KeyValueRow(
                    label: line.name,
                    value:
                        '${Fmt.quantity(_d(line.line.quantity))} · ${_money(line.line.revenue)}',
                  ),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Staff
// ---------------------------------------------------------------------------

final _staffColumns = <DataColumnSpec<StaffPerformanceLineDto>>[
  DataColumnSpec(
    label: 'Staff',
    field: 'actor',
    value: (r) => r.actorId == null ? 'Unknown' : _shortId(r.actorId!),
  ),
  DataColumnSpec(
    label: 'Sales',
    field: 'count',
    numeric: true,
    value: (r) => '${r.salesCount}',
  ),
  DataColumnSpec(
    label: 'Revenue',
    field: 'revenue',
    numeric: true,
    value: (r) => _money(r.revenue),
  ),
  DataColumnSpec(
    label: 'Void/refund',
    field: 'reversals',
    numeric: true,
    value: (r) => '${r.voidedCount + r.refundedCount}',
  ),
];

class _StaffSection extends ConsumerWidget {
  const _StaffSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(staffPerformanceProvider).valueOrNull ?? const [];

    return _Section(
      title: 'Staff performance',
      columns: _staffColumns,
      rows: lines,
      exportTitle: 'Staff performance',
      body: lines.isEmpty
          ? const _EmptySection(hint: 'No staff sales in this window')
          : Column(
              children: [
                for (final line in lines)
                  _KeyValueRow(
                    // Till logins resolve to names elsewhere; here the
                    // backend only knows actor ids, so the row shows a
                    // stable short id rather than a wrong name.
                    label: line.actorId == null
                        ? 'Unknown'
                        : _shortId(line.actorId!),
                    value:
                        '${line.salesCount} sales · ${_money(line.revenue)}',
                  ),
              ],
            ),
    );
  }
}

String _shortId(String id) => id.length <= 8 ? id : id.substring(0, 8);

// ---------------------------------------------------------------------------
// Finance
// ---------------------------------------------------------------------------

final _financeExpenseColumns = <DataColumnSpec<FinanceCategoryTotalDto>>[
  DataColumnSpec(
    label: 'Category',
    field: 'category',
    value: (r) => r.category,
  ),
  DataColumnSpec(
    label: 'Total',
    field: 'total',
    numeric: true,
    value: (r) => _money(r.total),
  ),
];

class _FinanceSection extends ConsumerWidget {
  const _FinanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(financeSummaryProvider).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SummaryMetricCard(
                label: 'Net',
                value: Fmt.money(
                  summary == null ? 0 : _d(summary.net),
                ),
                trend: 'Sales + income − expenses',
                icon: Icons.account_balance_wallet_outlined,
                accent: context.semantic.success,
              ),
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: SummaryMetricCard(
                label: 'Expenses',
                value: Fmt.money(
                  summary == null ? 0 : _d(summary.expenseTotal),
                ),
                trend: 'Ad-hoc spend',
                icon: Icons.trending_down_rounded,
                accent: context.semantic.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.md),
        _Section(
          title: 'Spend by category',
          columns: _financeExpenseColumns,
          rows: summary?.expensesByCategory ?? const [],
          exportTitle: 'Spend by category',
          body: (summary == null || summary.expensesByCategory.isEmpty)
              ? const _EmptySection(hint: 'No expenses in this window')
              : Column(
                  children: [
                    for (final line in summary.expensesByCategory)
                      _KeyValueRow(
                        label: line.category,
                        value: _money(line.total),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Waste
// ---------------------------------------------------------------------------

final _wasteColumns = <DataColumnSpec<WasteLineDto>>[
  DataColumnSpec(
    label: 'Item',
    field: 'name',
    value: (r) => r.itemName,
  ),
  DataColumnSpec(
    label: 'Wasted',
    field: 'qty',
    numeric: true,
    value: (r) => '${_d(r.quantityWasted)} ${r.itemUnit}',
  ),
  DataColumnSpec(
    label: 'Cost',
    field: 'cost',
    numeric: true,
    value: (r) => _money(r.costWasted),
  ),
];

class _WasteSection extends ConsumerWidget {
  const _WasteSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(wasteSummaryProvider).valueOrNull;
    final lines = summary?.lines ?? const [];

    return _Section(
      title: 'Waste',
      columns: _wasteColumns,
      rows: lines,
      exportTitle: 'Waste',
      body: lines.isEmpty
          ? const _EmptySection(hint: 'No waste recorded in this window')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cost wasted: ${_money(summary!.totalCostWasted)}',
                  style: context.text.titleSmall?.copyWith(
                    color: context.semantic.warning,
                  ),
                ),
                const SizedBox(height: Insets.sm),
                for (final line in lines)
                  _KeyValueRow(
                    label: line.itemName,
                    value:
                        '${Fmt.quantity(_d(line.quantityWasted))} ${line.itemUnit}'
                        ' · ${_money(line.costWasted)}',
                  ),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Production
// ---------------------------------------------------------------------------

final _productionColumns = <DataColumnSpec<IngredientConsumptionDto>>[
  DataColumnSpec(
    label: 'Ingredient',
    field: 'name',
    value: (r) => r.rawMaterialName,
  ),
  DataColumnSpec(
    label: 'Consumed',
    field: 'qty',
    numeric: true,
    value: (r) => '${_d(r.quantityConsumed)} ${r.rawMaterialUnit}',
  ),
];

class _ProductionSection extends ConsumerWidget {
  const _ProductionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(productionSummaryProvider).valueOrNull;
    final over = summary == null ? 0.0 : _d(summary.overPortionedBy);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SummaryMetricCard(
                label: 'Runs',
                value: '${summary?.runs ?? 0}',
                trend: 'Production runs',
                icon: Icons.soup_kitchen_outlined,
                accent: context.colors.primary,
              ),
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: SummaryMetricCard(
                label: 'Over-portioned',
                value: '${over > 0 ? '+' : ''}${Fmt.quantity(over)}',
                trend: 'Actual vs suggested',
                icon: Icons.tune_rounded,
                accent: over > 0
                    ? context.semantic.warning
                    : context.semantic.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.md),
        _Section(
          title: 'Ingredients consumed',
          columns: _productionColumns,
          rows: summary?.ingredientsConsumed ?? const [],
          exportTitle: 'Ingredients consumed',
          body: (summary == null || summary.ingredientsConsumed.isEmpty)
              ? const _EmptySection(hint: 'No production in this window')
              : Column(
                  children: [
                    for (final line in summary.ingredientsConsumed)
                      _KeyValueRow(
                        label: line.rawMaterialName,
                        value:
                            '${Fmt.quantity(_d(line.quantityConsumed))} ${line.rawMaterialUnit}',
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Valuation
// ---------------------------------------------------------------------------

final _valuationColumns = <DataColumnSpec<StockValuationLineDto>>[
  DataColumnSpec(
    label: 'Category',
    field: 'category',
    value: (r) => r.category ?? 'Uncategorized',
  ),
  DataColumnSpec(
    label: 'Lines',
    field: 'count',
    numeric: true,
    value: (r) => '${r.itemCount}',
  ),
  DataColumnSpec(
    label: 'Value',
    field: 'value',
    numeric: true,
    value: (r) => _money(r.totalValue),
  ),
];

class _ValuationSection extends ConsumerWidget {
  const _ValuationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valuation = ref.watch(stockValuationProvider).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SummaryMetricCard(
          label: 'Inventory value',
          value: Fmt.money(
            valuation == null ? 0 : _d(valuation.totalValue),
          ),
          trend: 'On hand at cost, right now',
          icon: Icons.inventory_2_outlined,
          accent: context.colors.primary,
        ),
        const SizedBox(height: Insets.md),
        _Section(
          title: 'Value by category',
          columns: _valuationColumns,
          rows: valuation?.lines ?? const [],
          exportTitle: 'Inventory valuation',
          body: (valuation == null || valuation.lines.isEmpty)
              ? const _EmptySection(hint: 'Nothing on hand')
              : Column(
                  children: [
                    for (final line in valuation.lines)
                      _KeyValueRow(
                        label: line.category ?? 'Uncategorized',
                        value:
                            '${line.itemCount} lines · ${_money(line.totalValue)}',
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.md),
      child: Text(
        hint,
        style: context.text.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodyMedium,
            ),
          ),
          const SizedBox(width: Insets.md),
          Text(
            value,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
