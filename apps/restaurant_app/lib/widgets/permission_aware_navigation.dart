/// Permission-aware navigation: hides menu items without read access.
///
/// Maps each navigation destination to its required view/read permission.
/// Menu items are hidden if the user lacks that permission.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/permission.dart';
import '../providers/permissions_provider.dart';

/// Navigation destination with its required permission.
class NavigationDestination {
  const NavigationDestination({
    required this.label,
    required this.requiredPermission,
  });

  final String label;
  final String requiredPermission;
}

/// Map each navigation item to its minimum required permission (read/view).
const Map<int, NavigationDestination> _navigationPermissions = {
  0: NavigationDestination(label: 'Dashboard', requiredPermission: 'dashboard'), // No permission check
  1: NavigationDestination(label: 'POS', requiredPermission: AppPermissions.posAccess),
  2: NavigationDestination(label: 'Sales', requiredPermission: AppPermissions.salesView),
  3: NavigationDestination(label: 'Customers', requiredPermission: 'customers'), // No strict permission
  4: NavigationDestination(label: 'Reorders', requiredPermission: 'reorders'),
  5: NavigationDestination(label: 'Couriers', requiredPermission: 'couriers'),
  6: NavigationDestination(label: 'Finance', requiredPermission: 'finance'),
  7: NavigationDestination(label: 'Reports', requiredPermission: AppPermissions.reportsView),
  8: NavigationDestination(label: 'Insights', requiredPermission: 'insights'),
  9: NavigationDestination(label: 'Inventory', requiredPermission: AppPermissions.inventoryView),
  10: NavigationDestination(label: 'Staff', requiredPermission: AppPermissions.staffView),
  11: NavigationDestination(label: 'Settings', requiredPermission: AppPermissions.settingsStore),
};

/// Provider: check if user can access a navigation destination.
///
/// Returns true if user has the required read permission.
/// Returns false if offline/unknown (safe fail: don't show menu item).
final canAccessNavDestinationProvider = FutureProvider.family<bool, int>(
  (ref, destinationIndex) async {
    final destination = _navigationPermissions[destinationIndex];
    if (destination == null) return false;

    // Special cases: some destinations don't require permission checks
    if (destination.requiredPermission == 'dashboard' ||
        destination.requiredPermission == 'customers' ||
        destination.requiredPermission == 'reorders' ||
        destination.requiredPermission == 'couriers' ||
        destination.requiredPermission == 'finance' ||
        destination.requiredPermission == 'insights') {
      return true; // Always accessible
    }

    // Check actual permission
    final permsResult = await ref.watch(currentUserPermissionsProvider.future);

    return permsResult.when(
      onKnown: (permissions, _) {
        return permissions.contains('*') || permissions.contains(destination.requiredPermission);
      },
      onUnknown: () => false, // Offline: hide unless always-accessible
    );
  },
);

/// Safe navigation check - returns false if offline (hide menu item).
/// Use this in UI builders for conditional rendering.
Future<bool> canAccessDestination(WidgetRef ref, int destinationIndex) async {
  try {
    final canAccess = await ref.read(canAccessNavDestinationProvider(destinationIndex).future);
    return canAccess;
  } catch (_) {
    return false; // On error, hide menu item
  }
}
