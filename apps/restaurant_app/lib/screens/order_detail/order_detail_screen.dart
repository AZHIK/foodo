import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/order.dart';
import '../../providers/orders_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../../widgets/dialogs/assign_courier_dialog.dart';
import '../../widgets/sales/fulfillment_status_badge.dart';
import '../../widgets/sales/order_status_badge.dart';

/// A single sale, receipt-style.
///
/// Constrained to a readable column rather than stretched across a 1920px
/// terminal — a receipt that spans a metre of glass is harder to check, not
/// easier.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderByIdProvider(orderId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: order == null
            ? _NotFound(orderId: orderId)
            : _OrderBody(order: order),
      ),
    );
  }
}

class _OrderBody extends ConsumerWidget {
  const _OrderBody({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pad = Insets.page(context.formFactor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailHeader(order: order),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(pad, Insets.sm, pad, pad),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MetaPanel(order: order),
                      const SizedBox(height: Insets.lg),
                      _LinesPanel(order: order),
                      const SizedBox(height: Insets.lg),
                      _PaymentPanel(order: order),
                      const SizedBox(height: Insets.lg),
                      _Actions(order: order),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final pad = Insets.page(context.formFactor);

    return Padding(
      padding: EdgeInsets.fromLTRB(pad - Insets.sm, Insets.md, pad, 0),
      child: Row(
        children: [
          BackButton(
            // A deep link can land here with nothing to pop, so fall back to
            // the ledger rather than showing a dead back button.
            onPressed: () => context.canPop()
                ? context.pop()
                : context.goNamed(AppRoute.salesName),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  order.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.headlineSmall,
                ),
                Text(
                  Fmt.relativeDateTime(order.placedAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Insets.sm),
          OrderStatusBadge(status: order.status),
          const SizedBox(width: Insets.sm),
          FulfillmentStatusBadge(status: order.fulfillmentStatus),
        ],
      ),
    );
  }
}

/// Shared shell for the three receipt sections.
class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: Radii.card,
        border: Border.all(color: context.semantic.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title.toUpperCase(),
              style: context.text.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
                letterSpacing: 0.9,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: Insets.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _MetaPanel extends StatelessWidget {
  const _MetaPanel({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final entries = <({IconData icon, String label, String value})>[
      (
        icon: order.orderType.icon,
        label: 'Order type',
        value: order.orderType.label,
      ),
      (
        icon: Icons.table_restaurant_outlined,
        label: 'Seated at',
        value: order.tableLabel ?? '—',
      ),
      (icon: Icons.person_outline_rounded, label: 'Server', value: order.serverName),
      (
        icon: Icons.schedule_rounded,
        label: 'Placed',
        value: Fmt.dayMonthTime(order.placedAt),
      ),
    ];

    return _Panel(
      title: 'Details',
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = Insets.lg;
          final perRow = constraints.maxWidth >= 420 ? 2 : 1;
          final width =
              (constraints.maxWidth - spacing * (perRow - 1)) / perRow;

          return Wrap(
            spacing: spacing,
            runSpacing: Insets.md,
            children: [
              for (final entry in entries)
                SizedBox(
                  width: width,
                  child: _MetaTile(
                    icon: entry.icon,
                    label: entry.label,
                    value: entry.value,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Icon(icon, size: 17, color: colors.onSurfaceVariant),
        const SizedBox(width: Insets.md - 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LinesPanel extends StatelessWidget {
  const _LinesPanel({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return _Panel(
      title: '${order.itemCount} items',
      child: Column(
        children: [
          for (var i = 0; i < order.lines.length; i++) ...[
            if (i > 0) const Divider(height: Insets.xl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.lines[i].emoji,
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        order.lines[i].name,
                        style: context.text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${order.lines[i].quantity} × '
                        '${Fmt.money(order.lines[i].unitPrice)}',
                        style: context.text.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (order.lines[i].note case final note?
                          when note.isNotEmpty)
                        Text(
                          note,
                          style: context.text.bodySmall?.copyWith(
                            color: context.semantic.warning,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: Insets.sm),
                Text(
                  Fmt.money(order.lines[i].lineTotal),
                  maxLines: 1,
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentPanel extends StatelessWidget {
  const _PaymentPanel({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return _Panel(
      title: 'Payment',
      child: Column(
        children: [
          _Line(label: 'Subtotal', value: Fmt.money(order.subtotal)),
          if (order.discountRate > 0)
            _Line(
              label: 'Discount (${Fmt.percent(order.discountRate)})',
              value: '−${Fmt.money(order.discount)}',
              valueColor: context.semantic.success,
            ),
          _Line(
            label: 'Tax (${Fmt.percent(order.taxRate)})',
            value: Fmt.money(order.tax),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: Insets.sm),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total',
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                Fmt.money(order.total),
                maxLines: 1,
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          Row(
            children: [
              Icon(
                Icons.credit_card_rounded,
                size: 16,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: Text(
                  order.status == OrderStatus.refunded
                      ? 'Refunded to ${order.paymentType.label}'
                      : 'Paid by ${order.paymentType.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final style = context.text.bodyMedium?.copyWith(
      color: context.colors.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          const SizedBox(width: Insets.sm),
          Text(
            value,
            maxLines: 1,
            style: style?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? style.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refunded = order.status == OrderStatus.refunded;
    final isDelivery = order.orderType == OrderType.delivery;

    return Wrap(
      spacing: Insets.md,
      runSpacing: Insets.md,
      children: [
        OutlinedButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Receipt for ${order.id} sent to printer')),
          ),
          icon: const Icon(Icons.print_outlined, size: 18),
          label: const Text('Print receipt'),
        ),
        if (isDelivery)
          OutlinedButton.icon(
            onPressed: () => showAssignCourierDialog(context, order),
            icon: const Icon(Icons.two_wheeler_rounded, size: 18),
            label: Text(order.courierId != null ? 'Change courier' : 'Assign courier'),
          ),
        OutlinedButton.icon(
          onPressed: refunded
              ? null
              : () => _confirmRefund(context, ref),
          icon: const Icon(Icons.undo_rounded, size: 18),
          label: Text(refunded ? 'Already refunded' : 'Refund order'),
          style: OutlinedButton.styleFrom(
            foregroundColor: refunded ? null : context.semantic.danger,
          ),
        ),
        PopupMenuButton<FulfillmentStatus>(
          onSelected: (value) {
            ref.read(ordersProvider.notifier).setFulfillmentStatus(order.id, value);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Status changed to ${value.label}')),
            );
          },
          itemBuilder: (context) => FulfillmentStatus.values
              .map(
                (status) => PopupMenuItem(
                  value: status,
                  child: Text(status.label),
                ),
              )
              .toList(),
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: Icon(order.fulfillmentStatus.icon, size: 18),
            label: Text(order.fulfillmentStatus.label),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmRefund(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Refund ${order.id}?'),
        content: Text(
          '${Fmt.money(order.total)} will be returned to '
          '${order.paymentType.label} and removed from today\'s takings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Refund'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    ref.read(ordersProvider.notifier).refund(order.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${order.id} refunded')),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 36,
              color: context.colors.onSurfaceVariant,
            ),
            const SizedBox(height: Insets.md),
            Text('Order $orderId not found', style: context.text.titleMedium),
            const SizedBox(height: Insets.lg),
            FilledButton.icon(
              onPressed: () => context.goNamed(AppRoute.salesName),
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: const Text('Back to sales'),
            ),
          ],
        ),
      ),
    );
  }
}
