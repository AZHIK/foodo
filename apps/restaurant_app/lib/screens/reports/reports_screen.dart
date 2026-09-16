import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_durations.dart';
import '../../constants/app_strings.dart';
import '../../models/permission.dart';
import '../../constants/app_limits.dart';
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
      lastDate: DateTime.now().add(AppDurations.singleDay),
      initialDateRange: current.from == null && current.to == null
          ? null
          : DateTimeRange(
              start:
                  current.from ??
                  DateTime.now().subtract(AppDurations.analyticsWindow),
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
        title: Text(AppStrings.reportsTitle),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: AppStrings.filterByDate,
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
                    AppStrings.dateChip(
                      filter.from == null
                          ? AppStrings.ellipsis
                          : Fmt.dayMonth(filter.from!),
                      filter.to == null
                          ? AppStrings.ellipsis
                          : Fmt.dayMonth(filter.to!),
                    ),
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
    label: AppStrings.dateColumn,
    field: 'date',
    value: (r) => r.date.toIso8601String().substring(0, 10),
  ),
  DataColumnSpec(
    label: AppStrings.revenueColumn,
    field: 'revenue',
    numeric: true,
    value: (r) => _money(r.revenue),
  ),
  DataColumnSpec(
    label: AppStrings.ordersColumn,
    field: 'count',
    numeric: true,
    value: (r) => '${r.salesCount}',
  ),
  DataColumnSpec(
    label: AppStrings.avgTicketColumn,
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
                label: AppStrings.revenueMetric,
                value: Fmt.money(revenue),
                trend: AppStrings.ordersTrend(orders),
                icon: Icons.payments_outlined,
                accent: context.semantic.success,
              ),
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: SummaryMetricCard(
                label: AppStrings.avgTicketMetric,
                value: Fmt.money(orders == 0 ? 0 : revenue / orders),
                trend: AppStrings.perOrderTrend,
                icon: Icons.receipt_long_outlined,
                accent: context.colors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.md),
        _Section(
          title: AppStrings.dailyTakingsSection,
          columns: _takingsColumns,
          rows: days,
          exportTitle: AppStrings.dailyTakingsSection,
          body: days.isEmpty
              ? _EmptySection(hint: AppStrings.noSalesInWindow)
              : Column(
                  children: [
                    for (final day in days)
                      _KeyValueRow(
                        label: Fmt.dayMonth(day.date),
                        value: AppStrings.takingsRow(
                          _money(day.revenue),
                          day.salesCount,
                        ),
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
    label: AppStrings.itemColumn,
    field: 'name',
    value: (r) => r.name,
  ),
  DataColumnSpec(
    label: AppStrings.qtyColumn,
    field: 'qty',
    numeric: true,
    value: (r) => '${_d(r.line.quantity)}',
  ),
  DataColumnSpec(
    label: AppStrings.revenueColumn,
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
      title: AppStrings.itemMixSection,
      columns: _itemMixColumns,
      rows: lines,
      exportTitle: AppStrings.itemMixSection,
      body: lines.isEmpty
          ? _EmptySection(hint: AppStrings.nothingSold)
          : Column(
              children: [
                for (final line in lines)
                  _KeyValueRow(
                    label: line.name,
                    value: AppStrings.itemMixRow(
                      Fmt.quantity(_d(line.line.quantity)),
                      _money(line.line.revenue),
                    ),
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
    label: AppStrings.staffColumn,
    field: 'actor',
    value: (r) => r.actorId == null ? AppStrings.unknown : _shortId(r.actorId!),
  ),
  DataColumnSpec(
    label: AppStrings.salesColumn,
    field: 'count',
    numeric: true,
    value: (r) => '${r.salesCount}',
  ),
  DataColumnSpec(
    label: AppStrings.revenueColumn,
    field: 'revenue',
    numeric: true,
    value: (r) => _money(r.revenue),
  ),
  DataColumnSpec(
    label: AppStrings.voidRefundColumn,
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
      title: AppStrings.staffPerformanceSection,
      columns: _staffColumns,
      rows: lines,
      exportTitle: AppStrings.staffPerformanceSection,
      body: lines.isEmpty
          ? _EmptySection(hint: AppStrings.noStaffSales)
          : Column(
              children: [
                for (final line in lines)
                  _KeyValueRow(
                    // Till logins resolve to names elsewhere; here the
                    // backend only knows actor ids, so the row shows a
                    // stable short id rather than a wrong name.
                    label: line.actorId == null
                        ? AppStrings.unknown
                        : _shortId(line.actorId!),
                    value: AppStrings.staffRow(
                      line.salesCount,
                      _money(line.revenue),
                    ),
                  ),
              ],
            ),
    );
  }
}

String _shortId(String id) => id.length <= AppLimits.shortIdLength
    ? id
    : id.substring(0, AppLimits.shortIdLength);

// ---------------------------------------------------------------------------
// Finance
// ---------------------------------------------------------------------------

final _financeExpenseColumns = <DataColumnSpec<FinanceCategoryTotalDto>>[
  DataColumnSpec(
    label: AppStrings.categoryColumn,
    field: 'category',
    value: (r) => r.category,
  ),
  DataColumnSpec(
    label: AppStrings.totalColumn,
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
                label: AppStrings.netMetric,
                value: Fmt.money(
                  summary == null ? 0 : _d(summary.net),
                ),
                trend: AppStrings.netTrend,
                icon: Icons.account_balance_wallet_outlined,
                accent: context.semantic.success,
              ),
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: SummaryMetricCard(
                label: AppStrings.expensesMetric,
                value: Fmt.money(
                  summary == null ? 0 : _d(summary.expenseTotal),
                ),
                trend: AppStrings.adhocSpend,
                icon: Icons.trending_down_rounded,
                accent: context.semantic.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.md),
        _Section(
          title: AppStrings.spendByCategory,
          columns: _financeExpenseColumns,
          rows: summary?.expensesByCategory ?? const [],
          exportTitle: AppStrings.spendByCategory,
          body: (summary == null || summary.expensesByCategory.isEmpty)
              ? _EmptySection(hint: AppStrings.noExpenses)
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
    label: AppStrings.itemColumn,
    field: 'name',
    value: (r) => r.itemName,
  ),
  DataColumnSpec(
    label: AppStrings.wastedColumn,
    field: 'qty',
    numeric: true,
    value: (r) => '${_d(r.quantityWasted)} ${r.itemUnit}',
  ),
  DataColumnSpec(
    label: AppStrings.costColumn,
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
      title: AppStrings.wasteSection,
      columns: _wasteColumns,
      rows: lines,
      exportTitle: AppStrings.wasteSection,
      body: lines.isEmpty
          ? _EmptySection(hint: AppStrings.noWaste)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.costWasted(_money(summary!.totalCostWasted)),
                  style: context.text.titleSmall?.copyWith(
                    color: context.semantic.warning,
                  ),
                ),
                const SizedBox(height: Insets.sm),
                for (final line in lines)
                  _KeyValueRow(
                    label: line.itemName,
                    value: AppStrings.wasteRow(
                      Fmt.quantity(_d(line.quantityWasted)),
                      line.itemUnit,
                      _money(line.costWasted),
                    ),
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
    label: AppStrings.ingredientColumn,
    field: 'name',
    value: (r) => r.rawMaterialName,
  ),
  DataColumnSpec(
    label: AppStrings.consumedColumn,
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
                label: AppStrings.runsMetric,
                value: '${summary?.runs ?? 0}',
                trend: AppStrings.productionRunsTrend,
                icon: Icons.soup_kitchen_outlined,
                accent: context.colors.primary,
              ),
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: SummaryMetricCard(
                label: AppStrings.overPortioned,
                value: AppStrings.overPortionedValue(over, Fmt.quantity(over)),
                trend: AppStrings.actualVsSuggested,
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
          title: AppStrings.ingredientsConsumed,
          columns: _productionColumns,
          rows: summary?.ingredientsConsumed ?? const [],
          exportTitle: AppStrings.ingredientsConsumed,
          body: (summary == null || summary.ingredientsConsumed.isEmpty)
              ? _EmptySection(hint: AppStrings.noProduction)
              : Column(
                  children: [
                    for (final line in summary.ingredientsConsumed)
                      _KeyValueRow(
                        label: line.rawMaterialName,
                        value: AppStrings.consumedRow(
                          Fmt.quantity(_d(line.quantityConsumed)),
                          line.rawMaterialUnit,
                        ),
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
    label: AppStrings.categoryColumn,
    field: 'category',
    value: (r) => r.category ?? AppStrings.uncategorized,
  ),
  DataColumnSpec(
    label: AppStrings.linesColumn,
    field: 'count',
    numeric: true,
    value: (r) => '${r.itemCount}',
  ),
  DataColumnSpec(
    label: AppStrings.valueColumn,
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
          label: AppStrings.inventoryValueMetric,
          value: Fmt.money(
            valuation == null ? 0 : _d(valuation.totalValue),
          ),
          trend: AppStrings.onHandAtCost,
          icon: Icons.inventory_2_outlined,
          accent: context.colors.primary,
        ),
        const SizedBox(height: Insets.md),
        _Section(
          title: AppStrings.valueByCategory,
          columns: _valuationColumns,
          rows: valuation?.lines ?? const [],
          exportTitle: AppStrings.inventoryValuation,
          body: (valuation == null || valuation.lines.isEmpty)
              ? _EmptySection(hint: AppStrings.nothingOnHand)
              : Column(
                  children: [
                    for (final line in valuation.lines)
                      _KeyValueRow(
                        label: line.category ?? AppStrings.uncategorized,
                        value: AppStrings.valuationRow(
                          line.itemCount,
                          _money(line.totalValue),
                        ),
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
