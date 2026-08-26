import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/store_location.dart';
import '../../providers/store_locations_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/data_page/data_column_spec.dart';
import '../../widgets/data_page/data_page_scaffold.dart';
import '../../widgets/data_page/reusable_data_table.dart';
import '../../widgets/data_page/status_badge.dart';
import '../../widgets/data_page/summary_metric_card.dart';
import 'location_form_dialog.dart';

/// Every site the business trades from.
///
/// Uses [DataPageScaffold] like Inventory, Sales and Staff even though a
/// business has four locations rather than four hundred: the value of the
/// shared shell is that a list page looks like a list page, and a bespoke
/// layout for a short list is a second thing to maintain for no gain.
///
/// This screen edits the same provider the stock transfer dialog reads, so a
/// site added here is a transfer destination on the next frame.
class StoreManagementScreen extends ConsumerWidget {
  const StoreManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(locationsQueryProvider);
    final slice = ref.watch(locationsSliceProvider);
    final summary = ref.watch(locationsSummaryProvider);
    final managers = ref.watch(locationManagerNamesProvider);
    final notifier = ref.read(locationsQueryProvider.notifier);

    return DataPageScaffold(
      title: 'Store locations',
      subtitle: 'Sites this business trades from and moves stock between',
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.goNamed(AppRoute.settingsName),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Back to settings'),
        ),
      ],
      primaryAction: FilledButton.icon(
        onPressed: () => showLocationFormDialog(context),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Add location'),
      ),
      metrics: [
        SummaryMetricCard(
          label: 'Total locations',
          value: '${summary.total}',
          trend: summary.total == 1 ? 'Single site' : 'Across the business',
          icon: Icons.storefront_outlined,
        ),
        SummaryMetricCard(
          label: 'Active locations',
          value: '${summary.active}',
          trend: summary.active == summary.total
              ? 'All trading'
              : '${summary.total - summary.active} inactive',
          icon: Icons.check_circle_outline_rounded,
          accent: context.semantic.success,
        ),
        SummaryMetricCard(
          label: 'Total staff',
          value: '${summary.staff}',
          trend: 'Based across all sites',
          icon: Icons.groups_outlined,
          accent: context.colors.tertiary,
        ),
      ],
      // No search or filters: filtering four rows is a control that costs more
      // than it returns, the same call the Roles page makes.
      toolbar: const _LocationsCaption(),
      table: ReusableDataTable<StoreLocation>(
        columns: locationColumns(managers),
        slice: slice,
        query: query,
        onSort: notifier.toggleSort,
        onPageChanged: notifier.setPage,
        // Straight into the edit form rather than a detail screen — six fields
        // is a dialog, not a page.
        onRowTap: (location) =>
            showLocationFormDialog(context, existing: location),
        rowActions: _actions(ref),
      ),
    );
  }

  List<DataRowAction<StoreLocation>> _actions(WidgetRef ref) => [
    DataRowAction(
      label: 'Edit location',
      icon: Icons.edit_outlined,
      onSelected: (context, location) =>
          showLocationFormDialog(context, existing: location),
    ),
    DataRowAction(
      label: 'Activate / deactivate',
      icon: Icons.toggle_on_outlined,
      // The current store and the last active site both stay switched on: a
      // business with nowhere to trade is not a reachable state.
      isEnabled: (location) =>
          !location.isCurrent &&
          (!location.isActive ||
              ref.read(storeLocationsProvider.notifier).canDeactivate(
                location.id,
              )),
      onSelected: (context, location) {
        final wasActive = location.isActive;
        final done = ref
            .read(storeLocationsProvider.notifier)
            .toggleActive(location.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              done
                  ? '${location.name} ${wasActive ? 'deactivated' : 'reactivated'}'
                  : 'At least one location has to stay active',
            ),
          ),
        );
      },
    ),
    DataRowAction(
      label: 'Delete',
      icon: Icons.delete_outline_rounded,
      isDestructive: true,
      isEnabled: (location) =>
          ref.read(storeLocationsProvider.notifier).canDelete(location.id),
      onSelected: (context, location) => _confirmDelete(context, ref, location),
    ),
  ];

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    StoreLocation location,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete "${location.name}"?'),
        content: Text(
          location.staffCount == 0
              ? 'Stock movements recorded against this site keep their '
                    'history, but it will no longer be offered as a transfer '
                    'destination.'
              : '${location.staffCount} people are based here. They will keep '
                    'their records, but the site will no longer be offered as '
                    'a transfer destination.',
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

    final done = ref.read(storeLocationsProvider.notifier).delete(location.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          done
              ? '"${location.name}" deleted'
              : 'The last active location cannot be deleted',
        ),
      ),
    );
  }
}

/// Stands in for the toolbar on a page that does not need one, and carries the
/// rule the row actions enforce so it is stated before someone hits it.
class _LocationsCaption extends ConsumerWidget {
  const _LocationsCaption();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentStoreProvider);

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
            current == null
                ? 'The last active location cannot be deactivated or deleted.'
                : 'This terminal is installed at ${current.name}. The last '
                      'active location cannot be deactivated or deleted.',
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

List<DataColumnSpec<StoreLocation>> locationColumns(
  Map<String, String> managers,
) => [
  DataColumnSpec(
    label: 'Location',
    field: LocationSort.name,
    role: ColumnRole.primary,
    flex: 4,
    value: (location) => location.name,
    cellBuilder: (context, location) => _NameCell(location: location),
  ),
  DataColumnSpec(
    label: 'Address',
    field: 'locationAddress',
    sortable: false,
    flex: 5,
    minTableWidth: 760,
    value: (location) => location.address,
  ),
  DataColumnSpec(
    label: 'Manager',
    field: LocationSort.manager,
    flex: 3,
    minTableWidth: 560,
    value: (location) =>
        managers[location.id] ?? StoreLocation.unassignedManager,
  ),
  DataColumnSpec(
    label: 'Staff',
    field: LocationSort.staff,
    flex: 2,
    numeric: true,
    value: (location) => '${location.staffCount}',
  ),
  DataColumnSpec(
    label: 'Status',
    field: LocationSort.status,
    role: ColumnRole.status,
    width: 116,
    value: (location) => location.isActive ? 'Active' : 'Inactive',
    cellBuilder: (context, location) => StatusBadge(
      label: location.isActive ? 'Active' : 'Inactive',
      tone: location.isActive ? StatusTone.positive : StatusTone.neutral,
      dense: true,
    ),
  ),
];

/// The site's name, with the terminal's own site called out — the one fact
/// about this table that changes what the other screens do.
class _NameCell extends StatelessWidget {
  const _NameCell({required this.location});

  final StoreLocation location;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          location.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          location.isCurrent
              ? 'This store'
              : location.phone.isEmpty
              ? '—'
              : location.phone,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodySmall?.copyWith(
            color: location.isCurrent
                ? context.colors.primary
                : context.colors.onSurfaceVariant,
            fontWeight: location.isCurrent ? FontWeight.w600 : null,
          ),
        ),
      ],
    );
  }
}
