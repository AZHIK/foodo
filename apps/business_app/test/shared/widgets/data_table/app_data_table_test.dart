import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink_business/core/constants/app_dimensions.dart';
import 'package:foodlink_business/shared/widgets/cards/app_card.dart';
import 'package:foodlink_business/shared/widgets/data_table/app_data_table.dart';

class _TestItem {
  const _TestItem({required this.id, required this.name, required this.qty, required this.price});
  final String id;
  final String name;
  final int qty;
  final double price;
}

void main() {
  group('AppDataTable', () {
    final columns = <AppDataColumn<_TestItem>>[
      AppDataColumn<_TestItem>(
        key: 'id',
        label: 'ID',
        valueExtractor: (r) => r.id,
        isPrimary: true,
      ),
      AppDataColumn<_TestItem>(
        key: 'name',
        label: 'Name',
        valueExtractor: (r) => r.name,
        isPrimary: true,
      ),
      AppDataColumn<_TestItem>(
        key: 'qty',
        label: 'Qty',
        valueExtractor: (r) => r.qty,
        sortable: true,
      ),
      AppDataColumn<_TestItem>(
        key: 'price',
        label: 'Price',
        valueExtractor: (r) => r.price,
        sortable: true,
      ),
    ];

    const allRows = <_TestItem>[
      _TestItem(id: '1', name: 'Apple',  qty: 10, price: 1.5),
      _TestItem(id: '2', name: 'Banana', qty: 5,  price: 0.5),
      _TestItem(id: '3', name: 'Cherry', qty: 20, price: 3.0),
      _TestItem(id: '4', name: 'Date',   qty: 0,  price: 4.0),
      _TestItem(id: '5', name: 'Elder',  qty: 15, price: 2.25),
    ];

    Widget buildTable({
      required List<_TestItem> rows,
      Size size = const Size(1200, 800),
      int initialPageSize = 10,
      bool showSearch = true,
      bool showPagination = true,
    }) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Scaffold(
            body: SizedBox(
              width: size.width,
              height: size.height,
              child: AppDataTable<_TestItem>(
                rows: rows,
                columns: columns,
                initialPageSize: initialPageSize,
                showSearch: showSearch,
                showPagination: showPagination,
                emptyStateIcon: Icons.inbox_outlined,
                emptyStateTitle: 'No items',
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders rows correctly at desktop width', (tester) async {
      await tester.pumpWidget(buildTable(rows: allRows));
      await tester.pumpAndSettle();
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Elder'), findsOneWidget);
    });

    testWidgets('shows empty state when rows is empty', (tester) async {
      await tester.pumpWidget(buildTable(rows: const []));
      await tester.pumpAndSettle();
      expect(find.text('No items'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('search filters correctly (debounced)', (tester) async {
      await tester.pumpWidget(buildTable(rows: allRows));
      await tester.pumpAndSettle();
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Cherry');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(DataTable),
          matching: find.text('Cherry'),
        ),
        findsOneWidget,
      );
      expect(find.text('Apple'), findsNothing);
    });

    testWidgets('pagination limits rows per page correctly', (tester) async {
      final manyRows = List<_TestItem>.generate(
        30,
        (i) => _TestItem(id: '${i + 1}', name: 'Item ${i + 1}', qty: i, price: i * 1.5),
      );
      await tester.pumpWidget(
        buildTable(rows: manyRows, initialPageSize: 10),
      );
      await tester.pumpAndSettle();
      expect(find.text('1–10 of 30'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 10'), findsOneWidget);
      expect(find.text('Item 11'), findsNothing);
    });

    testWidgets('adaptive fallback triggers below tablet breakpoint', (tester) async {
      const narrow = Size(AppDimensions.breakpointTablet - 10, 800);
      tester.view.physicalSize = narrow;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildTable(rows: allRows, size: narrow));
      await tester.pumpAndSettle();
      final cards = find.descendant(
        of: find.byType(AppDataTable<_TestItem>),
        matching: find.byType(AppCard),
      );
      expect(cards.evaluate().length, greaterThanOrEqualTo(allRows.length));
    });

    testWidgets('desktop width renders trina_grid not card list', (tester) async {
      const wide = Size(AppDimensions.breakpointDesktop, 800);
      tester.view.physicalSize = wide;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildTable(rows: allRows, size: wide));
      await tester.pumpAndSettle();
      expect(find.text('ID'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Qty'), findsOneWidget);
      expect(find.text('Price'), findsOneWidget);
    });

    testWidgets('pagination controls advance to next page', (tester) async {
      final manyRows = List<_TestItem>.generate(
        15,
        (i) => _TestItem(id: '${i + 1}', name: 'Item ${i + 1}', qty: i, price: i * 1.5),
      );
      await tester.pumpWidget(
        buildTable(rows: manyRows, initialPageSize: 5),
      );
      await tester.pumpAndSettle();
      expect(find.text('1–5 of 15'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.text('6–10 of 15'), findsOneWidget);
      expect(find.text('Item 6'), findsOneWidget);
      expect(find.text('Item 1'), findsNothing);
    });
  });
}
