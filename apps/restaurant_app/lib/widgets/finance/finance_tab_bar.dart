import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_strings.dart';
import '../../theme/breakpoints.dart';

enum FinanceTab { expenses, incomes }

class FinanceTabBar extends StatelessWidget {
  const FinanceTabBar({super.key, required this.active});

  final FinanceTab active;

  @override
  Widget build(BuildContext context) {
    final pad = Insets.page(context.formFactor);

    return Padding(
      padding: EdgeInsets.fromLTRB(pad, Insets.md, pad, Insets.md),
      child: SegmentedButton<FinanceTab>(
        segments: [
          ButtonSegment(
            value: FinanceTab.expenses,
            label: Text(AppStrings.financeExpensesTab),
            icon: Icon(Icons.arrow_upward_rounded),
          ),
          ButtonSegment(
            value: FinanceTab.incomes,
            label: Text(AppStrings.financeIncomesTab),
            icon: Icon(Icons.arrow_downward_rounded),
          ),
        ],
        selected: {active},
        onSelectionChanged: (selected) {
          final tab = selected.first;
          if (tab == FinanceTab.expenses) {
            context.replace('/finance/expenses');
          } else {
            context.replace('/finance/incomes');
          }
        },
      ),
    );
  }
}
