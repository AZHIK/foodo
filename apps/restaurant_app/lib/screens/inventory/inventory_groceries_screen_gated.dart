/// Groceries screen with permission enforcement.
///
/// Screen-level gate: user must have `inventory.view` to see the list at
/// all. Same permission as Menu Items — the backend has not split
/// `inventory.view` into a grocery/menu-scoped pair, so one gate covers both
/// tabs, matching Finance's Expenses/Incomes split under `finance.view`.
/// Button-level gates on individual actions (add/edit/adjust/waste/
/// transfer/delete) are a follow-up — same stub state as
/// `pos_screen_gated.dart`, the reference implementation this mirrors.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/permission.dart';
import '../../widgets/permission_gated_widget.dart';
import 'inventory_groceries_screen.dart';

/// Gated Groceries screen — user must have `inventory.view` to access.
class InventoryGroceriesScreenGated extends ConsumerWidget {
  const InventoryGroceriesScreenGated({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const PermissionGatedScreen(
      requiredPermission: AppPermissions.inventoryView,
      title: 'Groceries',
      feature: 'Inventory',
      child: InventoryGroceriesScreen(),
    );
  }
}
