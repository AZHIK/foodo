import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/order.dart';
import '../../providers/orders_provider.dart';
import '../../providers/settings_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/data_page/data_column_spec.dart';
import '../../widgets/data_page/data_page_scaffold.dart';
import '../../widgets/data_page/data_table_toolbar.dart';
import '../../widgets/data_page/export_actions.dart';
import '../../widgets/data_page/reusable_data_table.dart';
import '../../widgets/data_page/summary_metric_card.dart';
import '../../widgets/dialogs/assign_courier_dialog.dart';
import '../../widgets/sales/fulfillment_status_badge.dart';
import '../../widgets/sales/order_status_badge.dart';
import 'sales_date_range_selector.dart';
import 'sales_filter_panel.dart';

/// The order ledger, built on the same shared data-page layer as Inventory.
///
/// This file is column config, filters and row actions — the layout comes
/// entirely from [DataPageScaffold] and [ReusableDataTable].
class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(salesQueryProvider);
    final slice = ref.watch(salesSliceProvider);
    final summary = ref.watch(salesSummaryProvider);
    final filters = ref.watch(salesFiltersProvider);
    final notifier = ref.read(salesQueryProvider.notifier);

    final period = filters.range == SalesDateRange.custom
        ? 'the selected period'
        : filters.range.label.toLowerCase();

    return DataPageScaffold(
      title: 'Sales',
      subtitle:
          'Orders, takings and refunds across ${Fmt.longDate(DateTime.now())}',
      // Exports the filtered, sorted list — every matching row, not just the
      // page on screen.
      actions: [
        IconButton(
          onPressed: () async =>
              ref.read(ordersProvider.notifier).checkForNewOrders(),
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Check for new orders',
        ),
        ...dataPageExportActions<Order>(
          context: context,
          columns: salesColumns,
          rows: ref.watch(filteredOrdersProvider),
          title: 'Sales',
          subtitle: _exportSubtitle(filters, query.search),
        ),
      ],
      // No "Add" here — a sale is created at the till, not in the ledger. The
      // period selector earns the slot instead.
      primaryAction: const SalesDateRangeSelector(),
      metrics: [
        SummaryMetricCard(
          label: 'Total sales',
          value: Fmt.moneyCompact(summary.revenue),
          trend: 'Net of refunds, $period',
          icon: Icons.payments_rounded,
        ),
        SummaryMetricCard(
          label: 'Orders',
          value: '${summary.orderCount}',
          trend: '${summary.itemCount} items sold',
          icon: Icons.receipt_long_rounded,
          accent: context.colors.tertiary,
        ),
        SummaryMetricCard(
          label: 'Average order',
          value: Fmt.money(summary.averageOrderValue),
          trend: summary.refundedCount == 0
              ? 'No refunds in this view'
              : '${summary.refundedCount} refunded',
          trendDirection: summary.refundedCount == 0
              ? TrendDirection.flat
              : TrendDirection.down,
          icon: Icons.trending_up_rounded,
          accent: context.semantic.success,
        ),
      ],
      toolbar: DataTableToolbar(
        searchHint: 'Search order, server, item or payment',
        searchValue: query.search,
        onSearchChanged: notifier.setSearch,
        activeFilterCount: filters.activeCount,
        onClearFilters: ref.read(salesFiltersProvider.notifier).clear,
        filterBuilder: (_) => const SalesFilterPanel(),
        sortOptions: const [
          SortOption(label: 'Date', field: SalesSort.date),
          SortOption(label: 'Order', field: SalesSort.orderId),
          SortOption(label: 'Items', field: SalesSort.items),
          SortOption(label: 'Total', field: SalesSort.total),
          SortOption(label: 'Payment', field: SalesSort.payment),
          SortOption(label: 'Fulfillment', field: SalesSort.fulfillment),
          SortOption(label: 'Status', field: SalesSort.status),
        ],
        sortField: query.sortField,
        sortAscending: query.ascending,
        onSortChanged: (field, ascending) =>
            notifier.setSort(field, ascending: ascending),
      ),
      table: ReusableDataTable<Order>(
        columns: salesColumns,
        slice: slice,
        query: query,
        onSort: notifier.toggleSort,
        onPageChanged: notifier.setPage,
        onRowTap: (order) => context.go(AppRoute.orderDetail(order.id)),
        rowActions: _actions(ref),
      ),
    );
  }

  List<DataRowAction<Order>> _actions(WidgetRef ref) => [
    DataRowAction(
      label: 'View detail',
      icon: Icons.open_in_new_rounded,
      onSelected: (context, order) =>
          context.go(AppRoute.orderDetail(order.id)),
    ),
    DataRowAction(
      label: 'Assign courier',
      icon: Icons.two_wheeler_rounded,
      isEnabled: (order) => order.orderType == OrderType.delivery,
      onSelected: (context, order) => showAssignCourierDialog(context, order),
    ),
    DataRowAction(
      label: 'Refund order',
      icon: Icons.undo_rounded,
      isDestructive: true,
      // A ticket can only be refunded once, and a voided one never took money.
      isEnabled: (order) => order.status == OrderStatus.paid,
      onSelected: (context, order) => _confirmRefund(context, ref, order),
    ),
    DataRowAction(
      label: 'Print receipt',
      icon: Icons.print_outlined,
      // Numbered under the store's configured prefix rather than by ticket id,
      // so a reprint carries the same number the original paper did.
      onSelected: (context, order) =>
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Receipt ${ref.read(receiptPrefixProvider)}'
                '${order.receiptSuffix} sent to printer',
              ),
            ),
          ),
    ),
  ];

  Future<void> _confirmRefund(
    BuildContext context,
    WidgetRef ref,
    Order order,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Refund ${order.id}?'),
        content: Text(
          '${Fmt.money(order.total)} will be returned to '
          '${order.paymentType.label} and removed from takings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Refund'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    ref.read(ordersProvider.notifier).refund(order.id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${order.id} refunded')));
  }

  /// Records on the exported file which view produced it — a takings report
  /// with no period on it is worse than useless to whoever receives it.
  static String _exportSubtitle(SalesFilters filters, String search) {
    final parts = <String>[
      SalesDateRangeSelector.labelFor(filters),
      if (filters.payments.isNotEmpty)
        filters.payments.map((p) => p.label).join(', '),
      if (filters.statuses.isNotEmpty)
        filters.statuses.map((s) => s.label).join(', '),
      if (search.trim().isNotEmpty) 'matching "${search.trim()}"',
    ];

    return parts.join(' · ');
  }
}

/// Column config for the ledger.
///
/// Top-level so the exporters can reuse the exact same definitions — the
/// spreadsheet then carries the same columns the screen shows.
final salesColumns = <DataColumnSpec<Order>>[
  DataColumnSpec(
    label: 'Order',
    field: SalesSort.orderId,
    role: ColumnRole.primary,
    flex: 4,
    value: (order) => order.id,
    cellBuilder: (context, order) => _OrderCell(order: order),
  ),
  DataColumnSpec(
    label: 'Date & time',
    field: SalesSort.date,
    flex: 4,
    minTableWidth: 640,
    value: (order) => Fmt.dayMonthTime(order.placedAt),
    cellBuilder: (context, order) => Text(
      Fmt.relativeDateTime(order.placedAt),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.text.bodySmall?.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    ),
  ),
  DataColumnSpec(
    label: 'Items',
    field: SalesSort.items,
    flex: 2,
    numeric: true,
    minTableWidth: 780,
    value: (order) => '${order.itemCount}',
  ),
  DataColumnSpec(
    label: 'Total',
    field: SalesSort.total,
    flex: 3,
    numeric: true,
    value: (order) => Fmt.money(order.total),
    cellBuilder: (context, order) => _TotalCell(order: order),
  ),
  DataColumnSpec(
    label: 'Payment',
    field: SalesSort.payment,
    flex: 3,
    minTableWidth: 900,
    value: (order) => order.paymentType.label,
  ),
  DataColumnSpec(
    label: 'Fulfillment',
    field: SalesSort.fulfillment,
    role: ColumnRole.status,
    width: 124,
    minTableWidth: 1000,
    value: (order) => order.fulfillmentStatus.label,
    cellBuilder: (context, order) =>
        FulfillmentStatusBadge(status: order.fulfillmentStatus, dense: true),
  ),
  DataColumnSpec(
    label: 'Status',
    field: SalesSort.status,
    role: ColumnRole.status,
    width: 124,
    value: (order) => order.status.label,
    cellBuilder: (context, order) =>
        OrderStatusBadge(status: order.status, dense: true),
  ),
];

class _OrderCell extends StatelessWidget {
  const _OrderCell({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final isRecent = order.isRecent(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                order.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (isRecent) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'NEW',
                  style: context.text.labelSmall?.copyWith(
                    color: context.colors.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
        Text(
          order.tableLabel ?? order.orderType.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TotalCell extends StatelessWidget {
  const _TotalCell({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    // Money that left again must never read with the same weight as takings.
    final struck = order.status != OrderStatus.paid;

    return Text(
      Fmt.money(order.total),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
      style: context.text.bodyMedium?.copyWith(
        fontWeight: FontWeight.w700,
        decoration: order.status == OrderStatus.refunded
            ? TextDecoration.lineThrough
            : null,
        color: struck ? context.colors.onSurfaceVariant : null,
      ),
    );
  }
}
