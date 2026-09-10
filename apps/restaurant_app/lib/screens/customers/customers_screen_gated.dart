/// Customers screen with permission enforcement.
///
/// Screen-level gate: user must have `customers.view` to see the list at
/// all. Action-level gating (add/edit/delete) happens inside
/// `CustomersScreen` itself via `hasPermissionProvider`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/permission.dart';
import '../../widgets/permission_gated_widget.dart';
import 'customers_screen.dart';

/// Gated Customers screen — user must have `customers.view` to access.
class CustomersScreenGated extends ConsumerWidget {
  const CustomersScreenGated({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PermissionGatedScreen(
      requiredPermission: AppPermissions.customersView,
      child: const CustomersScreen(),
      onDenied: (reason) => Scaffold(
        appBar: AppBar(title: const Text('Customers')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Customers Access Denied',
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
        appBar: AppBar(title: const Text('Customers')),
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
