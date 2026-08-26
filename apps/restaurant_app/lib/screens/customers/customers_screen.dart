import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/customer.dart';
import '../../providers/customers_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/data_page/data_column_spec.dart';
import '../../widgets/data_page/data_page_scaffold.dart';
import '../../widgets/data_page/data_table_toolbar.dart';
import '../../widgets/data_page/reusable_data_table.dart';
import '../../widgets/data_page/summary_metric_card.dart';
import 'customer_form_dialog.dart';

/// Customer list built on the shared data-page layer, modeled on InventoryScreen.
class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(customersQueryProvider);
    final slice = ref.watch(customersSliceProvider);
    final summary = ref.watch(customerSummaryProvider);
    final notifier = ref.read(customersQueryProvider.notifier);

    return DataPageScaffold(
      title: 'Customers',
      subtitle: 'All customer profiles and order history',
      actions: [],
      primaryAction: FilledButton.icon(
        onPressed: () => showCustomerFormDialog(context),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Add customer'),
      ),
      metrics: [
        SummaryMetricCard(
          label: 'Total customers',
          value: '${summary.totalCustomers}',
          trend: 'Registered profiles',
          icon: Icons.people_alt_outlined,
        ),
        SummaryMetricCard(
          label: 'Lifetime spend',
          value: Fmt.moneyCompact(summary.totalLifetimeSpend),
          trend: 'Total revenue from customers',
          icon: Icons.trending_up_rounded,
          accent: context.semantic.success,
        ),
        SummaryMetricCard(
          label: 'Average spend',
          value: Fmt.money(summary.averageOrderValue),
          trend: 'Per customer',
          icon: Icons.balance_rounded,
        ),
      ],
      toolbar: DataTableToolbar(
        searchHint: 'Search by name or phone',
        searchValue: ref.watch(customerSearchProvider),
        onSearchChanged: (value) =>
            ref.read(customerSearchProvider.notifier).state = value,
        activeFilterCount: 0,
        onClearFilters: () {},
        filterBuilder: (_) => const SizedBox.shrink(),
        sortOptions: const [
          SortOption(label: 'Name', field: CustomerSort.name),
          SortOption(label: 'Phone', field: CustomerSort.phone),
          SortOption(label: 'Last order', field: CustomerSort.lastOrder),
          SortOption(label: 'Total spent', field: CustomerSort.totalSpent),
        ],
        sortField: query.sortField,
        sortAscending: query.ascending,
        onSortChanged: (field, ascending) =>
            notifier.setSort(field, ascending: ascending),
      ),
      table: ReusableDataTable<Customer>(
        columns: _columns,
        slice: slice,
        query: query,
        onSort: notifier.toggleSort,
        onPageChanged: notifier.setPage,
        onRowTap: (customer) =>
            context.go(AppRoute.customerDetail(customer.id)),
        rowActions: _actions(ref),
      ),
    );
  }

  List<DataRowAction<Customer>> _actions(WidgetRef ref) => [
    DataRowAction(
      label: 'View detail',
      icon: Icons.open_in_new_rounded,
      onSelected: (context, customer) =>
          context.go(AppRoute.customerDetail(customer.id)),
    ),
    DataRowAction(
      label: 'Edit',
      icon: Icons.edit_outlined,
      onSelected: (context, customer) =>
          showCustomerFormDialog(context, existingCustomer: customer),
    ),
    DataRowAction(
      label: 'Delete',
      icon: Icons.delete_outline_rounded,
      isDestructive: true,
      onSelected: (context, customer) =>
          _confirmDelete(context, ref, customer),
    ),
  ];

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${customer.name}?'),
        content: const Text(
          'This customer record will be removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    ref.read(customersProvider.notifier).delete(customer.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${customer.name} deleted')),
    );
  }
}

/// Column config for the customers table.
final _columns = <DataColumnSpec<Customer>>[
  DataColumnSpec(
    label: 'Name',
    field: CustomerSort.name,
    role: ColumnRole.primary,
    flex: 4,
    value: (customer) => customer.name,
  ),
  DataColumnSpec(
    label: 'Phone',
    field: CustomerSort.phone,
    flex: 3,
    value: (customer) => customer.phone,
  ),
  DataColumnSpec(
    label: 'Last order',
    field: CustomerSort.lastOrder,
    flex: 3,
    minTableWidth: 640,
    value: (customer) => customer.lastOrderAt == null
        ? '—'
        : Fmt.relativeDateTime(customer.lastOrderAt!),
  ),
  DataColumnSpec(
    label: 'Orders',
    field: 'orders',
    flex: 2,
    numeric: true,
    minTableWidth: 780,
    value: (customer) => '${customer.totalOrders}',
  ),
  DataColumnSpec(
    label: 'Total spent',
    field: CustomerSort.totalSpent,
    flex: 2,
    numeric: true,
    value: (customer) => Fmt.money(customer.totalSpent),
  ),
];
