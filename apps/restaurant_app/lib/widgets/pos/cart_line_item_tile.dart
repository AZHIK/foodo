import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/cart.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import 'quantity_stepper.dart';

/// One line of the open order.
///
/// [compact] restacks the row into two tiers for the narrowed tablet panel
/// instead of letting the stepper and the line total fight over the width.
/// [readOnly] swaps the stepper for a plain quantity — the same line, printed
/// rather than editable, once the ticket is being paid for or has been.
class CartLineItemTile extends ConsumerWidget {
  const CartLineItemTile({
    super.key,
    required this.line,
    required this.compact,
    this.readOnly = false,
  });

  final CartItem line;
  final bool compact;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final notifier = ref.read(cartProvider.notifier);
    final id = line.item.id;

    final stepper = readOnly
        ? Text(
            '× ${line.quantity}',
            maxLines: 1,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          )
        : QuantityStepper(
            quantity: line.quantity,
            compact: true,
            onIncrement: () => notifier.add(line.item),
            onDecrement: () => notifier.decrement(id),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row: Item name + Stepper
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  line.item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    fontSize: 13,
                    color: colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: Insets.xs),
              stepper,
            ],
          ),
          const SizedBox(height: Insets.xs),
          // Bottom row: Price each + Line total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${Fmt.money(line.item.price)} each',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              Text(
                Fmt.money(line.lineTotal),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          if (line.note != null && line.note!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              line.note!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.semantic.warning,
                fontStyle: FontStyle.italic,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
