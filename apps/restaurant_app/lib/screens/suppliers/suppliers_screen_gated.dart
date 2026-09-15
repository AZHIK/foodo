/// Suppliers screen with permission enforcement.
///
/// Screen-level gate: user must have `suppliers.view` to see the list at
/// all. Action-level gating (add/edit/delete) happens inside
/// `SuppliersScreen` itself via `hasPermissionProvider`.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/permission.dart';
import '../../widgets/permission_gated_widget.dart';
import 'suppliers_screen.dart';

/// Gated Suppliers screen — user must have `suppliers.view` to access.
class SuppliersScreenGated extends ConsumerWidget {
  const SuppliersScreenGated({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const PermissionGatedScreen(
      requiredPermission: AppPermissions.suppliersView,
      title: 'Suppliers',
      child: SuppliersScreen(),
    );
  }
}
