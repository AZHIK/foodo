/// Customer detail screen with permission enforcement.
///
/// Gated separately from the list screen — `/customers/:customerId` is
/// independently deep-linkable, so a denied user who guesses or bookmarks
/// an id must not still be able to read a full profile plus order history.
library;

import 'package:flutter/widgets.dart';
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
      title: 'Customer',
      feature: 'Customers',
      child: CustomerDetailScreen(customerId: customerId),
    );
  }
}
