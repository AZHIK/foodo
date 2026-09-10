import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/permission.dart';
import '../../models/supplier.dart';
import '../../models/table_query.dart';
import '../../providers/permissions_provider.dart';
import '../../providers/suppliers_provider.dart';
import '../../providers/table_query_provider.dart';
import '../../widgets/data_page/data_column_spec.dart';
import '../../widgets/data_page/data_page_scaffold.dart';
import '../../widgets/data_page/data_table_toolbar.dart';
import '../../widgets/data_page/reusable_data_table.dart';
import '../../widgets/data_page/summary_metric_card.dart';
import '../../widgets/dialogs/supplier_form_dialog.dart';

/// Live search text for the suppliers table.
final supplierSearchProvider = StateProvider<String>((ref) => '');

/// Query state (page, sort) for the suppliers table.
final suppliersQueryProvider = NotifierProvider<TableQueryNotifier, TableQuery>(
  TableQueryNotifier.new,
);

final _filteredSuppliersProvider = Provider<List<Supplier>>((ref) {
  final suppliers = ref.watch(suppliersListProvider);
  final query = ref.watch(supplierSearchProvider).trim().toLowerCase();
  if (query.isEmpty) return suppliers;
  return suppliers.where((s) {
    return s.name.toLowerCase().contains(query) ||
        (s.phone?.toLowerCase().contains(query) ?? false) ||
        (s.email?.toLowerCase().contains(query) ?? false);
  }).toList();
});

final _suppliersSliceProvider = Provider<PageSlice<Supplier>>((ref) {
  final suppliers = ref.watch(_filteredSuppliersProvider);
  final query = ref.watch(suppliersQueryProvider);
  var sorted = [...suppliers]..sort((a, b) => a.name.compareTo(b.name));
  if (!query.ascending) sorted = sorted.reversed.toList();
  return PageSlice.of(sorted, query);
});

/// Supplier directory, built on the shared data-page layer.
class SuppliersScreen extends ConsumerWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(suppliersQueryProvider);
    final slice = ref.watch(_suppliersSliceProvider);
    final notifier = ref.read(suppliersQueryProvider.notifier);
    final canCreate = ref.watch(hasPermissionProvider(AppPermissions.suppliersCreate));
    final canUpdate = ref.watch(hasPermissionProvider(AppPermissions.suppliersUpdate));
    final canDelete = ref.watch(hasPermissionProvider(AppPermissions.suppliersDelete));

    return DataPageScaffold(
      title: 'Suppliers',
      subtitle: 'Vendors this business orders restock inventory from',
      actions: const [],
      // Hidden rather than shown-disabled: someone who can't add suppliers
      // shouldn't see a control that only ever 403s.
      primaryAction: !canCreate
          ? null
          : FilledButton.icon(
              onPressed: () => showSupplierFormDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add supplier'),
            ),
      metrics: [
        SummaryMetricCard(
          label: 'Total suppliers',
          value: '${ref.watch(suppliersListProvider).length}',
          trend: 'Active vendor records',
          icon: Icons.storefront_outlined,
        ),
      ],
      toolbar: DataTableToolbar(
        searchHint: 'Search by name, phone, or email',
        searchValue: ref.watch(supplierSearchProvider),
        onSearchChanged: (value) => ref.read(supplierSearchProvider.notifier).state = value,
        activeFilterCount: 0,
        onClearFilters: () {},
        filterBuilder: (_) => const SizedBox.shrink(),
        sortOptions: const [SortOption(label: 'Name', field: 'name')],
        sortField: query.sortField,
        sortAscending: query.ascending,
        onSortChanged: (field, ascending) => notifier.setSort(field, ascending: ascending),
      ),
      table: ReusableDataTable<Supplier>(
        columns: _columns,
        slice: slice,
        query: query,
        onSort: notifier.toggleSort,
        onPageChanged: notifier.setPage,
        rowActions: _actions(ref, canUpdate: canUpdate, canDelete: canDelete),
      ),
    );
  }

  List<DataRowAction<Supplier>> _actions(
    WidgetRef ref, {
    required bool canUpdate,
    required bool canDelete,
  }) => [
    if (canUpdate)
      DataRowAction(
        label: 'Edit',
        icon: Icons.edit_outlined,
        onSelected: (context, supplier) =>
            showSupplierFormDialog(context, existingSupplier: supplier),
      ),
    if (canDelete)
      DataRowAction(
        label: 'Delete',
        icon: Icons.delete_outline_rounded,
        isDestructive: true,
        onSelected: (context, supplier) => _confirmDelete(context, ref, supplier),
      ),
  ];

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Supplier supplier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${supplier.name}?'),
        content: const Text(
          'This supplier record will be removed. Past reorders keep their '
          'attribution. This cannot be undone.',
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

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(suppliersProvider.notifier).delete(supplier.id);
      messenger.showSnackBar(SnackBar(content: Text('${supplier.name} deleted')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not delete: $e')));
    }
  }
}

final _columns = <DataColumnSpec<Supplier>>[
  DataColumnSpec(
    label: 'Name',
    field: 'name',
    role: ColumnRole.primary,
    flex: 4,
    value: (supplier) => supplier.name,
  ),
  DataColumnSpec(
    label: 'Phone',
    field: 'phone',
    flex: 3,
    value: (supplier) => supplier.phone ?? '—',
  ),
  DataColumnSpec(
    label: 'Email',
    field: 'email',
    flex: 3,
    value: (supplier) => supplier.email ?? '—',
  ),
];
