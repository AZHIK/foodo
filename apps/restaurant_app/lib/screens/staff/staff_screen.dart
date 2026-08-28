import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/business_role.dart';
import '../../models/permission.dart';
import '../../models/staff_member.dart';
import '../../providers/permissions_provider.dart';
import '../../providers/roles_provider.dart';
import '../../providers/staff_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../../widgets/data_page/data_column_spec.dart';
import '../../widgets/data_page/data_page_scaffold.dart';
import '../../widgets/data_page/data_table_toolbar.dart';
import '../../widgets/data_page/export_actions.dart';
import '../../widgets/data_page/reusable_data_table.dart';
import '../../widgets/data_page/status_badge.dart';
import '../../widgets/data_page/summary_metric_card.dart';
import '../../widgets/staff/role_badge.dart';
import 'invite_staff_dialog.dart';
import 'staff_filter_panel.dart';

/// The team list — the third page built entirely from the shared data-page
/// layer, and the proof that the shell generalises past Inventory and Sales.
///
/// Like those two, this file is column config, filters and actions. It writes
/// no layout of its own.
class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(staffQueryProvider);
    final slice = ref.watch(staffSliceProvider);
    final summary = ref.watch(staffSummaryProvider);
    final filters = ref.watch(staffFiltersProvider);
    final roles = ref.watch(rolesProvider).valueOrNull ?? const <BusinessRole>[];
    final notifier = ref.read(staffQueryProvider.notifier);
    final canInvite = ref.watch(hasPermissionProvider(AppPermissions.staffAssign));
    final canRevoke = ref.watch(hasPermissionProvider(AppPermissions.staffRevoke));

    // Resolved once and handed to the column config, so a table of twelve rows
    // does not walk the roles list twelve times per rebuild.
    final rolesById = {for (final role in roles) role.id: role};
    final columns = staffColumns(rolesById);

    return DataPageScaffold(
      title: 'Staff',
      subtitle:
          '${summary.total} people across ${roles.length} roles · '
          '${summary.active} active',
      actions: [
        ...dataPageExportActions<StaffMember>(
          context: context,
          columns: columns,
          rows: ref.watch(filteredStaffProvider),
          title: 'Staff',
          subtitle: _exportSubtitle(filters, query.search, rolesById),
        ),
        context.isMobile
            ? SizedBox(
                height: 40,
                width: 40,
                child: Tooltip(
                  message: 'Roles',
                  child: Material(
                    color: context.colors.surfaceContainerLowest,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: context.semantic.hairline),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                      onPressed: () => context.pushNamed(AppRoute.rolesName),
                      icon: const Icon(Icons.shield_outlined),
                    ),
                  ),
                ),
              )
            : OutlinedButton.icon(
                onPressed: () => context.pushNamed(AppRoute.rolesName),
                icon: const Icon(Icons.shield_outlined, size: 18),
                label: const Text('Roles'),
              ),
      ],
      // Hidden rather than shown-disabled: an owner who can't invite anyone
      // shouldn't see a control that only ever 403s.
      primaryAction: !canInvite
          ? null
          : context.isMobile
          ? SizedBox(
              height: 40,
              width: 40,
              child: Tooltip(
                message: 'Invite staff',
                child: Material(
                  color: context.colors.primary,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    onPressed: () => showInviteStaffDialog(context),
                    icon: const Icon(Icons.person_add_alt_rounded),
                    color: context.colors.onPrimary,
                  ),
                ),
              ),
            )
          : FilledButton.icon(
              onPressed: () => showInviteStaffDialog(context),
              icon: const Icon(Icons.person_add_alt_rounded, size: 18),
              label: const Text('Invite staff'),
            ),
      metrics: [
        SummaryMetricCard(
          label: 'Total staff',
          value: '${summary.total}',
          trend: '${roles.length} roles in use',
          icon: Icons.groups_outlined,
        ),
        SummaryMetricCard(
          label: 'Active',
          value: '${summary.active}',
          trend: summary.inactive == 0
              ? 'Everyone active'
              : '${summary.inactive} deactivated',
          trendDirection: summary.inactive == 0
              ? TrendDirection.flat
              : TrendDirection.down,
          icon: Icons.check_circle_outline_rounded,
          accent: context.semantic.success,
        ),
        SummaryMetricCard(
          label: 'Pending invites',
          value: '${summary.pending}',
          trend: summary.pending == 0
              ? 'Nothing outstanding'
              : 'Awaiting first sign-in',
          icon: Icons.mark_email_unread_outlined,
          accent: context.semantic.warning,
        ),
      ],
      toolbar: DataTableToolbar(
        searchHint: 'Search name, email or role',
        searchValue: query.search,
        onSearchChanged: notifier.setSearch,
        activeFilterCount: filters.activeCount,
        onClearFilters: ref.read(staffFiltersProvider.notifier).clear,
        filterBuilder: (_) => const StaffFilterPanel(),
        sortOptions: const [
          SortOption(label: 'Name', field: StaffSort.name),
          SortOption(label: 'Role', field: StaffSort.role),
          SortOption(label: 'Status', field: StaffSort.status),
          SortOption(label: 'Last active', field: StaffSort.lastActive),
        ],
        sortField: query.sortField,
        sortAscending: query.ascending,
        onSortChanged: (field, ascending) =>
            notifier.setSort(field, ascending: ascending),
      ),
      table: ReusableDataTable<StaffMember>(
        columns: columns,
        slice: slice,
        query: query,
        onSort: notifier.toggleSort,
        onPageChanged: notifier.setPage,
        onRowTap: (member) => context.pushNamed(
          AppRoute.staffDetailName,
          pathParameters: {'staffId': member.id},
        ),
        rowActions: _actions(ref, canRevoke: canRevoke),
      ),
    );
  }

  List<DataRowAction<StaffMember>> _actions(
    WidgetRef ref, {
    required bool canRevoke,
  }) => [
    DataRowAction(
      label: 'View detail',
      icon: Icons.open_in_new_rounded,
      onSelected: (context, member) => context.pushNamed(
        AppRoute.staffDetailName,
        pathParameters: {'staffId': member.id},
      ),
    ),
    if (canRevoke)
      DataRowAction(
        label: 'Remove from team',
        icon: Icons.person_off_outlined,
        isDestructive: true,
        // No backend endpoint reactivates a removed member — they'd need a
        // fresh invite — so this only applies to someone currently holding
        // at least one role here.
        isEnabled: (member) => member.roles.isNotEmpty,
        onSelected: (context, member) => _removeFromTeam(context, ref, member),
      ),
  ];

  Future<void> _removeFromTeam(
    BuildContext context,
    WidgetRef ref,
    StaffMember member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${member.name}?'),
        content: Text(
          member.roles.length > 1
              ? 'This revokes all ${member.roles.length} of their roles at this business.'
              : 'This revokes their role at this business.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: dialogContext.semantic.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final notifier = ref.read(staffMembersProvider.notifier);
    var failures = 0;
    for (final role in member.roles) {
      try {
        await notifier.revokeRole(userId: member.id, roleId: role.roleId);
      } catch (_) {
        failures++;
      }
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failures == 0
              ? '${member.name} removed from the team'
              : "Couldn't remove all of ${member.name}'s roles — try again",
        ),
      ),
    );
  }

  /// Records on the exported file which view produced it.
  static String _exportSubtitle(
    StaffFilters filters,
    String search,
    Map<String, BusinessRole> rolesById,
  ) {
    final parts = <String>[
      if (filters.roleIds.isNotEmpty)
        filters.roleIds.map((id) => rolesById[id]?.name ?? id).join(', '),
      if (filters.statuses.isNotEmpty)
        filters.statuses.map((s) => s.label).join(', '),
      if (search.trim().isNotEmpty) 'matching "${search.trim()}"',
    ];

    return parts.isEmpty ? 'All staff' : 'Filtered by ${parts.join(' · ')}';
  }
}

/// Column config for the staff table.
///
/// A function rather than a top-level list because the role badge needs the
/// roles map — the exporters call it with the same map, so a spreadsheet
/// carries the same columns the screen shows.
List<DataColumnSpec<StaffMember>> staffColumns(
  Map<String, BusinessRole> rolesById,
) => [
  DataColumnSpec(
    label: 'Name',
    field: StaffSort.name,
    role: ColumnRole.primary,
    flex: 5,
    value: (member) => member.name,
    cellBuilder: (context, member) =>
        _NameCell(member: member, role: rolesById[member.roleId]),
  ),
  DataColumnSpec(
    label: 'Role',
    field: StaffSort.role,
    flex: 3,
    // A staff member can hold more than one role — join every name for
    // sorting/search/export, and render every badge in the cell.
    value: (member) => member.roles.map((r) => r.roleName).join(', '),
    cellBuilder: (context, member) => Align(
      alignment: Alignment.centerLeft,
      child: member.roles.isEmpty
          ? const RoleBadge(role: null, dense: true)
          : Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final assignment in member.roles)
                  RoleBadge(role: rolesById[assignment.roleId], dense: true),
              ],
            ),
    ),
  ),
  DataColumnSpec(
    label: 'Email',
    field: StaffSort.email,
    flex: 4,
    minTableWidth: 940,
    value: (member) => member.email,
  ),
  DataColumnSpec(
    label: 'Last active',
    field: StaffSort.lastActive,
    flex: 3,
    minTableWidth: 720,
    value: (member) => member.lastActiveAt == null
        ? 'Never'
        : Fmt.relativeDateTime(member.lastActiveAt!),
  ),
  DataColumnSpec(
    label: 'Status',
    field: StaffSort.status,
    role: ColumnRole.status,
    width: 150,
    value: (member) => member.status.label,
    cellBuilder: (context, member) => StatusBadge(
      label: member.status.label,
      tone: member.status.tone,
      icon: member.status.badgeIcon,
      dense: true,
    ),
  ),
];

class _NameCell extends StatelessWidget {
  const _NameCell({required this.member, required this.role});

  final StaffMember member;
  final BusinessRole? role;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StaffAvatar(initials: member.initials, role: role),
        const SizedBox(width: Insets.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                member.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                member.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
