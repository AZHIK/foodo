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

/// Confirms Groceries and Menu Items are standalone Stock destinations with
/// their own routes and no shared tab bar: each renders from its own
/// sidebar entry, and neither screen links to the other.
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

  testWidgets('/menu-items renders Menu Items on its own branch', (
    tester,
  ) async {
    final container = await pumpApp(tester, const Size(1440, 900));
    container.read(goRouterProvider).go(AppRoute.menuItems());
    await tester.pumpAndSettle();

    expect(find.byType(InventoryMenuItemsScreen), findsOneWidget);
    expect(find.byType(InventoryGroceriesScreen), findsNothing);
  });

  testWidgets('neither screen renders a shared tab bar', (tester) async {
    final container = await pumpApp(tester, const Size(1440, 900));

    // The old InventoryTabBar was a SegmentedButton switching two views in
    // place — neither standalone screen may contain one.
    container.read(goRouterProvider).go(AppRoute.groceries());
    await tester.pumpAndSettle();
    expect(find.byType(SegmentedButton), findsNothing);

    container.read(goRouterProvider).go(AppRoute.menuItems());
    await tester.pumpAndSettle();
    expect(find.byType(SegmentedButton), findsNothing);
  });

  testWidgets('the Stock group lists Groceries and Menu items separately', (
    tester,
  ) async {
    final container = await pumpApp(tester, const Size(1440, 900));
    container.read(goRouterProvider).go(AppRoute.groceries());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stock'));
    await tester.pumpAndSettle();

    // Both standalone entries appear in the sidebar; the old single
    // "Inventory" destination is gone.
    expect(find.text('Groceries'), findsWidgets);
    expect(find.text('Menu items'), findsWidgets);
    expect(find.text('Inventory'), findsNothing);
  });
}
