import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/database/app_database.dart';
import 'package:restaurant_pos/main.dart';
import 'package:restaurant_pos/providers/database_providers.dart';
import 'package:restaurant_pos/router/app_router.dart';
import 'package:restaurant_pos/screens/inventory/inventory_groceries_screen.dart';
import 'package:restaurant_pos/screens/inventory/inventory_menu_items_screen.dart';

/// Confirms the single "Inventory" nav destination hosts both Groceries and
/// Menu Items via the [InventoryTabBar] segmented control — the same
/// sub-navigation pattern Finance uses for Other Expenses / Other Incomes —
/// rather than two separate nav destinations or a filter on one shared table.
void main() {
  Future<ProviderContainer> pumpApp(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RestaurantPosApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('the bare /inventory path renders Groceries by default', (
    tester,
  ) async {
    final container = await pumpApp(tester, const Size(1440, 900));
    container.read(goRouterProvider).go(AppRoute.inventoryPath);
    await tester.pumpAndSettle();

    expect(find.byType(InventoryGroceriesScreen), findsOneWidget);
    expect(find.byType(InventoryMenuItemsScreen), findsNothing);
  });

  testWidgets('tapping the Menu items segment switches views in place', (
    tester,
  ) async {
    final container = await pumpApp(tester, const Size(1440, 900));
    container.read(goRouterProvider).go(AppRoute.groceries());
    await tester.pumpAndSettle();
    expect(find.byType(InventoryGroceriesScreen), findsOneWidget);

    await tester.tap(find.text('Menu items'));
    await tester.pumpAndSettle();

    expect(find.byType(InventoryMenuItemsScreen), findsOneWidget);
    expect(find.byType(InventoryGroceriesScreen), findsNothing);
  });

  testWidgets('tapping the Groceries segment switches back', (tester) async {
    final container = await pumpApp(tester, const Size(1440, 900));
    container.read(goRouterProvider).go(AppRoute.menuItems());
    await tester.pumpAndSettle();
    expect(find.byType(InventoryMenuItemsScreen), findsOneWidget);

    await tester.tap(find.text('Groceries'));
    await tester.pumpAndSettle();

    expect(find.byType(InventoryGroceriesScreen), findsOneWidget);
    expect(find.byType(InventoryMenuItemsScreen), findsNothing);
  });

  testWidgets('both routes stay under the same nav destination — no second '
      'Inventory-like rail entry appears', (tester) async {
    final container = await pumpApp(tester, const Size(1440, 900));
    container.read(goRouterProvider).go(AppRoute.groceries());
    await tester.pumpAndSettle();
    // "Inventory" appears exactly once in the rail; there is no separate
    // "Groceries"/"Menu items" top-level destination.
    expect(find.text('Inventory'), findsOneWidget);
  });
}
