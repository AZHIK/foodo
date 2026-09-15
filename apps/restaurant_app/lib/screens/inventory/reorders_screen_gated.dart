/// Reorders screen with permission enforcement.
///
/// Screen-level gate: user must have `reorders.view` to see the list at
/// all. Action-level gating (create/receive/cancel) happens inside
/// `ReordersScreen` itself via `hasPermissionProvider`.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/permission.dart';
import '../../widgets/permission_gated_widget.dart';
import 'reorders_screen.dart';

/// Gated Reorders screen — user must have `reorders.view` to access.
class ReordersScreenGated extends ConsumerWidget {
  const ReordersScreenGated({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const PermissionGatedScreen(
      requiredPermission: AppPermissions.reordersView,
      title: 'Reorders',
      child: ReordersScreen(),
    );
  }
}
