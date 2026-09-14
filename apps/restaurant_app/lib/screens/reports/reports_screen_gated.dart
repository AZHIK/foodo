/// Reports screen with permission enforcement.
///
/// Screen-level gate: user must have `reports.view` to read any section.
/// Export buttons gate themselves on `reports.export` inside the screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/permission.dart';
import '../../widgets/permission_gated_widget.dart';
import 'reports_screen.dart';

/// Gated Reports screen — user must have `reports.view` to access.
class ReportsScreenGated extends ConsumerWidget {
  const ReportsScreenGated({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PermissionGatedScreen(
      requiredPermission: AppPermissions.reportsView,
      child: const ReportsScreen(),
      onDenied: (reason) => Scaffold(
        appBar: AppBar(title: const Text('Reports')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Reports Access Denied',
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
        appBar: AppBar(title: const Text('Reports')),
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
