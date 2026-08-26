import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import 'order_summary_panel.dart';

/// The mobile stand-in for the desktop order panel: a sticky summary bar that
/// expands into a full-height sheet holding the same ticket.
class CartBottomSheet extends StatelessWidget {
  const CartBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // Leave the status bar visible so the sheet reads as a layer over the
      // grid rather than a new screen.
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => const CartBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Padding(
      // Lifts the whole sheet — totals and Charge included — clear of the
      // keyboard if one is open behind it.
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Flexible(child: OrderTicketBody(compact: true)),
              OrderTotalsFooter(compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sticky bar above the bottom navigation on mobile: item count, running
/// total, and the way into the full ticket.
class CartSummaryBar extends ConsumerWidget {
  const CartSummaryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final count = ref.watch(cartItemCountProvider);
    final total = ref.watch(cartProvider.select((cart) => cart.total));

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: context.semantic.hairline)),
      ),
      child: SafeArea(
        top: false,
        // The shell's navigation bar sits below and already claims the inset.
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.lg,
            Insets.sm,
            Insets.lg,
            Insets.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      count == 0
                          ? 'No items'
                          : '$count ${count == 1 ? 'item' : 'items'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        letterSpacing: 0.4,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Fmt.money(total),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Insets.lg),
              FilledButton.icon(
                onPressed: count == 0
                    ? null
                    : () => CartBottomSheet.show(context),
                icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                label: const Text('View'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
