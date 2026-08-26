import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/widgets.dart';
import 'pos_layout_model.dart';

/// How much room a cart row has to work with.
enum PosCartLineVariant {
  /// Narrow columns and phone width: no thumbnail, quantity stepper and
  /// line total share one row.
  compact,

  /// Wide cart column: rounded thumbnail tile, inline
  /// `unit × qty = total` price line, and a circular remove button
  /// overlapping the row corner.
  detailed,
}

/// A single cart row, rendered at the density the calling layout asks for.
///
/// Both variants expose exactly the same actions (quantity, per-line
/// discount, remove) — only the arrangement changes, so no form factor
/// loses a capability.
class PosCartLineTile extends StatelessWidget {
  const PosCartLineTile({
    super.key,
    required this.line,
    required this.variant,
    required this.onQuantityChanged,
    required this.onRemoved,
    required this.onDiscountChanged,
  });

  final PosCartLine line;
  final PosCartLineVariant variant;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemoved;
  final ValueChanged<int> onDiscountChanged;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      PosCartLineVariant.compact => _CompactLine(
        line: line,
        onQuantityChanged: onQuantityChanged,
        onRemoved: onRemoved,
        onDiscountChanged: onDiscountChanged,
      ),
      PosCartLineVariant.detailed => _DetailedLine(
        line: line,
        onQuantityChanged: onQuantityChanged,
        onRemoved: onRemoved,
        onDiscountChanged: onDiscountChanged,
      ),
    };
  }
}

class _CompactLine extends StatelessWidget {
  const _CompactLine({
    required this.line,
    required this.onQuantityChanged,
    required this.onRemoved,
    required this.onDiscountChanged,
  });

  final PosCartLine line;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemoved;
  final ValueChanged<int> onDiscountChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard.flat(
      padding: const EdgeInsets.all(AppDimensions.spaceSM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.item.name,
                      style: AppTextStyles.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.spaceXXS),
                    Text(
                      MoneyField.formatDisplay(line.item.priceSenti),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemoved,
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Remove line',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSM),
          Row(
            children: [
              SizedBox(
                width: 132,
                child: AppNumberField(
                  initialValue: line.quantity,
                  min: 0,
                  allowNegative: false,
                  allowZero: true,
                  onChanged: onQuantityChanged,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      MoneyField.formatDisplay(line.lineTotalSenti),
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    TextButton.icon(
                      onPressed: () => showPosDiscountDialog(
                        context: context,
                        title: 'Line Discount',
                        currentValueSenti: line.discountSenti,
                        maxValueSenti: line.grossTotalSenti,
                        onChanged: onDiscountChanged,
                      ),
                      icon: const Icon(Icons.sell_outlined, size: 16),
                      label: Text(
                        line.discountSenti > 0
                            ? '-${MoneyField.formatDisplay(line.discountSenti)}'
                            : 'Add discount',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailedLine extends StatelessWidget {
  const _DetailedLine({
    required this.line,
    required this.onQuantityChanged,
    required this.onRemoved,
    required this.onDiscountChanged,
  });

  final PosCartLine line;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemoved;
  final ValueChanged<int> onDiscountChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard.flat(
      padding: const EdgeInsets.all(AppDimensions.spaceSM),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                ),
                child: Icon(
                  Icons.restaurant_outlined,
                  size: 20,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.item.name,
                      style: AppTextStyles.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.spaceXXS),
                    Text(
                      '${MoneyField.formatDisplay(line.item.priceSenti)} '
                      '× ${line.quantity} = '
                      '${MoneyField.formatDisplay(line.lineTotalSenti)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.spaceSM),
                    Row(
                      children: [
                        Expanded(
                          child: AppNumberField(
                            initialValue: line.quantity,
                            min: 0,
                            allowNegative: false,
                            allowZero: true,
                            onChanged: onQuantityChanged,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceXS),
                        IconButton(
                          onPressed: () => showPosDiscountDialog(
                            context: context,
                            title: 'Line Discount',
                            currentValueSenti: line.discountSenti,
                            maxValueSenti: line.grossTotalSenti,
                            onChanged: onDiscountChanged,
                          ),
                          tooltip: line.discountSenti > 0
                              ? 'Discount: '
                                    '-${MoneyField.formatDisplay(line.discountSenti)}'
                              : 'Add discount',
                          icon: Icon(
                            Icons.sell_outlined,
                            size: 18,
                            color: line.discountSenti > 0
                                ? cs.primary
                                : cs.onSurface.withValues(alpha: 0.5),
                          ),
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    if (line.discountSenti > 0) ...[
                      const SizedBox(height: AppDimensions.spaceXXS),
                      Text(
                        'Discount: '
                        '-${MoneyField.formatDisplay(line.discountSenti)}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: cs.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Positioned(top: -4, right: -4, child: _RemoveDot(onTap: onRemoved)),
        ],
      ),
    );
  }
}

class _RemoveDot extends StatelessWidget {
  const _RemoveDot({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.error,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.close_rounded, size: 12, color: Colors.white),
        ),
      ),
    );
  }
}

/// Subtotal / sale discount / VAT / total block — identical maths on every
/// form factor, so it is written once and reused by all three layouts.
class PosTicketSummary extends StatelessWidget {
  const PosTicketSummary({
    super.key,
    required this.subtotalSenti,
    required this.saleDiscountSenti,
    required this.taxSenti,
    required this.totalSenti,
    required this.onSaleDiscountChanged,
  });

  final int subtotalSenti;
  final int saleDiscountSenti;
  final int taxSenti;
  final int totalSenti;
  final ValueChanged<int> onSaleDiscountChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SummaryRow(label: 'Subtotal', valueSenti: subtotalSenti),
        _SummaryRow(
          label: 'Sale Discount',
          valueSenti: -saleDiscountSenti,
          action: TextButton.icon(
            onPressed: subtotalSenti == 0
                ? null
                : () => showPosDiscountDialog(
                    context: context,
                    title: 'Sale Discount',
                    currentValueSenti: saleDiscountSenti,
                    maxValueSenti: subtotalSenti,
                    onChanged: onSaleDiscountChanged,
                  ),
            icon: const Icon(Icons.sell_outlined, size: 16),
            label: Text(saleDiscountSenti > 0 ? 'Edit' : 'Add'),
          ),
        ),
        _SummaryRow(label: 'VAT 18%', valueSenti: taxSenti),
        const Divider(),
        _SummaryRow(label: 'Total', valueSenti: totalSenti, isTotal: true),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.valueSenti,
    this.action,
    this.isTotal = false,
  });

  final String label;
  final int valueSenti;
  final Widget? action;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final style = isTotal ? AppTextStyles.titleLarge : AppTextStyles.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceXXS),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          ?action,
          Text(
            MoneyField.formatDisplay(valueSenti),
            style: style.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Placeholder shown in place of the cart list when nothing is on the
/// ticket yet.
class PosEmptyCart extends StatelessWidget {
  const PosEmptyCart({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: cs.onSurface.withValues(alpha: 0.34),
          ),
          const SizedBox(height: AppDimensions.spaceSM),
          const Text('Cart Is Empty', style: AppTextStyles.titleSmall),
          const SizedBox(height: AppDimensions.spaceXXS),
          Text(
            'Add an item to start a local sale.',
            style: AppTextStyles.bodySmall.copyWith(
              color: cs.onSurface.withValues(alpha: 0.56),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

Future<void> showPosDiscountDialog({
  required BuildContext context,
  required String title,
  required int currentValueSenti,
  required int maxValueSenti,
  required ValueChanged<int> onChanged,
}) async {
  var discountSenti = currentValueSenti;
  final controller = TextEditingController(text: currentValueSenti.toString());
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: MoneyField(
        controller: controller,
        label: 'Discount Amount',
        initialSenti: currentValueSenti,
        minSenti: 0,
        maxSenti: maxValueSenti,
        allowZero: true,
        onChanged: (value) => discountSenti = value,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            onChanged(discountSenti);
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    ),
  );
  controller.dispose();
}
