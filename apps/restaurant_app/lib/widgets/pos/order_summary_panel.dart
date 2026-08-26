import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/order.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_session_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../payment_summary_panel.dart';
import '../section_label.dart';
import '../selectable_option_card.dart';
import 'cart_line_item_tile.dart';
import 'charge_dialog.dart';

/// What the order panel is for right now.
///
/// The payment screen shows the *same* panel as the POS screen rather than a
/// summary of its own — it only swaps the footer's job (charge → confirm) and
/// freezes the ticket, because a cashier mid-payment should not be able to
/// re-type the order they are taking money for.
enum OrderPanelMode {
  ordering,
  payment;

  bool get isPayment => this == OrderPanelMode.payment;
}

/// The persistent running-order panel on desktop and tablet.
///
/// Composed from the same three parts the mobile cart sheet uses, so the
/// ticket reads identically on a 1920px terminal and a 360px phone.
class OrderSummaryPanel extends StatelessWidget {
  const OrderSummaryPanel({
    super.key,
    required this.width,
    this.mode = OrderPanelMode.ordering,
    this.onConfirm,
  });

  final double width;
  final OrderPanelMode mode;

  /// Tapped on "Confirm payment". Only consulted in [OrderPanelMode.payment].
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    // The narrowed tablet panel restacks rather than shrinking type.
    final compact = width < 260;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(left: BorderSide(color: context.semantic.hairline)),
      ),
      child: SafeArea(
        left: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: OrderTicketBody(compact: compact, mode: mode)),
            OrderTotalsFooter(
              compact: compact,
              mode: mode,
              onConfirm: onConfirm,
            ),
          ],
        ),
      ),
    );
  }
}

/// Ticket header and line items as one scroll view.
///
/// They scroll together so a short window (a 320px-tall terminal, or a phone
/// with the keyboard up) gives its remaining height to the lines instead of
/// overflowing behind a fixed header. The totals footer deliberately stays
/// outside this — checkout must never scroll out of reach.
class OrderTicketBody extends StatelessWidget {
  const OrderTicketBody({
    super.key,
    required this.compact,
    this.controller,
    this.mode = OrderPanelMode.ordering,
  });

  final bool compact;
  final ScrollController? controller;
  final OrderPanelMode mode;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      slivers: [
        SliverToBoxAdapter(
          child: OrderTicketHeader(compact: compact, mode: mode),
        ),
        const SliverToBoxAdapter(child: Divider(height: 1)),
        CartLinesSliver(compact: compact, readOnly: mode.isPayment),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header — who this ticket is for
// ---------------------------------------------------------------------------

class OrderTicketHeader extends ConsumerWidget {
  const OrderTicketHeader({
    super.key,
    required this.compact,
    this.mode = OrderPanelMode.ordering,
  });

  final bool compact;
  final OrderPanelMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final payment = ref.watch(paymentDetailsProvider);
    // Once the sale is written the ledger's "next id" has already moved on, so
    // a paid ticket has to show the number it was actually given.
    final String orderId = payment.orderId ?? ref.watch(nextOrderIdProvider);
    final orderType = ref.watch(orderTypeProvider);
    final itemCount = ref.watch(cartItemCountProvider);
    final table = ref.watch(tableLabelProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.md,
        Insets.md,
        Insets.md,
        Insets.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SectionLabel(
                      mode.isPayment ? 'Taking payment' : 'Current order',
                    ),
                    const SizedBox(height: 1),
                    Text(
                      orderId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (itemCount > 0 && !mode.isPayment)
                SizedBox(
                  height: 32,
                  width: 32,
                  child: IconButton(
                    tooltip: 'Clear order',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    onPressed: () => ref.read(cartProvider.notifier).clear(),
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    color: colors.onSurfaceVariant,
                  ),
                ),
              SizedBox(
                height: 32,
                width: 32,
                child: IconButton(
                  tooltip: 'Close',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          // Mid-payment the ticket is settled: its destination is reported,
          // not chosen.
          if (mode.isPayment)
            _TicketMeta(orderType: orderType, table: table)
          else ...[
            const _OrderTypeSelector(),
            if (orderType.usesTable) ...[
              const SizedBox(height: Insets.sm),
              const _TablePicker(),
            ],
          ],
        ],
      ),
    );
  }
}

/// Read-only stand-in for the type selector and table picker.
class _TicketMeta extends StatelessWidget {
  const _TicketMeta({required this.orderType, required this.table});

  final OrderType orderType;
  final String? table;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.md,
        vertical: Insets.sm - 1,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(orderType.icon, size: 15, color: colors.onSurfaceVariant),
          const SizedBox(width: Insets.sm - 2),
          Flexible(
            child: Text(
              table == null ? orderType.label : '${orderType.label} · $table',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dine-in / takeaway / delivery as three equal stacked buttons.
///
/// Stacked rather than a [SegmentedButton] because the labels have to survive
/// a 220px panel divided three ways without truncating to nonsense. Uses the
/// same [SelectableOptionCard] as the tender picker, so "chosen" looks the
/// same on both.
class _OrderTypeSelector extends ConsumerWidget {
  const _OrderTypeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(orderTypeProvider);

    return Row(
      children: [
        for (final type in OrderType.values) ...[
          if (type != OrderType.values.first) const SizedBox(width: Insets.sm),
          Expanded(
            child: SelectableOptionCard(
              label: type.label,
              icon: type.icon,
              dense: true,
              selected: type == selected,
              onTap: () => ref.read(orderTypeProvider.notifier).state = type,
            ),
          ),
        ],
      ],
    );
  }
}

class _TablePicker extends ConsumerWidget {
  const _TablePicker();

  static const _tableCount = 24;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final table = ref.watch(tableNumberProvider);

    return Align(
      alignment: Alignment.centerLeft,
      child: PopupMenuButton<int?>(
        tooltip: 'Assign table',
        onSelected: (value) =>
            ref.read(tableNumberProvider.notifier).state = value,
        itemBuilder: (context) => [
          const PopupMenuItem(value: null, child: Text('Counter (no table)')),
          const PopupMenuDivider(),
          for (var i = 1; i <= _tableCount; i++)
            PopupMenuItem(value: i, child: Text('Table $i')),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.md,
            vertical: Insets.sm - 1,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(Radii.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.table_restaurant_outlined,
                size: 15,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: Insets.sm - 2),
              Flexible(
                child: Text(
                  table == null ? 'Counter' : 'Table $table',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelMedium,
                ),
              ),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lines
// ---------------------------------------------------------------------------

class CartLinesSliver extends ConsumerWidget {
  const CartLinesSliver({
    super.key,
    required this.compact,
    this.readOnly = false,
  });

  final bool compact;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(cartProvider.select((cart) => cart.items));

    if (lines.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyOrder(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.md),
      sliver: SliverList.separated(
        itemCount: lines.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) => CartLineItemTile(
          line: lines[index],
          compact: compact,
          readOnly: readOnly,
        ),
      ),
    );
  }
}

class _EmptyOrder extends StatelessWidget {
  const _EmptyOrder();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 28,
              color: colors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: Insets.sm),
            Text(
              'No items yet',
              textAlign: TextAlign.center,
              style: context.text.titleSmall?.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap a menu item to start this order.',
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Totals + checkout
// ---------------------------------------------------------------------------

class OrderTotalsFooter extends ConsumerWidget {
  const OrderTotalsFooter({
    super.key,
    required this.compact,
    this.mode = OrderPanelMode.ordering,
    this.onConfirm,
  });

  final bool compact;
  final OrderPanelMode mode;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final totals = ref.watch(orderTotalsProvider);
    final hasItems = ref.watch(cartItemCountProvider) > 0;
    final paying = mode.isPayment;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: context.semantic.hairline)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Insets.md,
          Insets.sm,
          Insets.md,
          Insets.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // The one totals rendering in the app, shared with the payment
            // screen, the receipt and sale detail. In payment mode it grows
            // the tender rows — method, tendered, change due — rather than a
            // second summary appearing beside this one.
            PaymentBreakdown(
              totals: totals,
              payment: paying ? ref.watch(paymentDetailsProvider) : null,
              compact: compact,
              highlightChange: true,
            ),
            const SizedBox(height: Insets.sm),
            if (paying)
              _ConfirmPaymentButton(compact: compact, onConfirm: onConfirm)
            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: hasItems
                          ? () => chargeOpenOrder(context, ref)
                          : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: Insets.md),
                      ),
                      child: Text(
                        compact ? 'Charge' : 'Charge ${Fmt.money(totals.total)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: Insets.xs),
                  _DiscountButton(enabled: hasItems),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Greys out until the tender covers the total, so the cashier cannot settle a
/// ticket the customer has not yet paid for.
class _ConfirmPaymentButton extends ConsumerWidget {
  const _ConfirmPaymentButton({required this.compact, required this.onConfirm});

  final bool compact;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(canConfirmPaymentProvider);

    return FilledButton.icon(
      onPressed: ready ? onConfirm : null,
      icon: const Icon(Icons.check_circle_outline_rounded, size: 19),
      label: Text(
        compact ? 'Confirm' : 'Confirm payment',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _DiscountButton extends ConsumerWidget {
  const _DiscountButton({required this.enabled});

  final bool enabled;

  static const _rates = [0.0, 0.05, 0.10, 0.15, 0.20];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(cartProvider.select((c) => c.discountRate)) > 0;
    final colors = context.colors;

    return SizedBox(
      height: 40,
      width: 40,
      child: Material(
        color: active ? colors.primaryContainer : colors.surfaceContainerHighest,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: PopupMenuButton<double>(
          enabled: enabled,
          tooltip: 'Apply discount',
          onSelected: (rate) =>
              ref.read(cartProvider.notifier).applyDiscount(rate),
          itemBuilder: (context) => [
            for (final rate in _rates)
              PopupMenuItem(
                value: rate,
                child: Text(rate == 0 ? 'No discount' : Fmt.percent(rate)),
              ),
          ],
          child: Icon(
            Icons.percent_rounded,
            size: 17,
            color: enabled
                ? (active ? colors.onPrimaryContainer : colors.onSurfaceVariant)
                : colors.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

