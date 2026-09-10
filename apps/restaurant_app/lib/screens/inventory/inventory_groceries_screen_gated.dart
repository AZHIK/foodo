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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/permission.dart';
import '../../widgets/permission_gated_widget.dart';
import 'inventory_groceries_screen.dart';

/// Gated Groceries screen — user must have `inventory.view` to access.
class InventoryGroceriesScreenGated extends ConsumerWidget {
  const InventoryGroceriesScreenGated({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PermissionGatedScreen(
      requiredPermission: AppPermissions.inventoryView,
      child: const InventoryGroceriesScreen(),
      onDenied: (reason) => Scaffold(
        appBar: AppBar(title: const Text('Groceries')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Inventory Access Denied',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(reason, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
      onUnknown: (reason) => Scaffold(
        appBar: AppBar(title: const Text('Groceries')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Offline Mode',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Permission check unavailable. Some features may be disabled.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
