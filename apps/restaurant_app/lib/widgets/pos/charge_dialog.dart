import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/order.dart';
import '../../constants/app_strings.dart';
import '../../models/permission.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_session_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/permissions_provider.dart';
import '../../providers/settings_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../cash_tender_panel.dart';
import '../payment_summary_panel.dart';
import '../section_label.dart';
import '../selectable_option_card.dart';
import 'customer_picker.dart';

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
        customerId: ref.read(selectedCustomerIdProvider),
      );

  // A new ticket must not silently inherit the last customer — only reset
  // on a successful charge, never when the dialog is merely dismissed (see
  // `selectedCustomerIdProvider`'s doc comment).
  ref.read(selectedCustomerIdProvider.notifier).state = null;

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
        AppStrings.orderCharged(
          order.id,
          Fmt.money(order.total),
          order.paymentType.label,
          change != null && change > 0
              ? AppStrings.chargeChangePart(Fmt.money(change))
              : '',
          autoPrint ? AppStrings.chargeReceiptPart(receiptNumber) : '',
        ),
      ),
      action: SnackBarAction(
        label: AppStrings.cartView,
        onPressed: () => context.go(AppRoute.orderDetail(order.id)),
      ),
    ),
  );
}

/// The take-payment dialog.
///
/// On desktop and tablet it is a wide two-pane layout — tenders and cash
/// entry on the left, the amount due and the charge button pinned on the
/// right — so every action fits without scrolling and the charge button is
/// visible the moment the dialog opens. On a phone it stays a narrow single
/// column with the tenders reflowed two across.
class ChargeDialog extends ConsumerWidget {
  const ChargeDialog({super.key});

  /// Two panes need room: tenders three across on the left, the amount-due
  /// card plus a full-width charge button on the right.
  static const double _wideWidth = 1020;
  static const double _tabletWidth = 980;
  static const double _phoneWidth = 420;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = context.formFactor;
    final ready = ref.watch(canConfirmPaymentProvider);

    // The dialog's own inset either side, so a 360px phone still gets a
    // dialog rather than a horizontal overflow. Larger screens use the
    // tighter 24px inset below, so they can claim the extra room here.
    final screen = MediaQuery.sizeOf(context);
    final available = screen.width - (form.isMobile ? 80 : 56);
    final width = math.max(
      240.0,
      math.min(
        form.isDesktop
            ? _wideWidth
            : (form.isTablet ? _tabletWidth : _phoneWidth),
        available,
      ),
    );

    // On phones the actions ride the dialog's bottom bar as before; on
    // larger screens they move into the pinned right pane, next to the
    // amount they settle.
    final actions = form.isMobile
        ? <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppStrings.cancel),
            ),
            _ChargeButton(ready: ready, compact: true),
          ]
        : null;

    // Fixed height on larger screens so the row below can split into a
    // scrolling left pane and a pinned right one: the amount due, change
    // and charge button never scroll away, however long the tender form
    // gets. Takes most of the viewport — this is a working surface, not
    // a confirmation popup.
    final height = math.max(
      480.0,
      math.min(760.0, screen.height - 180.0),
    );

    return AlertDialog(
      title: Text(AppStrings.takePayment),
      // Tighter than the default 40px inset on larger screens, so the
      // dialog itself can be bigger on screen.
      insetPadding: form.isMobile
          ? null
          : const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(
        Insets.xl,
        Insets.lg,
        Insets.xl,
        Insets.sm,
      ),
      content: SizedBox(
        width: width,
        child: form.isMobile
            // Scrolls rather than overflows when the system keyboard is up
            // or the text scale is large.
            ? const SingleChildScrollView(child: _NarrowPane())
            : SizedBox(
                height: height,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: SingleChildScrollView(
                        child: _WideForm(wide: form.isDesktop),
                      ),
                    ),
                    const SizedBox(width: Insets.xl),
                    Expanded(
                      flex: 1,
                      child: SingleChildScrollView(
                        // Cash entry first, then the amount due, change and
                        // charge button — the working order at the till.
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _CashSection(),
                            const SizedBox(height: Insets.lg),
                            _ChargePane(ready: ready),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      actions: actions,
    );
  }
}

/// Single-column content for phones — the dialog's bottom bar carries the
/// charge button, as before.
class _NarrowPane extends ConsumerWidget {
  const _NarrowPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = context.formFactor;
    final totals = ref.watch(orderTotalsProvider);
    final payment = ref.watch(paymentDetailsProvider);

    return Column(
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
        // Hidden without `customers.view` — a cashier who can't read
        // the customer list has nothing to pick from, and the picker
        // would only ever 403.
        if (ref.watch(hasPermissionProvider(AppPermissions.customersView))) ...[
          const SizedBox(height: Insets.lg),
          SectionLabel(AppStrings.chargeCustomer),
          const SizedBox(height: Insets.sm),
          const CustomerPickerField(),
        ],
        const SizedBox(height: Insets.lg),
        SectionLabel(AppStrings.chargePaymentMethod),
        const SizedBox(height: Insets.sm),
        _TenderGrid(perRow: 2),
        if (payment.isCash) ...[
          const SizedBox(height: Insets.lg),
          SectionLabel(AppStrings.cashReceived),
          const SizedBox(height: Insets.sm),
          // No autofocus on a phone — it would throw the system keyboard
          // over the chips.
          const CashTenderPanel(),
        ] else ...[
          const SizedBox(height: Insets.lg),
          _TerminalNotice(method: payment.method),
        ],
      ],
    );
  }
}

/// Tender form for desktop and tablet: everything the cashier touches.
///
/// Lives inside the row's scrolling left pane — only this column ever
/// scrolls. The amount due, change and charge button live in [_ChargePane],
/// which sits beside this in a fixed pane that never moves.
///
/// [wide] is true on desktop (tenders three across) and false on tablet
/// (two across, where a third column would squeeze each card).
class _WideForm extends ConsumerWidget {
  const _WideForm({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(orderTotalsProvider);

    return Column(
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
                // The shared totals block — the same one the order panel
                // and the receipt use, so the amount due here cannot drift
                // from the amount due there.
                child: PaymentBreakdown(totals: totals, compact: !wide),
              ),
              // Hidden without `customers.view` — a cashier who can't read
              // the customer list has nothing to pick from, and the picker
              // would only ever 403.
              if (ref.watch(
                hasPermissionProvider(AppPermissions.customersView),
              )) ...[
                const SizedBox(height: Insets.lg),
                SectionLabel(AppStrings.chargeCustomer),
                const SizedBox(height: Insets.sm),
                const CustomerPickerField(),
              ],
              const SizedBox(height: Insets.lg),
              SectionLabel(AppStrings.chargePaymentMethod),
              const SizedBox(height: Insets.sm),
              _TenderGrid(perRow: wide ? 3 : 2),
      ],
    );
  }
}

/// Cash entry for the wide layout's right column, under the charge card:
/// the "cash received" field with its quick chips, or the terminal notice
/// for non-cash tenders.
class _CashSection extends ConsumerWidget {
  const _CashSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payment = ref.watch(paymentDetailsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (payment.isCash) ...[
          SectionLabel(AppStrings.cashReceived),
          const SizedBox(height: Insets.sm),
          // Autofocus only where there is a hardware keyboard: on a
          // phone it would throw the system keyboard over the chips
          // (phones never reach this pane, so this is always true
          // here — kept explicit so the behaviour stays with the
          // widget, not the layout).
          CashTenderPanel(autofocus: context.formFactor.isDesktop),
        ] else ...[
          _TerminalNotice(method: payment.method),
        ],
      ],
    );
  }
}

/// Tender pickup cards — five methods, wrapping [perRow] across.
class _TenderGrid extends ConsumerWidget {
  const _TenderGrid({required this.perRow});

  final int perRow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payment = ref.watch(paymentDetailsProvider);

    return SelectableOptionGrid(
      perRow: perRow,
      children: [
        for (final type in PaymentType.values)
          SelectableOptionCard(
            label: type.label,
            icon: type.icon,
            selected: type == payment.method,
            onTap: () =>
                ref.read(cartProvider.notifier).selectPaymentMethod(type),
          ),
      ],
    );
  }
}

/// Pinned right pane on desktop and tablet: the amount due, what was handed
/// over and what goes back, then the charge button at full width — visible
/// the moment the dialog opens, no scrolling to find it.
class _ChargePane extends ConsumerWidget {
  const _ChargePane({required this.ready});

  final bool ready;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(orderTotalsProvider);
    final payment = ref.watch(paymentDetailsProvider);
    final colors = context.colors;
    final change = payment.changeFor(totals);

    return Container(
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: context.semantic.hairline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.chargeAmountDue,
            style: context.text.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Insets.xs),
          Text(
            Fmt.money(totals.total),
            style: context.text.displaySmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (payment.isCash && payment.amountTendered != null) ...[
            const SizedBox(height: Insets.md),
            _DueRow(
              label: AppStrings.cashTendered,
              value: Fmt.money(payment.amountTendered!),
            ),
            if (change != null) ...[
              const SizedBox(height: Insets.xs),
              _DueRow(
                label: AppStrings.chargeChange,
                value: Fmt.money(change),
                emphasized: true,
              ),
            ],
          ],
          const SizedBox(height: Insets.lg),
          _ChargeButton(ready: ready, compact: false),
          const SizedBox(height: Insets.xs),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.cancel),
          ),
        ],
      ),
    );
  }
}

/// One line of the amount-due card.
class _DueRow extends StatelessWidget {
  const _DueRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : context.text.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
    );
  }
}

/// The settle button, shared by the phone's bottom bar ([compact]) and the
/// wide pane's pinned card. Dead until the cash covers the total — a ticket
/// cannot be settled for less than it is worth.
class _ChargeButton extends ConsumerWidget {
  const _ChargeButton({required this.ready, required this.compact});

  final bool ready;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(orderTotalsProvider);

    final label = Text(
      AppStrings.chargeTotal(Fmt.money(totals.total)),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: compact ? null : context.text.titleMedium,
    );
    const icon = Icon(Icons.check_circle_outline_rounded, size: 22);

    if (compact) {
      return FilledButton.icon(
        onPressed: ready ? () => Navigator.of(context).pop(true) : null,
        icon: const Icon(Icons.check_circle_outline_rounded, size: 19),
        label: Text(
          AppStrings.chargeTotal(Fmt.money(totals.total)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    return FilledButton.icon(
      onPressed: ready ? () => Navigator.of(context).pop(true) : null,
      icon: icon,
      label: label,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: Insets.lg),
      ),
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
              AppStrings.terminalNotice(method.label),
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
