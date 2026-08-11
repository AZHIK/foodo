import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink_business/features/inventory/presentation/screens/item_detail_screen.dart';
import 'package:foodlink_business/shared/fakes/fake_data_service.dart';
import 'package:foodlink_business/shared/widgets/data_table/app_data_table.dart';

final _sampleItem = FakeInventoryItem(
  id: 'inv_test_1',
  name: 'Wali Maharage',
  category: 'Mains',
  sku: 'MAI-001',
  priceSenti: 150000,
  costPriceSenti: 90000,
  stockLevel: 15,
  reorderThreshold: 5,
  reorderQuantity: 20,
  unit: 'pcs',
  barcode: '12345',
  itemType: 'prepared_item',
  createdAt: DateTime(2026, 1, 5, 10, 30),
  updatedAt: DateTime(2026, 1, 5, 10, 30),
);

Future<void> _pumpAt(
  WidgetTester tester,
  Size size,
  List<FakeInventoryItem> items,
  String itemId,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        fakeInventoryProvider.overrideWith((ref) {
          final notifier = FakeInventoryNotifier(FakeDataService());
          notifier.loadItems(items);
          return notifier;
        }),
      ],
      child: MaterialApp(
        home: SizedBox(
          width: size.width,
          height: size.height,
          child: ItemDetailScreen(itemId: itemId),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ItemDetailScreen', () {
    testWidgets('shows item details and its movement history table',
        (tester) async {
      await _pumpAt(
        tester,
        const Size(1000, 900),
        [_sampleItem],
        _sampleItem.id,
      );

      expect(find.text('Wali Maharage'), findsWidgets);
      expect(find.text('SKU: MAI-001 • Category: Mains'), findsOneWidget);
      expect(find.text('15 pcs'), findsOneWidget);

      expect(find.text('Adjust Stock'), findsOneWidget);
      expect(find.text('Record Waste'), findsOneWidget);
      expect(find.text('Transfer Stock'), findsOneWidget);

      expect(find.byType(AppDataTable<FakeMovement>), findsOneWidget);
      expect(find.text('Stock Movement Log'), findsOneWidget);
      expect(find.text('Initial stock setup'), findsOneWidget);
      expect(find.text('+15 pcs'), findsOneWidget);
    });

    testWidgets('opens stock operations as a dialog on tablet/desktop widths',
        (tester) async {
      await _pumpAt(
        tester,
        const Size(1000, 900),
        [_sampleItem],
        _sampleItem.id,
      );

      await tester.tap(find.text('Adjust Stock'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.textContaining('Adjust Stock — Wali Maharage'), findsOneWidget);
      expect(find.text('Submit Adjustment'), findsOneWidget);
    });

    testWidgets('opens stock operations as a bottom sheet on phone widths',
        (tester) async {
      await _pumpAt(
        tester,
        const Size(390, 800),
        [_sampleItem],
        _sampleItem.id,
      );

      await tester.ensureVisible(find.text('Record Waste'));
      await tester.tap(find.text('Record Waste'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.textContaining('Record Waste — Wali Maharage'), findsOneWidget);
    });

    testWidgets('shows a not-found state for an unknown item id',
        (tester) async {
      await _pumpAt(
        tester,
        const Size(1000, 900),
        [_sampleItem],
        'missing-item',
      );

      expect(find.text('Item not found.'), findsOneWidget);
      expect(find.text('Back to Inventory'), findsOneWidget);
    });
  });
}
