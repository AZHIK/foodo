import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/business_role.dart';
import '../../models/permission.dart';
import '../../providers/roles_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/data_page/data_column_spec.dart';
import '../../widgets/data_page/data_page_scaffold.dart';
import '../../widgets/data_page/reusable_data_table.dart';
import '../../widgets/data_page/status_badge.dart';
import '../../widgets/data_page/summary_metric_card.dart';
import 'role_form_dialog.dart';

/// Roles and what each one can do.
///
/// Uses [DataPageScaffold] like every other list page, but deliberately omits
/// two things the others carry: exports, because a permission matrix is not
/// something anyone takes to a spreadsheet, and the search/filter toolbar,
/// because a business has a handful of roles and filtering five rows is a
/// control that costs more than it returns.
class RolesScreen extends ConsumerWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(rolesQueryProvider);
    final slice = ref.watch(rolesSliceProvider);
    final summary = ref.watch(rolesSummaryProvider);
    final counts = ref.watch(roleStaffCountsProvider);
    final notifier = ref.read(rolesQueryProvider.notifier);

    return DataPageScaffold(
      title: 'Roles & permissions',
      subtitle:
          '${summary.totalRoles} roles · '
          '${summary.staffAssigned} staff assigned',
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.goNamed(AppRoute.staffName),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Back to staff'),
        ),
      ],
      primaryAction: FilledButton.icon(
        onPressed: () => showRoleFormDialog(context),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Create role'),
      ),
      metrics: [
        SummaryMetricCard(
          label: 'Total roles',
          value: '${summary.totalRoles}',
          trend: '${summary.totalRoles - summary.customRoles} built in',
          icon: Icons.shield_outlined,
        ),
        SummaryMetricCard(
          label: 'Custom roles',
          value: '${summary.customRoles}',
          trend: summary.customRoles == 0
              ? 'None created yet'
              : 'Created for this business',
          icon: Icons.tune_rounded,
          accent: context.colors.tertiary,
        ),
        SummaryMetricCard(
          label: 'Staff assigned',
          value: '${summary.staffAssigned}',
          trend: 'Across all roles',
          icon: Icons.groups_outlined,
          accent: context.semantic.success,
        ),
      ],
      // The scaffold requires a toolbar slot; this page has no use for search
      // or filters, so it spends the space on the one thing that does help —
      // saying what the table below is counting.
      toolbar: const _RolesCaption(),
      table: ReusableDataTable<BusinessRole>(
        columns: roleColumns(counts),
        slice: slice,
        query: query,
        onSort: notifier.toggleSort,
        onPageChanged: notifier.setPage,
        onRowTap: (role) => showRoleFormDialog(context, existingRole: role),
        rowActions: _actions(ref),
      ),
    );
  }

  List<DataRowAction<BusinessRole>> _actions(WidgetRef ref) => [
    DataRowAction(
      label: 'Edit role',
      icon: Icons.edit_outlined,
      onSelected: (context, role) =>
          showRoleFormDialog(context, existingRole: role),
    ),
    DataRowAction(
      label: 'Duplicate',
      icon: Icons.copy_all_outlined,
      onSelected: (context, role) {
        final copy = ref.read(rolesProvider.notifier).duplicate(role.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created "${copy.name}"')),
        );
      },
    ),
    DataRowAction(
      label: 'Delete',
      icon: Icons.delete_outline_rounded,
      isDestructive: true,
      // System roles are referenced by staff records and by reporting, so
      // removing one would orphan both. The row explains why in a tooltip.
      isEnabled: (role) => !role.isSystem,
      onSelected: (context, role) => _confirmDelete(context, ref, role),
    ),
  ];

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BusinessRole role,
  ) async {
    final assigned = ref.read(roleStaffCountsProvider)[role.id] ?? 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete "${role.name}"?'),
        content: Text(
          assigned == 0
              ? 'This role is not assigned to anyone. It will be removed '
                    'permanently.'
              : '$assigned ${assigned == 1 ? 'person is' : 'people are'} '
                    'assigned to this role. They will keep the role on their '
                    'record but it will no longer grant any permissions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    ref.read(rolesProvider.notifier).delete(role.id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('"${role.name}" deleted')));
  }
}

/// Stands in for the toolbar on a page that does not need one.
class _RolesCaption extends StatelessWidget {
  const _RolesCaption();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: context.colors.onSurfaceVariant,
        ),
        const SizedBox(width: Insets.sm),
        Expanded(
          child: Text(
            'Built-in roles can be edited but not renamed or deleted.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

List<DataColumnSpec<BusinessRole>> roleColumns(Map<String, int> counts) => [
  DataColumnSpec(
    label: 'Role',
    field: RoleSort.name,
    role: ColumnRole.primary,
    flex: 5,
    value: (role) => role.name,
    cellBuilder: (context, role) => _RoleCell(role: role),
  ),
  DataColumnSpec(
    label: 'Staff',
    field: RoleSort.staffCount,
    flex: 2,
    numeric: true,
    value: (role) => '${counts[role.id] ?? 0}',
  ),
  DataColumnSpec(
    label: 'Permissions',
    field: RoleSort.permissions,
    flex: 3,
    minTableWidth: 620,
    value: (role) => role.permissionSummary,
    cellBuilder: (context, role) => _PermissionsCell(role: role),
  ),
  DataColumnSpec(
    label: 'Type',
    field: 'roleType',
    role: ColumnRole.status,
    sortable: false,
    width: 120,
    value: (role) => role.isSystem ? 'Built in' : 'Custom',
    // Says the same thing the column's value says — a badge showing the role's
    // name here would put a different word on screen from the one an export
    // carries for the same cell.
    cellBuilder: (context, role) => Tooltip(
      message: role.isSystem
          ? 'Built-in roles cannot be renamed or deleted'
          : 'Created for this business',
      child: StatusBadge(
        label: role.isSystem ? 'Built in' : 'Custom',
        tone: role.isSystem ? StatusTone.neutral : StatusTone.info,
        icon: role.isSystem
            ? Icons.lock_outline_rounded
            : Icons.auto_awesome_outlined,
        dense: true,
      ),
    ),
  ),
];

class _RoleCell extends StatelessWidget {
  const _RoleCell({required this.role});

  final BusinessRole role;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          role.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          role.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// The permission count with a bar behind it, so relative reach across roles is
/// legible without reading four numbers.
class _PermissionsCell extends StatelessWidget {
  const _PermissionsCell({required this.role});

  final BusinessRole role;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final total = role.permissionCount;
    final fraction = total == 0 ? 0.0 : total / AppPermissions.count;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          role.permissionSummary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Insets.xs + 1),
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.pill),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 4,
            backgroundColor: colors.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(
              fraction == 1 ? context.semantic.success : colors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
