import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_strings.dart';
import '../../models/order.dart';
import '../../providers/orders_provider.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/data_page/filter_controls.dart';
import 'sales_date_range_selector.dart';

/// The Sales-specific contents of the shared filter popover/sheet.
class SalesFilterPanel extends ConsumerWidget {
  const SalesFilterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(salesFiltersProvider);
    final notifier = ref.read(salesFiltersProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // The same control as the page header, driving the same state — so
        // changing the period here updates the header chip, and vice versa.
        FilterSection(
          title: AppStrings.dateRangeFilter,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SalesDateRangeSelector(filled: false),
          ),
        ),
        const SizedBox(height: Insets.xl),
        FilterSection(
          title: AppStrings.paymentMethodFilter,
          child: FilterChipGroup<PaymentType>(
            options: PaymentType.values,
            selected: filters.payments,
            labelOf: (payment) => payment.label,
            onToggle: notifier.togglePayment,
          ),
        ),
        const SizedBox(height: Insets.xl),
        FilterSection(
          title: AppStrings.statusFilter,
          child: FilterChipGroup<OrderStatus>(
            options: OrderStatus.values,
            selected: filters.statuses,
            labelOf: (status) => status.label,
            onToggle: notifier.toggleStatus,
          ),
        ),
      ],
    );
  }
}
