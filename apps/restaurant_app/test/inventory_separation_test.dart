import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/database/app_database.dart';
import 'package:restaurant_pos/main.dart';
import 'package:restaurant_pos/models/inventory_item.dart';
import 'package:restaurant_pos/providers/database_providers.dart';
import 'package:restaurant_pos/providers/inventory_provider.dart';
import 'package:restaurant_pos/router/app_router.dart';

/// The concrete proof that Groceries and Menu Items are strictly disjoint
/// standalone screens: a `both` item (a bottled drink bought and resold
/// unchanged) lives on Menu Items only — never on Groceries — so the two
/// screens share no rows and neither double-counts.
void main() {
  const flour = InventoryItem(
    id: 'test-flour',
    sku: 'SKU-FLOUR',
    name: 'All-purpose Flour',
    categoryId: 'dry',
    emoji: '🌾',
    stock: 20,
    reorderLevel: 5,
    unitCost: 1.2,
    unit: 'kg',
    itemType: 'raw_material',
  );
  const cola = InventoryItem(
    id: 'test-cola',
    sku: 'SKU-COLA',
    name: 'Bottled Cola',
    categoryId: 'drinks',
    emoji: '🥤',
    stock: 12,
    reorderLevel: 4,
    unitCost: 0.9,
    unit: 'ea',
    itemType: 'both',
    sellingPrice: 2.5,
    isSellable: true,
  );
  const salad = InventoryItem(
    id: 'test-salad',
    sku: 'SKU-SALAD',
    name: 'House Salad',
    categoryId: 'starters',
    emoji: '🥗',
    stock: 0,
    reorderLevel: 0,
    unitCost: 2.1,
    trackStock: false,
    itemType: 'sellable',
    sellingPrice: 9.5,
    isSellable: true,
  );

  Future<ProviderContainer> container() async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        inventoryItemsListProvider.overrideWithValue(
          const [flour, cola, salad],
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('groceries holds raw_material only — no sellable, no both', () async {
    final c = await container();
    final groceries = c.read(groceryItemsProvider);

    expect(groceries.map((i) => i.id), contains('test-flour'));
    expect(groceries.every((i) => i.itemType == 'raw_material'), isTrue);
  });

  test('menu holds sellable and both — no raw_material', () async {
    final c = await container();
    final menuItems = c.read(menuCatalogItemsProvider);

    expect(menuItems.map((i) => i.id), contains('test-salad'));
    expect(menuItems.map((i) => i.id), contains('test-cola'));
    expect(
      menuItems.every(
        (i) => i.itemType == 'sellable' || i.itemType == 'both',
      ),
      isTrue,
    );
  });

  test('the two screens share no rows', () async {
    final c = await container();
    final groceryIds = c.read(groceryItemsProvider).map((i) => i.id).toSet();
    final menuIds = c.read(menuCatalogItemsProvider).map((i) => i.id).toSet();

    expect(groceryIds.intersection(menuIds), isEmpty);
  });

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize =
        const Size(1920, 900) * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        inventoryItemsListProvider.overrideWithValue(
          const [flour, cola, salad],
        ),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const RestaurantPosApp(),
      ),
    );
    await tester.pumpAndSettle();
    return c;
  }

  testWidgets('the both item renders as a row on the Menu Items screen', (
    tester,
  ) async {
    final c = await pumpApp(tester);
    c.read(goRouterProvider).go(AppRoute.menuItems());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Bottled Cola');
    await tester.pumpAndSettle();

    expect(find.text('Bottled Cola'), findsOneWidget);
  });

  testWidgets('the both item does not render on the Groceries screen', (
    tester,
  ) async {
    final c = await pumpApp(tester);
    c.read(goRouterProvider).go(AppRoute.groceries());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Bottled Cola');
    await tester.pumpAndSettle();

    expect(find.text('Bottled Cola'), findsNothing);
  });
}
