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
import 'package:restaurant_pos/widgets/data_page/data_row_card.dart';
import 'package:restaurant_pos/widgets/data_page/status_badge.dart';
import 'package:restaurant_pos/widgets/data_page/summary_metric_card.dart';
import 'package:restaurant_pos/widgets/inventory/inventory_tab_bar.dart';

const _widths = <double>[360, 400, 768, 1024, 1440, 1920];

Future<ProviderContainer> pumpGroceries(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.reset);

  // No business/store context is seeded, so this falls back to
  // `MockInventory` — see inventory_provider.dart's `InventoryNotifier.build`.
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

  container.read(goRouterProvider).go(AppRoute.groceries());
  await tester.pumpAndSettle();
  return container;
}

/// The page is one ListView, so anything below the fold is not built yet.
Future<void> scrollDown(WidgetTester tester, [double by = 500]) async {
  await tester.drag(find.byType(ListView), Offset(0, -by));
  await tester.pumpAndSettle();
}

void main() {
  group('Groceries query', () {
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

    test('only raw_material and both items appear', () async {
      final c = await container();
      final all = c.read(inventoryItemsListProvider);
      final groceries = c.read(groceryItemsProvider);

      expect(all.any((i) => i.itemType == 'sellable'), isTrue,
          reason: 'the fixture has to actually contain a pure menu item '
              'for this test to mean anything');
      expect(
        groceries.every((i) => i.itemType == 'raw_material' || i.itemType == 'both'),
        isTrue,
      );
      expect(groceries.any((i) => i.itemType == 'both'), isTrue);
      expect(groceries.where((i) => i.itemType == 'sellable'), isEmpty);
    });

    test('summary is scoped to groceries, not the whole catalog', () async {
      final c = await container();
      final groceries = c.read(groceryItemsProvider);
      final summary = c.read(inventorySummaryProvider);

      expect(summary.totalItems, groceries.length);
      expect(summary.totalItems, lessThan(c.read(inventoryItemsListProvider).length));
      expect(
        summary.lowStockCount,
        groceries.where((i) => i.status == StockStatus.lowStock).length,
      );
      expect(
        summary.outOfStockCount,
        groceries.where((i) => i.status == StockStatus.outOfStock).length,
      );
      expect(
        summary.totalValue,
        groceries.fold<double>(0, (sum, i) => sum + i.totalValue),
      );
    });
  });

  group('Groceries screen', () {
    testWidgets('no overflow at any target width', (tester) async {
      for (final width in _widths) {
        await pumpGroceries(tester, Size(width, 900));
        expect(tester.takeException(), isNull, reason: 'render error at ${width}px');
        expect(find.byType(SummaryMetricCard), findsNWidgets(4));
      }
    });

    testWidgets('the tab bar shows Groceries selected', (tester) async {
      await pumpGroceries(tester, const Size(1440, 900));
      expect(find.byType(InventoryTabBar), findsOneWidget);
      expect(find.text('Groceries'), findsWidgets);
      expect(find.text('Menu items'), findsWidgets);
    });

    testWidgets('desktop shows the grocery-specific columns', (tester) async {
      await pumpGroceries(tester, const Size(1920, 900));

      expect(find.byType(DataRowCard<InventoryItem>), findsNothing);
      expect(find.text('ITEM'), findsOneWidget);
      expect(find.text('CATEGORY'), findsOneWidget);
      expect(find.text('UNIT'), findsOneWidget);
      expect(find.text('STOCK'), findsOneWidget);
      expect(find.text('REORDER AT'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
      // No selling-price column — that is Menu Items' field, not Groceries'.
      expect(find.text('PRICE'), findsNothing);
    });

    testWidgets('every row is a grocery item — none is a pure menu item', (
      tester,
    ) async {
      final container = await pumpGroceries(tester, const Size(1440, 900));
      final rows = container.read(inventorySliceProvider).items;

      expect(rows, isNotEmpty);
      expect(rows.every((i) => i.itemType != 'sellable'), isTrue);
    });

    testWidgets('low-stock and out-of-stock rows carry the right badge', (
      tester,
    ) async {
      final container = await pumpGroceries(tester, const Size(1440, 900));
      container.read(inventoryFiltersProvider.notifier)
        ..clear()
        ..toggleStatus(StockStatus.outOfStock);
      await tester.pumpAndSettle();

      final rows = container.read(inventorySliceProvider).items;
      expect(rows, isNotEmpty);
      expect(rows.every((i) => i.status == StockStatus.outOfStock), isTrue);

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge).first);
      expect(badge.label, 'Out of stock');
      expect(badge.tone, StatusTone.danger);
    });

    testWidgets('the summary cards reflect the grocery-scoped totals', (
      tester,
    ) async {
      final container = await pumpGroceries(tester, const Size(1440, 900));
      final summary = container.read(inventorySummaryProvider);

      expect(find.text('${summary.totalItems}'), findsWidgets);
      expect(find.text('${summary.lowStockCount}'), findsWidgets);
      expect(find.text('${summary.outOfStockCount}'), findsWidgets);
    });
  });
}
