import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/order.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_session_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/settings_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../cash_tender_panel.dart';
import '../payment_summary_panel.dart';
import '../section_label.dart';
import '../selectable_option_card.dart';

/// Takes payment for the open order: pick a tender, count the cash, write the
/// sale, reset the ticket.
///
/// Shared by the desktop panel and the mobile cart sheet so "Charge" means the
/// same thing everywhere, and so the reset sequence (place → clear → notify)
/// only exists once.
Future<void> chargeOpenOrder(BuildContext context, WidgetRef ref) async {
  if (ref.read(cartProvider).isEmpty) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => const ChargeDialog(),
  );

  if (confirmed != true) {
    // A dismissed dialog must not leave a tender sitting on the ticket for the
    // next attempt to inherit.
    ref.read(cartProvider.notifier).resetPayment();
    return;
  }
  if (!context.mounted) return;

  // The tender and the amount handed over were recorded on the cart as the
  // cashier worked, so the sale is built from one source rather than from
  // arguments threaded back out of the dialog.
  final order = ref
      .read(ordersProvider.notifier)
      .placeOrder(
        cart: ref.read(cartProvider),
        orderType: ref.read(orderTypeProvider),
        tableLabel: ref.read(tableLabelProvider),
        serverName: ref.read(currentStaffProvider),
      );

  final change = order.payment.changeFor(order.totals);

  // Store Settings decides whether a receipt follows a settled payment. There
  // is no printer driver behind this yet, so what it controls is whether the
  // confirmation says one is on its way — the branch is the wiring, and the
  // driver drops in where the message is built.
  final autoPrint = ref.read(autoPrintReceiptProvider);
  final receiptNumber = '${ref.read(receiptPrefixProvider)}${order.receiptSuffix}';

  ref.read(cartProvider.notifier).clear();

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        '${order.id} charged — ${Fmt.money(order.total)} by '
        '${order.paymentType.label}'
        '${change != null && change > 0 ? ' · ${Fmt.money(change)} change' : ''}'
        '${autoPrint ? ' · receipt $receiptNumber printing' : ''}',
      ),
      action: SnackBarAction(
        label: 'View',
        onPressed: () => context.go(AppRoute.orderDetail(order.id)),
      ),
    ),
  );
}

/// The take-payment dialog.
///
/// Wide enough on desktop and tablet to lay the tenders out three across and
/// still leave the cash entry room to breathe; on a phone it narrows and the
/// tenders reflow two across rather than shrinking below a thumb's width.
class ChargeDialog extends ConsumerWidget {
  const ChargeDialog({super.key});

  /// Comfortable for a three-across tender row plus the cash panel. Wider than
  /// this and the totals drift away from the amounts they belong to.
  static const double _wideWidth = 560;
  static const double _phoneWidth = 420;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = context.formFactor;
    final totals = ref.watch(orderTotalsProvider);
    final payment = ref.watch(paymentDetailsProvider);
    final ready = ref.watch(canConfirmPaymentProvider);

    // The dialog's own inset either side, so a 360px phone still gets a
    // dialog rather than a horizontal overflow.
    final available = MediaQuery.sizeOf(context).width - 80;
    final width = math.max(
      240.0,
      math.min(form.isMobile ? _phoneWidth : _wideWidth, available),
    );

    return AlertDialog(
      title: const Text('Take payment'),
      contentPadding: const EdgeInsets.fromLTRB(
        Insets.xl,
        Insets.lg,
        Insets.xl,
        Insets.sm,
      ),
      content: SizedBox(
        width: width,
        // Scrolls rather than overflows when the window is short, the system
        // keyboard is up, or the text scale is large.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Insets.lg,
                  vertical: Insets.md,
                ),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                // The shared totals block — the same one the order panel and
                // the receipt use, so the amount due here cannot drift from
                // the amount due there.
                child: PaymentBreakdown(totals: totals, compact: form.isMobile),
              ),
              const SizedBox(height: Insets.lg),
              const SectionLabel('Payment method'),
              const SizedBox(height: Insets.sm),
              SelectableOptionGrid(
                // Three across on desktop and tablet; two on a phone, where a
                // third column would push each card under a thumb's width.
                perRow: form.isMobile ? 2 : 3,
                children: [
                  for (final type in PaymentType.values)
                    SelectableOptionCard(
                      label: type.label,
                      icon: type.icon,
                      selected: type == payment.method,
                      onTap: () => ref
                          .read(cartProvider.notifier)
                          .selectPaymentMethod(type),
                    ),
                ],
              ),
              if (payment.isCash) ...[
                const SizedBox(height: Insets.lg),
                const SectionLabel('Cash received'),
                const SizedBox(height: Insets.sm),
                // Autofocus only where there is a hardware keyboard: on a
                // phone it would throw the system keyboard over the chips.
                CashTenderPanel(autofocus: form.isDesktop),
              ] else ...[
                const SizedBox(height: Insets.lg),
                _TerminalNotice(method: payment.method),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          // Dead until the cash covers the total — a ticket cannot be settled
          // for less than it is worth.
          onPressed: ready ? () => Navigator.of(context).pop(true) : null,
          icon: const Icon(Icons.check_circle_outline_rounded, size: 19),
          label: Text(
            'Charge ${Fmt.money(totals.total)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Card, QRIS and the rest settle on a terminal this build only mocks: there
/// is no amount to key in, so the dialog says so rather than leaving a blank.
class _TerminalNotice extends StatelessWidget {
  const _TerminalNotice({required this.method});

  final PaymentType method;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: context.semantic.hairline),
      ),
      child: Row(
        children: [
          Icon(method.icon, size: 20, color: colors.onSurfaceVariant),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Text(
              'Complete the ${method.label.toLowerCase()} payment on the '
              'terminal, then charge to record it.',
              style: context.text.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
