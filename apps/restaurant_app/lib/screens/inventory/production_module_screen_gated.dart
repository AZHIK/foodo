/// Production module screen with permission enforcement.
///
/// Screen-level gate: user must have `production.view` to see the module at
/// all. Mutations (scheduling, starting, completing, publishing, recipe
/// edits) are action-gated inside via `hasPermissionProvider`.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/permission.dart';
import '../../widgets/permission_gated_widget.dart';
import 'production_module_screen.dart';

/// Gated production module — user must have `production.view` to access.
class ProductionModuleScreenGated extends ConsumerWidget {
  const ProductionModuleScreenGated({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const PermissionGatedScreen(
      requiredPermission: AppPermissions.productionView,
      title: 'Production',
      child: ProductionModuleScreen(),
    );
  }
}
