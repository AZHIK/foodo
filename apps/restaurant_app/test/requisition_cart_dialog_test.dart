/// Widget tests for the requisition cart dialog's responsive presentation.
///
/// - Mobile width → full-height bottom sheet; desktop width → centered
///   modal dialog (same component, layout-only change).
/// - Cart state survives dismiss (session-only cart, no server draft).
/// - Unassigned lines render the "No supplier" badge and the submit footer
///   explains the blocker inline.
/// - Per-item badge tap opens the nested supplier picker; choosing a
///   supplier updates that line only.
/// - Esc closes the desktop dialog.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/models/inventory_item.dart';
import 'package:restaurant_pos/models/supplier.dart';
import 'package:restaurant_pos/providers/connectivity_provider.dart';
import 'package:restaurant_pos/providers/inventory_provider.dart';
import 'package:restaurant_pos/providers/permissions_provider.dart';
import 'package:restaurant_pos/providers/requisition_cart_provider.dart';
import 'package:restaurant_pos/providers/suppliers_provider.dart';
import 'package:restaurant_pos/screens/purchasing/requisition_cart_dialog.dart';
import 'package:restaurant_pos/theme/app_theme.dart';

import 'test_helpers/test_container.dart';

InventoryItem _item(String id, String name) => InventoryItem(
      id: id,
      sku: 'SKU-$id',
      name: name,
      categoryId: 'cat-1',
      emoji: '🥕',
      stock: 10,
      reorderLevel: 2,
      unitCost: 1.5,
      unit: 'kg',
      itemType: 'raw_material',
    );

Supplier _supplier(String id, String name) => Supplier(
      id: id,
      name: name,
      phone: '+255700000000',
      createdAt: DateTime.utc(2026, 1, 1),
    );

ProviderContainer _container() => newTestContainer(
      extraOverrides: [
        suppliersListProvider
            .overrideWithValue([_supplier('sup-a', 'Supplier A')]),
        inventoryItemsListProvider
            .overrideWithValue([_item('flour', 'Flour')]),
        isOnlineProvider.overrideWith((ref) => Stream.value(true)),
        currentBusinessIdProvider.overrideWithValue('biz-1'),
        currentStoreIdProvider.overrideWithValue('store-1'),
      ],
    );

Future<void> _pumpTrigger(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => showRequisitionCart(context),
                child: const Text('Open cart'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open cart'));
  await tester.pumpAndSettle();
}

void _setSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('Requisition cart dialog', () {
    testWidgets('mobile width opens a bottom sheet', (tester) async {
      _setSurface(tester, const Size(390, 844));
      await _pumpTrigger(tester, _container());
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Cart is empty'), findsOneWidget);
    });

    testWidgets('desktop width opens a centered dialog', (tester) async {
      _setSurface(tester, const Size(1440, 900));
      await _pumpTrigger(tester, _container());
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('dismiss preserves cart state for the session', (tester) async {
      _setSurface(tester, const Size(1440, 900));
      final container = _container();
      await _pumpTrigger(tester, container);
      container
          .read(requisitionCartProvider.notifier)
          .addItem(itemId: 'flour', itemName: 'Flour', unit: 'kg', qty: 2);
      await tester.pumpAndSettle();
      expect(find.text('Flour'), findsOneWidget);

      // Close icon dismisses…
      await tester.tap(find.byTooltip('Close cart'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);

      // …and reopening shows the same line (no server draft involved).
      await tester.tap(find.text('Open cart'));
      await tester.pumpAndSettle();
      expect(find.text('Flour'), findsOneWidget);
    });

    testWidgets('unassigned line blocks submit with inline reason',
        (tester) async {
      _setSurface(tester, const Size(390, 844));
      final container = _container();
      await _pumpTrigger(tester, container);
      container
          .read(requisitionCartProvider.notifier)
          .addItem(itemId: 'flour', itemName: 'Flour', unit: 'kg', qty: 2);
      await tester.pumpAndSettle();

      expect(find.text('No supplier'), findsOneWidget);
      expect(find.text('1 item needs a supplier'), findsOneWidget);
    });

    testWidgets('badge tap opens picker and assigns that line only',
        (tester) async {
      _setSurface(tester, const Size(1440, 900));
      final container = _container();
      await _pumpTrigger(tester, container);
      final notifier = container.read(requisitionCartProvider.notifier);
      notifier.addItem(
          itemId: 'flour', itemName: 'Flour', unit: 'kg', qty: 2);
      await tester.pumpAndSettle();

      await tester.tap(find.text('No supplier'));
      await tester.pumpAndSettle();
      // Nested picker on desktop is a Dialog above the cart dialog.
      expect(find.text('Choose supplier'), findsOneWidget);
      await tester.tap(find.text('Supplier A'));
      await tester.pumpAndSettle();

      expect(find.text('Supplier A'), findsWidgets);
      expect(
          container
              .read(requisitionCartProvider)
              .lines
              .first
              .supplierId,
          'sup-a');
    });

    testWidgets('escape closes the desktop dialog', (tester) async {
      _setSurface(tester, const Size(1440, 900));
      await _pumpTrigger(tester, _container());
      expect(find.byType(Dialog), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });
  });
}
