/// Customers screen with permission enforcement.
///
/// Screen-level gate: user must have `customers.view` to see the list at
/// all. Action-level gating (add/edit/delete) happens inside
/// `CustomersScreen` itself via `hasPermissionProvider`.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/permission.dart';
import '../../widgets/permission_gated_widget.dart';
import 'customers_screen.dart';

/// Gated Customers screen — user must have `customers.view` to access.
class CustomersScreenGated extends ConsumerWidget {
  const CustomersScreenGated({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const PermissionGatedScreen(
      requiredPermission: AppPermissions.customersView,
      title: 'Customers',
      child: CustomersScreen(),
    );
  }
}
