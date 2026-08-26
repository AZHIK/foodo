import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cart_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';
import '../utils/formatters.dart';
import 'selectable_option_card.dart';

/// Cash entry: what was handed over, and what to give back.
///
/// Reads and writes the tender on the cart provider rather than holding it
/// locally, so the change due here, the change due on the order panel and the
/// change printed on the receipt are all one number being read three times.
class CashTenderPanel extends ConsumerStatefulWidget {
  const CashTenderPanel({super.key, this.autofocus = false});

  /// Focus the amount field on open — right on a desktop terminal with a
  /// keyboard, wrong on a phone where it would throw up the system keyboard
  /// over the very buttons the cashier is reaching for.
  final bool autofocus;

  @override
  ConsumerState<CashTenderPanel> createState() => _CashTenderPanelState();
}

class _CashTenderPanelState extends ConsumerState<CashTenderPanel> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final tendered = ref.read(paymentDetailsProvider).amountTendered;
    _controller = TextEditingController(
      text: tendered == null ? '' : Fmt.editableAmount(tendered),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Mirrors a change made *elsewhere* — a quick-amount chip, "Exact" — back
  /// into the field, without fighting the cashier for the cursor while they
  /// are mid-word.
  void _syncField(double? amount) {
    final typed = Fmt.parseAmount(_controller.text);
    if (typed == amount) return;

    final text = amount == null ? '' : Fmt.editableAmount(amount);
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.read(cartProvider.notifier);
    final totals = ref.watch(orderTotalsProvider);
    final tendered = ref.watch(
      paymentDetailsProvider.select((p) => p.amountTendered),
    );
    final change = ref.watch(changeDueProvider);
    final quickAmounts = ref.watch(cashQuickAmountsProvider);

    ref.listen(paymentDetailsProvider.select((p) => p.amountTendered), (
      _,
      next,
    ) {
      _syncField(next);
    });

    // How far short the customer still is, or null once they have covered it.
    final shortfall = tendered != null && !totals.covers(tendered)
        ? totals.total - tendered
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          autofocus: widget.autofocus,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            labelText: 'Amount tendered',
            prefixText: '${Fmt.currencySymbol} ',
            hintText: Fmt.editableAmount(totals.total),
            suffixIcon: tendered == null
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.backspace_outlined, size: 18),
                    onPressed: () => cart.setAmountTendered(null),
                  ),
          ),
          onChanged: (value) => cart.setAmountTendered(Fmt.parseAmount(value)),
        ),
        const SizedBox(height: Insets.md),
        _QuickAmounts(amounts: quickAmounts),
        const SizedBox(height: Insets.md),
        // The answer to "what do I hand back?", sized to be read at a glance
        // across a counter rather than squinted at.
        _ChangeCallout(change: change, shortfall: shortfall),
      ],
    );
  }
}

/// One-tap top-ups. Configured amounts plus "Exact", which is the single most
/// common cash outcome and otherwise takes four keystrokes.
///
/// Always three to a row, at every breakpoint and on every screen that takes
/// cash: a fixed grid means the note a cashier reaches for is in the same
/// place on the phone in their hand as on the terminal at the counter. The
/// labels scale down inside their column rather than the columns resizing to
/// fit the labels, so the arrangement holds at 360px.
class _QuickAmounts extends ConsumerWidget {
  const _QuickAmounts({required this.amounts});

  static const perRow = 3;

  final List<double> amounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartProvider.notifier);

    return SelectableOptionGrid(
      perRow: perRow,
      children: [
        for (final amount in amounts)
          _QuickChip(
            label: '+${Fmt.money(amount)}',
            onTap: () => cart.addTender(amount),
          ),
        _QuickChip(label: 'Exact', emphasis: true, onTap: cart.tenderExact),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.onTap,
    this.emphasis = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: emphasis
          ? colors.primaryContainer
          : colors.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.pill),
        side: BorderSide(
          color: emphasis ? colors.primary : context.semantic.hairline,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Type size comes from the column, not from the label: every chip
            // in a row is handed the same width, so they all land on the same
            // size and read as one set. Scaling each label to fit itself
            // instead would leave "+$5.00" a size larger than "+$50.00".
            final style =
                (constraints.maxWidth < 96
                        ? context.text.labelMedium
                        : context.text.labelLarge)
                    ?.copyWith(
                      color: emphasis
                          ? colors.onPrimaryContainer
                          : colors.onSurface,
                      fontWeight: FontWeight.w700,
                    );

            return Container(
              // 44px minimum: these are tapped with a thumb on a busy counter,
              // at every breakpoint, not just on mobile.
              constraints: const BoxConstraints(minHeight: 44),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: Insets.sm),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: style,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Change due, or how far short the customer still is.
class _ChangeCallout extends StatelessWidget {
  const _ChangeCallout({required this.change, required this.shortfall});

  final double? change;

  /// Non-null while the tender does not cover the total.
  final double? shortfall;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final colors = context.colors;

    final (background, foreground, label, value) = switch ((shortfall, change)) {
      (final owing?, _) => (
        semantic.warningContainer,
        semantic.warning,
        'Still owing',
        Fmt.money(owing),
      ),
      (_, final due?) => (
        semantic.successContainer,
        semantic.success,
        'Change due',
        Fmt.money(due),
      ),
      // Nothing keyed in yet: hold the space so the dialog does not jump when
      // the first digit lands.
      _ => (
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
        'Change due',
        '—',
      ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.lg,
        vertical: Insets.md,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelLarge?.copyWith(color: foreground),
            ),
          ),
          const SizedBox(width: Insets.sm),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: context.text.headlineSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
