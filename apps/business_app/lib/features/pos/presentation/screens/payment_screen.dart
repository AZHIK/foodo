import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/fakes/fake_data_service.dart';
import '../../../../shared/widgets/widgets.dart';

/// Payment confirmation step for a locally built POS ticket.
///
/// This screen intentionally performs no network work. It records the sale into
/// [fakeSalesProvider] immediately and returns the completed [FakeSale] to the
/// caller, preserving POS's offline-first completion model.
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({
    super.key,
    required this.lines,
    required this.subtotalSenti,
    required this.saleDiscountSenti,
    required this.taxSenti,
    required this.totalSenti,
  });

  final List<PaymentLineDraft> lines;
  final int subtotalSenti;
  final int saleDiscountSenti;
  final int taxSenti;
  final int totalSenti;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  FakePaymentMethod _method = FakePaymentMethod.cash;

  void _confirm() {
    final sale = ref
        .read(fakeSalesProvider.notifier)
        .completeSale(
          lines: widget.lines
              .map(
                (line) => FakeSaleLine(
                  itemId: line.itemId,
                  itemName: line.itemName,
                  quantity: line.quantity,
                  unitPriceSenti: line.unitPriceSenti,
                  discountSenti: line.discountSenti,
                  subtotalSenti:
                      line.quantity * line.unitPriceSenti - line.discountSenti,
                ),
              )
              .toList(),
          subtotalSenti: widget.subtotalSenti,
          discountSenti: widget.saleDiscountSenti,
          taxSenti: widget.taxSenti,
          totalSenti: widget.totalSenti,
          paymentMethod: _method,
        );
    Navigator.of(context).pop(sale);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceLG),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Complete Sale', style: AppTextStyles.headlineSmall),
              const SizedBox(height: AppDimensions.spaceSM),
              Text(
                'Choose a payment method. The sale will be completed locally.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLG),
              AppDropdownField<FakePaymentMethod>(
                label: 'Payment Method',
                value: _method,
                options: FakePaymentMethod.values,
                labelBuilder: _paymentMethodLabel,
                onChanged: (value) {
                  if (value != null) setState(() => _method = value);
                },
              ),
              const SizedBox(height: AppDimensions.spaceLG),
              AppCard.flat(
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                child: Column(
                  children: [
                    _PaymentTotalRow(
                      label: 'Subtotal',
                      valueSenti: widget.subtotalSenti,
                    ),
                    _PaymentTotalRow(
                      label: 'Discount',
                      valueSenti: -widget.saleDiscountSenti,
                    ),
                    _PaymentTotalRow(
                      label: 'VAT 18%',
                      valueSenti: widget.taxSenti,
                    ),
                    const Divider(),
                    _PaymentTotalRow(
                      label: 'Total',
                      valueSenti: widget.totalSenti,
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLG),
              Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceMD),
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'Confirm',
                      icon: Icons.check_rounded,
                      onPressed: _confirm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Immutable line draft passed from the sale-builder to the payment step.
class PaymentLineDraft {
  const PaymentLineDraft({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitPriceSenti,
    this.discountSenti = 0,
  });

  final String itemId;
  final String itemName;
  final int quantity;
  final int unitPriceSenti;
  final int discountSenti;
}

class _PaymentTotalRow extends StatelessWidget {
  const _PaymentTotalRow({
    required this.label,
    required this.valueSenti,
    this.isTotal = false,
  });

  final String label;
  final int valueSenti;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final style = isTotal
        ? AppTextStyles.titleMedium
        : AppTextStyles.bodyMedium;
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
