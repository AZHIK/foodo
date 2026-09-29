/// Purchasing module: multi-line purchase orders ("New purchase").
///
/// Single-flow screen — the legacy single-item reorders tab was removed.
/// The destination gates itself on `procurement.view` (see
/// `responsive_scaffold.dart`).
///
/// Online-only in behavior: purchases fetch live with an offline
/// placeholder.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_strings.dart';
import '../../models/permission.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/permissions_provider.dart';
import '../purchases/purchase_order_dialog.dart';
import '../purchases/purchases_screen.dart';
import '../../widgets/permission_gated_widget.dart';

class PurchasingScreen extends ConsumerWidget {
  const PurchasingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final canCreate =
        ref.watch(hasPermissionProvider(AppPermissions.procurementCreate));

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.purchasingTitle),
        elevation: 0,
      ),
      floatingActionButton: canCreate && online
          ? FloatingActionButton.extended(
              onPressed: () => showPurchaseOrderDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(AppStrings.newOrderAction),
            )
          : null,
      body: const PermissionGatedScreen(
        requiredPermission: AppPermissions.procurementView,
        title: 'Purchasing',
        child: PurchasesTabView(),
      ),
    );
  }
}
