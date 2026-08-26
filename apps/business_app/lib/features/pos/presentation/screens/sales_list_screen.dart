import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/fakes/fake_data_service.dart';
import '../../../../shared/widgets/widgets.dart';

/// POS sales history and reporting screen.
///
/// This mocks the POS Service sales list and summary endpoints using
/// [fakeSalesProvider]. It proves [AppDataTable] can render another domain
/// shape beyond Inventory while keeping status, time-suspect, and payment
/// metadata readable in the white-dominant design language.
class SalesListScreen extends ConsumerWidget {
  const SalesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(fakeSalesProvider);
    final completed = sales.where((s) => s.status == FakeSaleStatus.completed);
    final today = DateTime.now();
    final todaySales = completed.where((sale) {
      return sale.createdAt.year == today.year &&
          sale.createdAt.month == today.month &&
          sale.createdAt.day == today.day;
    }).toList();
    final todayRevenue = todaySales.fold<int>(
      0,
      (sum, sale) => sum + sale.totalSenti,
    );

    final columns = <AppDataColumn<FakeSale>>[
      AppDataColumn<FakeSale>(
        key: 'occurred_at',
        label: 'Occurred At',
        isPrimary: true,
        valueExtractor: (sale) => sale.createdAt,
        cellBuilder: (context, sale, _) => Text(
          _formatDateTime(sale.createdAt),
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      AppDataColumn<FakeSale>(
        key: 'status',
        label: 'Status',
        valueExtractor: (sale) => sale.status.name,
        cellBuilder: (context, sale, _) => Wrap(
          spacing: AppDimensions.spaceXS,
          runSpacing: AppDimensions.spaceXXS,
          children: [
            _statusBadge(sale.status),
            if (sale.isTimeSuspect)
              const StatusBadge(
                label: 'Time suspect',
                variant: StatusBadgeVariant.suspect,
                size: StatusBadgeSize.compact,
              ),
          ],
        ),
      ),
      AppDataColumn<FakeSale>(
        key: 'payment_method',
        label: 'Payment',
        valueExtractor: (sale) => _paymentMethodLabel(sale.paymentMethod),
      ),
      AppDataColumn<FakeSale>(
        key: 'total',
        label: 'Total',
        valueExtractor: (sale) => sale.totalSenti,
        cellBuilder: (context, sale, _) => Text(
          MoneyField.formatDisplay(sale.totalSenti),
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        actions: [
          TextButton.icon(
            onPressed: () => context.go(AppRoutes.pos),
            icon: const Icon(Icons.point_of_sale_outlined, size: 18),
            label: const Text('New Sale'),
          ),
          const SizedBox(width: AppDimensions.spaceSM),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide =
                    constraints.maxWidth >= AppDimensions.breakpointTablet;
                final cards = [
                  StatCard(
                    label: 'Today Revenue',
                    value: MoneyField.formatDisplay(todayRevenue),
                    icon: Icons.payments_outlined,
                  ),
                  StatCard(
                    label: 'Today Sales',
                    value: todaySales.length.toString(),
                    icon: Icons.receipt_long_outlined,
                  ),
                ];
                if (!isWide) {
                  return Column(
                    children: [
                      for (final card in cards) ...[
                        card,
                        const SizedBox(height: AppDimensions.spaceSM),
                      ],
                    ],
                  );
                }
                return Row(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppDimensions.spaceMD),
                      Expanded(child: cards[i]),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: AppDimensions.spaceLG),
            Expanded(
              child: AppDataTable<FakeSale>(
                rows: sales,
                columns: columns,
                showSearch: true,
                showExport: true,
                showPagination: true,
                exportFilenamePrefix: 'sales',
                emptyStateIcon: Icons.receipt_long_outlined,
                emptyStateTitle: 'No Sales Yet',
                rowOnTap: (sale) =>
                    context.go('${AppRoutes.posSales}/${sale.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _statusBadge(FakeSaleStatus status) {
  return switch (status) {
    FakeSaleStatus.completed => const StatusBadge(
      label: 'Completed',
      variant: StatusBadgeVariant.success,
      size: StatusBadgeSize.compact,
    ),
    FakeSaleStatus.voided => const StatusBadge(
      label: 'Voided',
      variant: StatusBadgeVariant.danger,
      size: StatusBadgeSize.compact,
    ),
    FakeSaleStatus.refunded => const StatusBadge(
      label: 'Refunded',
      variant: StatusBadgeVariant.warning,
      size: StatusBadgeSize.compact,
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
