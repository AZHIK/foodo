import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_finance.dart';
import '../../models/order.dart';
import '../../providers/other_expenses_provider.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/data_page/filter_controls.dart';

class OtherExpenseFilterPanel extends ConsumerWidget {
  const OtherExpenseFilterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(otherExpenseFiltersProvider);
    final notifier = ref.read(otherExpenseFiltersProvider.notifier);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(Insets.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilterSection(
              title: 'Category',
              child: FilterChipGroup<String>(
                options: MockFinance.expenseCategories.map((c) => c.id).toList(),
                selected: filters.categoryIds,
                labelOf: (id) => MockFinance.expenseCategoryLabel(id),
                onToggle: (id) => notifier.toggleCategory(id),
              ),
            ),
            SizedBox(height: Insets.lg),
            FilterSection(
              title: 'Payment method',
              child: FilterChipGroup<PaymentType>(
                options: PaymentType.values,
                selected: filters.payments,
                labelOf: (type) => type.label,
                onToggle: (type) => notifier.togglePayment(type),
              ),
            ),
            SizedBox(height: Insets.lg),
            FilterSection(
              title: 'Date range',
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () async {
                    final picked = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now(), initialDateRange: filters.dateRange);
                    if (picked != null) notifier.setDateRange(picked);
                  },
                  child: Text(filters.dateRange == null ? 'Pick a date range' : '${filters.dateRange!.start.month}/${filters.dateRange!.start.day} – ${filters.dateRange!.end.month}/${filters.dateRange!.end.day}'),
                ),
              ),
            ),
            if (filters.activeCount > 0) ...[
              SizedBox(height: Insets.lg),
              SizedBox(width: double.infinity, child: OutlinedButton(onPressed: notifier.clear, child: const Text('Clear all filters'))),
            ],
          ],
        ),
      ),
    );
  }
}
