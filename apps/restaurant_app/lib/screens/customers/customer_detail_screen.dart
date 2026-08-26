import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/customer.dart';
import '../../models/order.dart';
import '../../models/table_query.dart';
import '../../providers/customers_provider.dart';
import '../../providers/orders_provider.dart';
import '../../router/app_router.dart';
import '../../screens/sales/sales_screen.dart' show salesColumns;
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../../widgets/data_page/reusable_data_table.dart';
import '../../widgets/data_page/summary_metric_card.dart';
import '../../widgets/detail_page/detail_page_scaffold.dart';
import 'customer_form_dialog.dart';

/// Detail view for a single customer: profile and order history.
class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = ref.watch(customerByIdProvider(customerId));

    if (customer == null) return _NotFound(customerId: customerId);

    final allOrders = ref.watch(ordersProvider);
    final customerOrders =
        allOrders.where((o) => o.customerId == customerId).toList();

    return DetailPageScaffold(
      header: _Header(customer: customer),
      sidePanel: [_ProfilePanel(customer: customer)],
      children: [
        _OrderHistoryPanel(
          customer: customer,
          orders: customerOrders,
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return DetailPageHeader(
      title: customer.name,
      subtitle: customer.phone,
      onBack: () => context.canPop()
          ? context.pop()
          : context.goNamed(AppRoute.customersName),
      actions: [
        OutlinedButton.icon(
          onPressed: () => showCustomerFormDialog(context,
              existingCustomer: customer),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Edit'),
        ),
      ],
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      SummaryMetricCard(
        label: 'Orders placed',
        value: '${customer.totalOrders}',
        trend: 'Total transactions',
        icon: Icons.receipt_long_rounded,
      ),
      SummaryMetricCard(
        label: 'Total spent',
        value: Fmt.money(customer.totalSpent),
        trend: 'Lifetime value',
        icon: Icons.savings_outlined,
        accent: context.semantic.success,
      ),
      SummaryMetricCard(
        label: 'Average order',
        value: customer.totalOrders == 0
            ? '—'
            : Fmt.money(customer.totalSpent / customer.totalOrders),
        trend: 'Per order',
        icon: Icons.trending_up_rounded,
      ),
    ];

    return DetailPanel(
      title: 'Profile',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...tiles,
          const SizedBox(height: Insets.lg),
          const Divider(height: 1),
          const SizedBox(height: Insets.lg),
          LabeledValueGrid(
            maxColumns: 2,
            minColumnWidth: 220,
            children: [
              if (customer.email case final email?)
                LabeledValue(
                  label: 'Email',
                  value: email,
                  icon: Icons.email_outlined,
                ),
              if (customer.addressLine1 case final address?)
                LabeledValue(
                  label: 'Address',
                  value: address,
                  icon: Icons.location_on_outlined,
                ),
              LabeledValue(
                label: 'Joined',
                value: Fmt.relativeDateTime(customer.createdAt),
                icon: Icons.event_available_outlined,
              ),
              if (customer.lastOrderAt != null)
                LabeledValue(
                  label: 'Last order',
                  value: Fmt.relativeDateTime(customer.lastOrderAt!),
                  icon: Icons.history_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderHistoryPanel extends StatefulWidget {
  const _OrderHistoryPanel({
    required this.customer,
    required this.orders,
  });

  final Customer customer;
  final List<Order> orders;

  @override
  State<_OrderHistoryPanel> createState() => _OrderHistoryPanelState();
}

class _OrderHistoryPanelState extends State<_OrderHistoryPanel> {
  int _page = 0;
  static const _pageSize = 8;

  @override
  Widget build(BuildContext context) {
    final orders = [...widget.orders];
    orders.sort((a, b) => b.placedAt.compareTo(a.placedAt));

    final tableQuery = TableQuery(page: _page, pageSize: _pageSize);
    final slice = PageSlice.of(orders, tableQuery);

    return DetailPanel(
      title: 'Order history',
      trailing: Text(
        '${widget.orders.length} orders',
        style: context.text.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
      child: widget.orders.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Insets.xl),
                child: Text(
                  'No orders yet',
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : ReusableDataTable<Order>(
              columns: salesColumns,
              slice: slice,
              query: tableQuery,
              onSort: (_) {},
              onPageChanged: (page) => setState(() => _page = page),
            ),
    );
  }
}

class DetailPanel extends StatelessWidget {
  const DetailPanel({
    super.key,
    required this.title,
    this.trailing,
    required this.child,
  });

  final String title;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: context.semantic.hairline),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: context.text.titleMedium,
                  ),
                ),
                if (trailing case final t?) t,
              ],
            ),
            const SizedBox(height: Insets.lg),
            child,
          ],
        ),
      ),
    );
  }
}

class LabeledValue extends StatelessWidget {
  const LabeledValue({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: context.colors.onSurfaceVariant),
              const SizedBox(width: Insets.sm),
            ],
            Text(
              label,
              style: context.text.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.xs),
        Text(
          value,
          style: context.text.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class LabeledValueGrid extends StatelessWidget {
  const LabeledValueGrid({
    super.key,
    required this.children,
    this.maxColumns = 1,
    this.minColumnWidth = 200,
  });

  final List<Widget> children;
  final int maxColumns;
  final double minColumnWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / minColumnWidth).floor().clamp(1, maxColumns);
        const spacing = Insets.lg;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(
                width: (constraints.maxWidth - spacing * (columns - 1)) / columns,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Insets.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 48,
                  color: context.colors.onSurfaceVariant,
                ),
                const SizedBox(height: Insets.lg),
                Text(
                  'Customer not found',
                  style: context.text.titleMedium,
                ),
                const SizedBox(height: Insets.md),
                Text(
                  '$customerId doesn\'t exist',
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Insets.xl),
                OutlinedButton.icon(
                  onPressed: () => context.goNamed(AppRoute.customersName),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back to customers'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
