/// Other Incomes screen with permission enforcement.
///
/// Mirror of `other_expenses_screen_gated.dart` — same `finance.view` gate,
/// same reasoning.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/permission.dart';
import '../../widgets/permission_gated_widget.dart';
import 'other_incomes_screen.dart';

/// Gated Other Incomes screen — user must have `finance.view` to access.
class OtherIncomesScreenGated extends ConsumerWidget {
  const OtherIncomesScreenGated({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const PermissionGatedScreen(
      requiredPermission: AppPermissions.financeView,
      title: 'Other income',
      feature: 'Finance',
      child: OtherIncomesScreen(),
    );
  }
}
