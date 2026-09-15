/// Menu Items screen with permission enforcement.
///
/// Screen-level gate: user must have `inventory.view` to see the list at
/// all — same permission as Groceries, see that screen's gated wrapper for
/// why. Button-level gates on individual actions are a follow-up, same stub
/// state as `pos_screen_gated.dart`.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/permission.dart';
import '../../widgets/permission_gated_widget.dart';
import 'inventory_menu_items_screen.dart';

/// Gated Menu Items screen — user must have `inventory.view` to access.
class InventoryMenuItemsScreenGated extends ConsumerWidget {
  const InventoryMenuItemsScreenGated({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const PermissionGatedScreen(
      requiredPermission: AppPermissions.inventoryView,
      title: 'Menu items',
      feature: 'Inventory',
      child: InventoryMenuItemsScreen(),
    );
  }
}
