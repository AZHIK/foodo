/// Reports screen with permission enforcement.
///
/// Screen-level gate: user must have `reports.view` to read any section.
/// Export buttons gate themselves on `reports.export` inside the screen.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/permission.dart';
import '../../widgets/permission_gated_widget.dart';
import 'reports_screen.dart';

/// Gated Reports screen — user must have `reports.view` to access.
class ReportsScreenGated extends ConsumerWidget {
  const ReportsScreenGated({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const PermissionGatedScreen(
      requiredPermission: AppPermissions.reportsView,
      title: 'Reports',
      child: ReportsScreen(),
    );
  }
}
