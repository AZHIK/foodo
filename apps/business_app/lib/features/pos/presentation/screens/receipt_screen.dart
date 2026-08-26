import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/fakes/fake_data_service.dart';
import '../../../../shared/widgets/widgets.dart';

/// In-app receipt view shown immediately after local POS completion.
///
/// The receipt is independent of sync state: once a sale is completed locally,
/// the user can view the receipt whether online or offline. PDF/printing is
/// intentionally out of scope for MVP; this screen provides a clean
/// receipt-like rhythm for review and handoff.
class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key, required this.sale});

  final FakeSale sale;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.spaceMD),
            children: [
              AppCard.elevated(
                padding: const EdgeInsets.all(AppDimensions.spaceLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Foodo',
                      style: AppTextStyles.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.spaceXXS),
                    Text(
                      sale.receiptNumber,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.58),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.spaceLG),
                    for (final line in sale.lines) ...[
                      _ReceiptLine(line: line),
                      const SizedBox(height: AppDimensions.spaceSM),
                    ],
                    const Divider(),
                    _ReceiptTotal(
                      label: 'Subtotal',
                      valueSenti: sale.subtotalSenti,
                    ),
                    _ReceiptTotal(
                      label: 'Discount',
                      valueSenti: -sale.discountSenti,
                    ),
                    _ReceiptTotal(label: 'VAT 18%', valueSenti: sale.taxSenti),
                    const Divider(),
                    _ReceiptTotal(
                      label: 'Total',
                      valueSenti: sale.totalSenti,
                      isTotal: true,
                    ),
                    const SizedBox(height: AppDimensions.spaceLG),
                    InfoCard(
                      label: 'Payment',
                      value: _paymentMethodLabel(sale.paymentMethod),
                      description: _formatDateTime(sale.createdAt),
                      leading: const Icon(Icons.payments_outlined),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLG),
              AppPrimaryButton(
                label: 'New Sale',
                icon: Icons.point_of_sale_outlined,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  const _ReceiptLine({required this.line});

  final FakeSaleLine line;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(line.itemName, style: AppTextStyles.titleSmall),
              Text(
                '${line.quantity} x ${MoneyField.formatDisplay(line.unitPriceSenti)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.58),
                ),
              ),
            ],
          ),
        ),
        Text(
          MoneyField.formatDisplay(line.subtotalSenti),
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ReceiptTotal extends StatelessWidget {
  const _ReceiptTotal({
    required this.label,
    required this.valueSenti,
    this.isTotal = false,
  });

  final String label;
  final int valueSenti;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final style = isTotal ? AppTextStyles.titleLarge : AppTextStyles.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceXXS),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(
            MoneyField.formatDisplay(valueSenti),
            style: style.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

String _paymentMethodLabel(FakePaymentMethod method) {
  return switch (method) {
    FakePaymentMethod.cash => 'Cash',
    FakePaymentMethod.mobileMoney => 'Mobile money',
    FakePaymentMethod.card => 'Card',
    FakePaymentMethod.other => 'Other',
  };
}

String _formatDateTime(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final mo = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '$y-$mo-$day $hh:$mm';
}
