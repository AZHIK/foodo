import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/fakes/fake_data_service.dart';
import '../../../../shared/widgets/widgets.dart';

/// Detailed POS sale view.
///
/// Shows receipt lines, totals, payment metadata, and guarded void/refund
/// actions. State transitions mirror the backend rule: only completed sales
/// can be voided or refunded, and both require a reason before mutating fake
/// state.
class SaleDetailScreen extends ConsumerWidget {
  const SaleDetailScreen({super.key, required this.saleId});

  final String saleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(fakeSalesProvider);
    final sale = sales.where((s) => s.id == saleId).firstOrNull;

    if (sale == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sale Detail')),
        body: Center(
          child: AppEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Sale Not Found',
            action: AppSecondaryButton(
              label: 'Back to Sales',
              expanded: false,
              onPressed: () => context.go(AppRoutes.posSales),
            ),
          ),
        ),
      );
    }

    final canTransition = sale.status == FakeSaleStatus.completed;
    return Scaffold(
      appBar: AppBar(title: Text(sale.receiptNumber)),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMD),
        children: [
          AppCard.elevated(
            padding: const EdgeInsets.all(AppDimensions.spaceLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: AppDimensions.spaceSM,
                  runSpacing: AppDimensions.spaceSM,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Sale Detail',
                      style: AppTextStyles.headlineSmall,
                    ),
                    _statusBadge(sale.status),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceLG),
                for (final line in sale.lines) ...[
                  _SaleLineRow(line: line),
                  const SizedBox(height: AppDimensions.spaceSM),
                ],
                const Divider(),
                _TotalRow(label: 'Subtotal', valueSenti: sale.subtotalSenti),
                _TotalRow(label: 'Discount', valueSenti: -sale.discountSenti),
                _TotalRow(label: 'VAT 18%', valueSenti: sale.taxSenti),
                const Divider(),
                _TotalRow(
                  label: 'Total',
                  valueSenti: sale.totalSenti,
                  isTotal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceLG),
          InfoCard(
            label: 'Payment',
            value: _paymentMethodLabel(sale.paymentMethod),
            description:
                '${sale.staffName} • ${_formatDateTime(sale.createdAt)}',
            leading: const Icon(Icons.payments_outlined),
          ),
          if (sale.isTimeSuspect) ...[
            const SizedBox(height: AppDimensions.spaceSM),
            AppInfoContainer(
              color: AppColors.timeSuspect.withValues(alpha: 0.12),
              icon: Icons.schedule_outlined,
              title: 'Time suspect',
              child: Text(
                'This sale was flagged with a suspect device timestamp.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.timeSuspect,
                ),
              ),
            ),
          ],
          if (sale.voidRefundReason != null) ...[
            const SizedBox(height: AppDimensions.spaceSM),
            InfoCard(
              label: 'Reason',
              value: sale.voidRefundReason!,
              leading: const Icon(Icons.notes_outlined),
            ),
          ],
          const SizedBox(height: AppDimensions.spaceLG),
          Wrap(
            spacing: AppDimensions.spaceSM,
            runSpacing: AppDimensions.spaceSM,
            children: [
              AppSecondaryButton(
                label: 'Void',
                icon: Icons.block_outlined,
                expanded: false,
                isDestructive: true,
                onPressed: canTransition
                    ? () => _requestReason(
                        context: context,
                        title: 'Void Sale',
                        confirmLabel: 'Void',
                        onConfirmed: (reason) {
                          ref
                              .read(fakeSalesProvider.notifier)
                              .voidSale(sale.id, reason);
                        },
                      )
                    : null,
              ),
              AppSecondaryButton(
                label: 'Refund',
                icon: Icons.undo_outlined,
                expanded: false,
                onPressed: canTransition
                    ? () => _requestReason(
                        context: context,
                        title: 'Refund Sale',
                        confirmLabel: 'Refund',
                        onConfirmed: (reason) {
                          ref
                              .read(fakeSalesProvider.notifier)
                              .refundSale(sale.id, reason);
                        },
                      )
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SaleLineRow extends StatelessWidget {
  const _SaleLineRow({required this.line});

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

class _TotalRow extends StatelessWidget {
  const _TotalRow({
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

Future<void> _requestReason({
  required BuildContext context,
  required String title,
  required String confirmLabel,
  required ValueChanged<String> onConfirmed,
}) async {
  final formKey = GlobalKey<FormState>();
  final controller = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: AppTextField(
          controller: controller,
          label: 'Reason',
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Reason is required'
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!(formKey.currentState?.validate() ?? false)) return;
            onConfirmed(controller.text.trim());
            Navigator.of(context).pop();
          },
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

Widget _statusBadge(FakeSaleStatus status) {
  return switch (status) {
    FakeSaleStatus.completed => const StatusBadge(
      label: 'Completed',
      variant: StatusBadgeVariant.success,
    ),
    FakeSaleStatus.voided => const StatusBadge(
      label: 'Voided',
      variant: StatusBadgeVariant.danger,
    ),
    FakeSaleStatus.refunded => const StatusBadge(
      label: 'Refunded',
      variant: StatusBadgeVariant.warning,
    ),
  };
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
