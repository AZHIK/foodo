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

const _widths = <double>[360, 400, 768, 1024, 1440, 1920];

/// Local catalog fixtures — a mix of grocery and sellable-only items with
/// varied stock levels, so the query, summary and table tests have real
/// rows to work with. Plain test data, not shared fixtures.
List<InventoryItem> _fixtureItems() => [
      InventoryItem(
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
      ),
      InventoryItem(
        id: 'test-tomatoes',
        sku: 'SKU-TOMATO',
        name: 'Heirloom Tomatoes',
        categoryId: 'produce',
        emoji: '🍅',
        stock: 2,
        reorderLevel: 5,
        unitCost: 0.8,
        unit: 'kg',
        itemType: 'both',
        sellingPrice: 3.5,
        isSellable: true,
      ),
      InventoryItem(
        id: 'test-milk',
        sku: 'SKU-MILK',
        name: 'Whole Milk',
        categoryId: 'dairy',
        emoji: '🥛',
        stock: 0,
        reorderLevel: 4,
        unitCost: 1.0,
        unit: 'L',
        itemType: 'raw_material',
      ),
      InventoryItem(
        id: 'test-pizza',
        sku: 'SKU-PIZZA',
        name: 'Margherita Pizza',
        categoryId: 'mains',
        emoji: '🍕',
        stock: 0,
        reorderLevel: 0,
        unitCost: 2.5,
        trackStock: false,
        itemType: 'sellable',
        sellingPrice: 12.0,
        isSellable: true,
      ),
    ];

Future<ProviderContainer> pumpGroceries(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.reset);

  // No business/store context is seeded, so the inventory list comes from
  // the fixture override below — the provider itself returns empty with no
  // context. See inventory_provider.dart's `InventoryNotifier.build`.
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);

  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      inventoryItemsListProvider.overrideWithValue(_fixtureItems()),
    ],
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
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          inventoryItemsListProvider.overrideWithValue(_fixtureItems()),
        ],
      );
      addTearDown(c.dispose);
      await c.read(inventoryItemsProvider.future);
      return c;
    }

    test('only raw_material items appear — never sellable, never both', () async {
      final c = await container();
      final all = c.read(inventoryItemsListProvider);
      final groceries = c.read(groceryItemsProvider);

      expect(all.any((i) => i.itemType == 'sellable'), isTrue,
          reason: 'the fixture has to actually contain a pure menu item '
              'for this test to mean anything');
      expect(all.any((i) => i.itemType == 'both'), isTrue,
          reason: 'the fixture has to contain a both item to prove it stays '
              'on Menu Items');
      expect(
        groceries.every((i) => i.itemType == 'raw_material'),
        isTrue,
      );
      expect(groceries.where((i) => i.itemType == 'both'), isEmpty);
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

    testWidgets('no standalone tab bar links away from Groceries', (tester) async {
      await pumpGroceries(tester, const Size(1440, 900));
      expect(find.byType(SegmentedButton), findsNothing);
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

    testWidgets('every row is a grocery item — raw materials only', (
      tester,
    ) async {
      final container = await pumpGroceries(tester, const Size(1440, 900));
      final rows = container.read(inventorySliceProvider).items;

      expect(rows, isNotEmpty);
      expect(rows.every((i) => i.itemType == 'raw_material'), isTrue);
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
