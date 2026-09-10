/// Other Expenses screen with permission enforcement.
///
/// Screen-level gate: user must have `finance.view` to see the list at all
/// — the same permission covers both the Expenses and Incomes tabs (see
/// `inventory_groceries_screen_gated.dart`'s doc comment, which anticipates
/// this exact split). Action-level gating (add/edit/delete, receipt upload)
/// happens inside `OtherExpensesScreen` itself via `hasPermissionProvider`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/permission.dart';
import '../../widgets/permission_gated_widget.dart';
import 'other_expenses_screen.dart';

/// Gated Other Expenses screen — user must have `finance.view` to access.
class OtherExpensesScreenGated extends ConsumerWidget {
  const OtherExpensesScreenGated({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PermissionGatedScreen(
      requiredPermission: AppPermissions.financeView,
      child: const OtherExpensesScreen(),
      onDenied: (reason) => Scaffold(
        appBar: AppBar(title: const Text('Other expenses')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Finance Access Denied',
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
        appBar: AppBar(title: const Text('Other expenses')),
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
