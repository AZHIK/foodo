import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink_business/core/constants/app_dimensions.dart';
import 'package:foodlink_business/features/inventory/presentation/screens/inventory_list_screen.dart';
import 'package:foodlink_business/shared/fakes/fake_data_service.dart';
import 'package:foodlink_business/shared/widgets/buttons/app_fab.dart';
import 'package:foodlink_business/shared/widgets/cards/app_card.dart';
import 'package:foodlink_business/shared/widgets/data_table/app_data_table.dart';

Widget _buildTestApp({
  required Size size,
  List<FakeInventoryItem>? customItems,
}) {
  return ProviderScope(
    overrides: [
      if (customItems != null)
        fakeInventoryProvider.overrideWith((ref) {
          final notifier = FakeInventoryNotifier(FakeDataService());
          notifier.loadItems(customItems);
          return notifier;
        }),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: const InventoryListScreen(),
        ),
      ),
    ),
  );
}

void main() {
  final sampleItems = [
    FakeInventoryItem(
      id: 'inv_1',
      name: 'Ugali Extra',
      category: 'Staples',
      sku: 'STA-001',
      priceSenti: 200000,
      stockLevel: 4,
      reorderThreshold: 10,
      costPriceSenti: 100000,
      unit: 'pcs',
      barcode: '12345',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    FakeInventoryItem(
      id: 'inv_2',
      name: 'Soda Fanta',
      category: 'Drinks',
      sku: 'DRI-002',
      priceSenti: 150000,
      stockLevel: 0,
      reorderThreshold: 5,
      costPriceSenti: 70000,
      unit: 'pcs',
      barcode: '67890',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    FakeInventoryItem(
      id: 'inv_3',
      name: 'Chapati Mix',
      category: 'Staples',
      sku: 'STA-003',
      priceSenti: 80000,
      stockLevel: 50,
      reorderThreshold: 10,
      costPriceSenti: 40000,
      unit: 'pcs',
      barcode: '11111',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_buildTestApp(size: size, customItems: sampleItems));
    await tester.pumpAndSettle();
  }

  group('InventoryListScreen', () {
    testWidgets('renders fake items and export button on desktop width',
        (tester) async {
      await pumpAt(
        tester,
        const Size(AppDimensions.breakpointDesktop, 900),
      );

      expect(find.text('Inventory Management'), findsOneWidget);
      expect(find.text('Ugali Extra'), findsOneWidget);
      expect(find.text('Soda Fanta'), findsOneWidget);
      expect(find.text('Export'), findsOneWidget);
      expect(find.byType(AppDataTable<FakeInventoryItem>), findsOneWidget);
      expect(find.text('Add Item'), findsOneWidget);
    });

    testWidgets('shows low stock and out of stock badges correctly',
        (tester) async {
      await pumpAt(
        tester,
        const Size(AppDimensions.breakpointDesktop, 900),
      );

      expect(find.text('Out of Stock'), findsOneWidget);
      expect(find.text('4 pcs (Low)'), findsOneWidget);
      expect(find.text('50 pcs'), findsOneWidget);
    });

    testWidgets('search filters the list of items', (tester) async {
      await pumpAt(
        tester,
        const Size(AppDimensions.breakpointDesktop, 900),
      );

      await tester.enterText(find.byType(TextField).first, 'Soda');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Soda Fanta'), findsOneWidget);
      expect(find.text('Ugali Extra'), findsNothing);
    });

    testWidgets('sorting by selling price reorders the rows', (tester) async {
      await pumpAt(
        tester,
        const Size(AppDimensions.breakpointDesktop, 900),
      );

      // Tap the "Selling Price" column header once → ascending sort.
      await tester.tap(find.text('Selling Price'));
      await tester.pumpAndSettle();

      final chapatiY = tester.getTopLeft(find.text('Chapati Mix')).dy;
      final sodaY = tester.getTopLeft(find.text('Soda Fanta')).dy;
      final ugaliY = tester.getTopLeft(find.text('Ugali Extra')).dy;

      expect(chapatiY, lessThan(sodaY));
      expect(sodaY, lessThan(ugaliY));
    });

    testWidgets('falls back to card list pattern on phone width',
        (tester) async {
      await pumpAt(tester, const Size(390, 800));

      final cards = find.descendant(
        of: find.byType(AppDataTable<FakeInventoryItem>),
        matching: find.byType(AppCard),
      );
      expect(cards.evaluate().length, greaterThanOrEqualTo(sampleItems.length));
      // On phones the Add Item action lives in a compact FAB (icon only).
      expect(find.byType(AppFab), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}
