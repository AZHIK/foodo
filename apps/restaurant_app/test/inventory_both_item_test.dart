import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/database/app_database.dart';
import 'package:restaurant_pos/main.dart';
import 'package:restaurant_pos/providers/database_providers.dart';
import 'package:restaurant_pos/providers/inventory_provider.dart';
import 'package:restaurant_pos/router/app_router.dart';

/// The concrete proof that an `item_type == 'both'` item — a bottled drink
/// bought and resold unchanged, per the mock fixture's "Sparkling Water"
/// line — genuinely appears in *both* Inventory views at once, rather than
/// being accidentally excluded from one of them by the split.
void main() {
  Future<ProviderContainer> container() async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final c = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(c.dispose);
    await c.read(inventoryItemsProvider.future);
    return c;
  }

  test('a both-type item is present in the raw provider once, itemType=both', () async {
    final c = await container();
    final items = c.read(inventoryItemsListProvider);
    final bothItems = items.where((i) => i.itemType == 'both').toList();

    expect(bothItems, isNotEmpty, reason: 'the fixture needs a both item for this to prove anything');
    final drink = bothItems.first;
    expect(drink.isGroceryItem, isTrue);
    expect(drink.isMenuCatalogItem, isTrue);
  });

  test('a both-type item appears in groceryItemsProvider AND menuCatalogItemsProvider simultaneously', () async {
    final c = await container();
    final both = c
        .read(inventoryItemsListProvider)
        .firstWhere((i) => i.itemType == 'both');

    final groceries = c.read(groceryItemsProvider);
    final menuItems = c.read(menuCatalogItemsProvider);

    expect(groceries.map((i) => i.id), contains(both.id));
    expect(menuItems.map((i) => i.id), contains(both.id));
  });

  testWidgets('the both item renders as a row on the Groceries screen', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);
    await container.read(inventoryItemsProvider.future);
    final both = container
        .read(inventoryItemsListProvider)
        .firstWhere((i) => i.itemType == 'both');

    tester.view.physicalSize = const Size(1920, 900) * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RestaurantPosApp(),
      ),
    );
    await tester.pumpAndSettle();
    container.read(goRouterProvider).go(AppRoute.groceries());
    await tester.pumpAndSettle();

    // The table paginates at 8 rows, and the both item may not be on page
    // one alphabetically — search narrows straight to it.
    await tester.enterText(find.byType(TextField).first, both.name);
    await tester.pumpAndSettle();

    expect(find.text(both.name), findsOneWidget);
  });

  testWidgets('the same both item renders as a row on the Menu Items screen', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);
    await container.read(inventoryItemsProvider.future);
    final both = container
        .read(inventoryItemsListProvider)
        .firstWhere((i) => i.itemType == 'both');

    tester.view.physicalSize = const Size(1920, 900) * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RestaurantPosApp(),
      ),
    );
    await tester.pumpAndSettle();
    container.read(goRouterProvider).go(AppRoute.menuItems());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, both.name);
    await tester.pumpAndSettle();

    expect(find.text(both.name), findsOneWidget);
  });
}
