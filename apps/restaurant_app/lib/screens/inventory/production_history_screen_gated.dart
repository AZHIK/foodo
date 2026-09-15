/// Production history screen with permission enforcement.
///
/// Screen-level gate: user must have `production.view` to see the ledger at
/// all. Recording is action-gated inside the menu-item detail screen via
/// `hasPermissionProvider`.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/permission.dart';
import '../../widgets/permission_gated_widget.dart';
import 'production_history_screen.dart';

/// Gated production history — user must have `production.view` to access.
class ProductionHistoryScreenGated extends ConsumerWidget {
  const ProductionHistoryScreenGated({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const PermissionGatedScreen(
      requiredPermission: AppPermissions.productionView,
      title: 'Production',
      child: ProductionHistoryScreen(),
    );
  }
}
