/// Purchase order detail screen with permission enforcement.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/permission.dart';
import '../../widgets/permission_gated_widget.dart';
import 'purchase_detail_screen.dart';

/// Gated detail screen — user must have `procurement.view` to access.
class PurchaseDetailScreenGated extends ConsumerWidget {
  const PurchaseDetailScreenGated({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PermissionGatedScreen(
      requiredPermission: AppPermissions.procurementView,
      title: 'Order',
      child: PurchaseDetailScreen(orderId: orderId),
    );
  }
}
