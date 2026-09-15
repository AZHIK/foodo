/// Other Expenses screen with permission enforcement.
///
/// Screen-level gate: user must have `finance.view` to see the list at all
/// — the same permission covers both the Expenses and Incomes tabs (see
/// `inventory_groceries_screen_gated.dart`'s doc comment, which anticipates
/// this exact split). Action-level gating (add/edit/delete, receipt upload)
/// happens inside `OtherExpensesScreen` itself via `hasPermissionProvider`.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/permission.dart';
import '../../widgets/permission_gated_widget.dart';
import 'other_expenses_screen.dart';

/// Gated Other Expenses screen — user must have `finance.view` to access.
class OtherExpensesScreenGated extends ConsumerWidget {
  const OtherExpensesScreenGated({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const PermissionGatedScreen(
      requiredPermission: AppPermissions.financeView,
      title: 'Other expenses',
      feature: 'Finance',
      child: OtherExpensesScreen(),
    );
  }
}
