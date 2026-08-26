import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/models/table_query.dart';
import 'package:restaurant_pos/providers/table_query_provider.dart';
import 'package:restaurant_pos/theme/app_theme.dart';
import 'package:restaurant_pos/widgets/data_page/data_column_spec.dart';
import 'package:restaurant_pos/widgets/data_page/data_page_scaffold.dart';
import 'package:restaurant_pos/widgets/data_page/data_row_card.dart';
import 'package:restaurant_pos/widgets/data_page/data_table_toolbar.dart';
import 'package:restaurant_pos/widgets/data_page/reusable_data_table.dart';
import 'package:restaurant_pos/widgets/data_page/status_badge.dart';
import 'package:restaurant_pos/widgets/data_page/summary_metric_card.dart';

// ---------------------------------------------------------------------------
// A placeholder domain the shared layer knows nothing about. If this composes
// cleanly, so will Inventory, Sales, and any page added later.
// ---------------------------------------------------------------------------

class Gadget {
  const Gadget(this.name, this.group, this.count, this.ok);
  final String name;
  final String group;
  final int count;
  final bool ok;
}

final _rows = <Gadget>[
  for (var i = 0; i < 23; i++)
    Gadget('Thing ${(23 - i).toString().padLeft(2, '0')}', 'G${i % 3}', i * 3, i % 4 != 0),
];

final _queryProvider = NotifierProvider<TableQueryNotifier, TableQuery>(
  () => TableQueryNotifier(const TableQuery(sortField: 'name', pageSize: 5)),
);

/// The derived provider a real page would write: raw data in, searched and
/// sorted list out.
final _filteredProvider = Provider<List<Gadget>>((ref) {
  final query = ref.watch(_queryProvider);
  final search = query.search.trim().toLowerCase();

  final rows = _rows
      .where((r) => search.isEmpty || r.name.toLowerCase().contains(search))
      .toList();

  final direction = query.ascending ? 1 : -1;
  rows.sort((a, b) {
    final cmp = switch (query.sortField) {
      'count' => a.count.compareTo(b.count),
      _ => a.name.compareTo(b.name),
    };
    return cmp * direction;
  });
  return rows;
});

final _sliceProvider = Provider<PageSlice<Gadget>>(
  (ref) => PageSlice.of(ref.watch(_filteredProvider), ref.watch(_queryProvider)),
);

final _columns = <DataColumnSpec<Gadget>>[
  DataColumnSpec(
    label: 'Name',
    field: 'name',
    role: ColumnRole.primary,
    flex: 4,
    value: (r) => r.name,
  ),
  DataColumnSpec(
    label: 'Group',
    field: 'group',
    flex: 2,
    minTableWidth: 700,
    value: (r) => r.group,
  ),
  DataColumnSpec(
    label: 'Count',
    field: 'count',
    flex: 2,
    numeric: true,
    value: (r) => '${r.count}',
  ),
  DataColumnSpec(
    label: 'State',
    field: 'ok',
    role: ColumnRole.status,
    width: 120,
    sortable: false,
    value: (r) => r.ok ? 'Ready' : 'Blocked',
    cellBuilder: (context, r) => StatusBadge(
      label: r.ok ? 'Ready' : 'Blocked',
      tone: r.ok ? StatusTone.positive : StatusTone.danger,
      dense: true,
    ),
  ),
];

class _DemoPage extends ConsumerWidget {
  const _DemoPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(_queryProvider);
    final slice = ref.watch(_sliceProvider);
    final notifier = ref.read(_queryProvider.notifier);

    return DataPageScaffold(
      title: 'Placeholder',
      subtitle: 'Proving the shared layout composes',
      actions: [
        OutlinedButton(onPressed: () {}, child: const Text('Export PDF')),
      ],
      primaryAction: FilledButton(
        onPressed: () {},
        child: const Text('Add thing'),
      ),
      metrics: const [
        SummaryMetricCard(label: 'Total', value: '23', trend: 'all groups'),
        SummaryMetricCard(label: 'Ready', value: '17', trend: 'healthy'),
        SummaryMetricCard(label: 'Blocked', value: '6', trend: 'needs review'),
      ],
      toolbar: DataTableToolbar(
        searchHint: 'Search things',
        searchValue: query.search,
        onSearchChanged: notifier.setSearch,
        activeFilterCount: 1,
        onClearFilters: () {},
        filterBuilder: (context) => const Text('Filter fields go here'),
        sortOptions: const [
          SortOption(label: 'Name', field: 'name'),
          SortOption(label: 'Count', field: 'count'),
        ],
        sortField: query.sortField,
        sortAscending: query.ascending,
        onSortChanged: (field, asc) =>
            notifier.setSort(field, ascending: asc),
      ),
      table: ReusableDataTable<Gadget>(
        columns: _columns,
        slice: slice,
        query: query,
        onSort: notifier.toggleSort,
        onPageChanged: notifier.setPage,
        onRowTap: (_) {},
        rowActions: [
          DataRowAction(
            label: 'Edit',
            icon: Icons.edit_outlined,
            onSelected: (_, _) {},
          ),
          DataRowAction(
            label: 'Delete',
            icon: Icons.delete_outline_rounded,
            isDestructive: true,
            onSelected: (_, _) {},
          ),
        ],
      ),
    );
  }
}

Future<ProviderContainer> pumpDemo(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.reset);

  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.light(), home: const _DemoPage()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('PageSlice', () {
    test('slices and reports counts', () {
      final slice = PageSlice.of(_rows, const TableQuery(page: 1, pageSize: 5));
      expect(slice.items, hasLength(5));
      expect(slice.totalCount, 23);
      expect(slice.pageCount, 5);
      expect(slice.firstRow, 6);
      expect(slice.lastRow, 10);
      expect(slice.hasPrevious, isTrue);
      expect(slice.hasNext, isTrue);
    });

    test('clamps a page that no longer exists', () {
      // Filters just cut 23 rows down to 3 while the user was on page 4.
      final slice = PageSlice.of(
        _rows.take(3).toList(),
        const TableQuery(page: 4, pageSize: 5),
      );
      expect(slice.page, 0);
      expect(slice.items, hasLength(3));
    });

    test('an empty result still reports one page', () {
      final slice = PageSlice.of(<Gadget>[], const TableQuery(pageSize: 5));
      expect(slice.pageCount, 1);
      expect(slice.firstRow, 0);
      expect(slice.hasNext, isFalse);
    });
  });

  group('TableQuery', () {
    test('toggling the active column flips direction', () {
      const q = TableQuery(sortField: 'name', page: 3);
      final flipped = q.toggledSort('name');
      expect(flipped.ascending, isFalse);
      expect(flipped.page, 0, reason: 'sorting returns to page one');
    });

    test('a new column starts ascending', () {
      const q = TableQuery(sortField: 'name', ascending: false);
      expect(q.toggledSort('count').ascending, isTrue);
    });

    test('searching returns to page one', () {
      const q = TableQuery(page: 4);
      expect(q.withSearch('x').page, 0);
    });
  });

  group('Shared data page', () {
    testWidgets('no overflow at any target width', (tester) async {
      for (final width in [360.0, 400.0, 768.0, 1024.0, 1440.0, 1920.0]) {
        await pumpDemo(tester, Size(width, 900));
        expect(
          tester.takeException(),
          isNull,
          reason: 'render error at ${width}px',
        );
        expect(find.byType(SummaryMetricCard), findsNWidgets(3));
      }
    });

    testWidgets('table below 600px becomes cards', (tester) async {
      await pumpDemo(tester, const Size(390, 900));
      expect(find.byType(DataRowCard<Gadget>), findsWidgets);

      await pumpDemo(tester, const Size(1024, 900));
      expect(find.byType(DataRowCard<Gadget>), findsNothing);
    });

    testWidgets('columns drop out rather than scrolling sideways', (
      tester,
    ) async {
      await pumpDemo(tester, const Size(1440, 900));
      expect(find.text('GROUP'), findsOneWidget);

      await pumpDemo(tester, const Size(680, 900));
      expect(find.text('GROUP'), findsNothing);
      expect(find.text('NAME'), findsOneWidget);
    });

    testWidgets('tapping a header sorts and shows an arrow', (tester) async {
      final container = await pumpDemo(tester, const Size(1440, 900));
      expect(container.read(_queryProvider).sortField, 'name');

      await tester.tap(find.text('COUNT'));
      await tester.pumpAndSettle();

      final query = container.read(_queryProvider);
      expect(query.sortField, 'count');
      expect(query.ascending, isTrue);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsWidgets);

      await tester.tap(find.text('COUNT'));
      await tester.pumpAndSettle();
      expect(container.read(_queryProvider).ascending, isFalse);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsWidgets);
    });

    testWidgets('pagination walks pages and reports the range', (
      tester,
    ) async {
      final container = await pumpDemo(tester, const Size(1440, 900));
      expect(find.text('Showing 1–5 of 23'), findsOneWidget);

      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();
      expect(container.read(_queryProvider).page, 1);
      expect(find.text('Showing 6–10 of 23'), findsOneWidget);

      // Jump by page number.
      await tester.tap(find.widgetWithText(InkWell, '5').first);
      await tester.pumpAndSettle();
      expect(container.read(_queryProvider).page, 4);
      expect(find.text('Showing 21–23 of 23'), findsOneWidget);
      expect(find.byTooltip('Next page'), findsOneWidget);
    });

    testWidgets('search filters live and resets to page one', (tester) async {
      final container = await pumpDemo(tester, const Size(1440, 900));
      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Thing 01');
      await tester.pumpAndSettle();

      expect(container.read(_queryProvider).page, 0);
      expect(container.read(_filteredProvider), hasLength(1));
      expect(find.text('Showing 1–1 of 1'), findsOneWidget);
    });

    testWidgets('empty search shows the empty state', (tester) async {
      await pumpDemo(tester, const Size(1440, 900));
      await tester.enterText(find.byType(TextField).first, 'zzzz');
      await tester.pumpAndSettle();

      expect(find.text('No results'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('filters open as a popover on desktop', (tester) async {
      await pumpDemo(tester, const Size(1440, 900));
      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Filter fields go here'), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('filters open as a sheet on mobile', (tester) async {
      await pumpDemo(tester, const Size(390, 844));
      await tester.tap(find.byIcon(Icons.filter_list_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Filter fields go here'), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('row actions menu opens on both layouts', (tester) async {
      for (final size in [const Size(1440, 900), const Size(390, 844)]) {
        await pumpDemo(tester, size);
        await tester.tap(find.byTooltip('Row actions').first);
        await tester.pumpAndSettle();

        expect(find.text('Edit'), findsOneWidget, reason: '$size');
        expect(find.text('Delete'), findsOneWidget, reason: '$size');

        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();
      }
    });
  });
}
