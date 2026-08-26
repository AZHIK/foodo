import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/business_role.dart';
import '../../models/staff_member.dart';
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
    final roles = ref.watch(rolesProvider);
    final notifier = ref.read(staffQueryProvider.notifier);

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
      primaryAction: context.isMobile
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
        rowActions: _actions(ref),
      ),
    );
  }

  List<DataRowAction<StaffMember>> _actions(WidgetRef ref) => [
    DataRowAction(
      label: 'View detail',
      icon: Icons.open_in_new_rounded,
      onSelected: (context, member) => context.pushNamed(
        AppRoute.staffDetailName,
        pathParameters: {'staffId': member.id},
      ),
    ),
    DataRowAction(
      label: 'Change role',
      icon: Icons.badge_outlined,
      onSelected: (context, member) => showChangeRoleDialog(context, member),
    ),
    DataRowAction(
      label: 'Resend invite',
      icon: Icons.forward_to_inbox_outlined,
      // Only means anything for someone who has not accepted yet.
      isEnabled: (member) => member.isPending,
      onSelected: (context, member) => ScaffoldMessenger.of(context)
          .showSnackBar(
            SnackBar(content: Text('Invite resent to ${member.email}')),
          ),
    ),
    DataRowAction(
      label: 'Deactivate',
      icon: Icons.person_off_outlined,
      isDestructive: true,
      isEnabled: (member) => !member.isPending,
      onSelected: (context, member) => _toggleActive(context, ref, member),
    ),
  ];

  void _toggleActive(
    BuildContext context,
    WidgetRef ref,
    StaffMember member,
  ) {
    ref.read(staffMembersProvider.notifier).toggleActive(member.id);

    final nowActive = member.status != StaffStatus.active;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nowActive
              ? '${member.name} reactivated'
              : '${member.name} deactivated',
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
    value: (member) => rolesById[member.roleId]?.name ?? '—',
    cellBuilder: (context, member) => Align(
      alignment: Alignment.centerLeft,
      child: RoleBadge(role: rolesById[member.roleId], dense: true),
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
