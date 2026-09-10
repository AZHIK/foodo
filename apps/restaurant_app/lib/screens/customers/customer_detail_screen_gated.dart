/// Customer detail screen with permission enforcement.
///
/// Gated separately from the list screen — `/customers/:customerId` is
/// independently deep-linkable, so a denied user who guesses or bookmarks
/// an id must not still be able to read a full profile plus order history.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/permission.dart';
import '../../widgets/permission_gated_widget.dart';
import 'customer_detail_screen.dart';

/// Gated customer detail screen — user must have `customers.view` to access.
class CustomerDetailScreenGated extends ConsumerWidget {
  const CustomerDetailScreenGated({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PermissionGatedScreen(
      requiredPermission: AppPermissions.customersView,
      child: CustomerDetailScreen(customerId: customerId),
      onDenied: (reason) => Scaffold(
        appBar: AppBar(title: const Text('Customer')),
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
        appBar: AppBar(title: const Text('Customer')),
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
