import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/main.dart';
import 'package:restaurant_pos/models/inventory_item.dart';
import 'package:restaurant_pos/providers/inventory_provider.dart';
import 'package:restaurant_pos/providers/stock_movement_provider.dart';
import 'package:restaurant_pos/router/app_router.dart';
import 'package:restaurant_pos/screens/inventory/stock_dialog_shared.dart';
import 'package:restaurant_pos/widgets/data_page/data_row_card.dart';
import 'package:restaurant_pos/widgets/dialogs/item_form_dialog.dart';
import 'package:restaurant_pos/widgets/data_page/summary_metric_card.dart';

const _widths = <double>[360, 400, 768, 1024, 1440, 1920];

Future<ProviderContainer> pumpInventory(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.reset);

  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const RestaurantPosApp(),
    ),
  );
  await tester.pumpAndSettle();

  container.read(goRouterProvider).go('/inventory');
  await tester.pumpAndSettle();
  return container;
}

/// The page is one ListView, so anything below the fold is not built yet.
/// Tests asserting on the table or its footer have to bring it into view
/// first, exactly as a user would.
///
/// Targets the page's ListView specifically — the navigation rail is itself
/// scrollable, and is the first Scrollable in the tree on desktop.
Future<void> scrollDown(WidgetTester tester, [double by = 500]) async {
  await tester.drag(find.byType(ListView), Offset(0, -by));
  await tester.pumpAndSettle();
}

void main() {
  group('Inventory model', () {
    test('status derives from stock against the reorder level', () {
      const base = InventoryItem(
        id: 'x',
        sku: 'X',
        name: 'X',
        categoryId: 'dry',
        emoji: '📦',
        stock: 20,
        reorderLevel: 10,
        unitCost: 2.50,
      );

      expect(base.status, StockStatus.inStock);
      expect(base.copyWith(stock: 10).status, StockStatus.lowStock);
      expect(base.copyWith(stock: 3).status, StockStatus.lowStock);
      expect(base.copyWith(stock: 0).status, StockStatus.outOfStock);
      expect(base.totalValue, 50.0);
    });
  });

  group('Inventory providers', () {
    ProviderContainer container() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c;
    }

    test('search matches name, sku and category', () {
      final c = container();
      c.read(inventoryQueryProvider.notifier).setSearch('salmon');
      expect(c.read(filteredInventoryProvider), hasLength(1));

      c.read(inventoryQueryProvider.notifier).setSearch('BEV-');
      final bySku = c.read(filteredInventoryProvider);
      expect(bySku, isNotEmpty);
      expect(bySku.every((i) => i.sku.startsWith('BEV-')), isTrue);
    });

    test('category and status filters compose', () {
      final c = container();
      c.read(inventoryFiltersProvider.notifier).toggleCategory('produce');
      c
          .read(inventoryFiltersProvider.notifier)
          .toggleStatus(StockStatus.outOfStock);

      final rows = c.read(filteredInventoryProvider);
      expect(rows, isNotEmpty);
      expect(
        rows.every(
          (i) =>
              i.categoryId == 'produce' && i.status == StockStatus.outOfStock,
        ),
        isTrue,
      );
      expect(c.read(inventoryFiltersProvider).activeCount, 2);
    });

    test('stock range filter bounds both ends', () {
      final c = container();
      c.read(inventoryFiltersProvider.notifier).setStockRange(10, 30);

      final rows = c.read(filteredInventoryProvider);
      expect(rows, isNotEmpty);
      expect(rows.every((i) => i.stock >= 10 && i.stock <= 30), isTrue);
      expect(c.read(inventoryFiltersProvider).activeCount, 1);
    });

    test('changing a filter returns to page one', () {
      final c = container();
      c.read(inventoryQueryProvider.notifier).setPage(3);
      expect(c.read(inventoryQueryProvider).page, 3);

      c.read(inventoryFiltersProvider.notifier).toggleCategory('meat');
      expect(c.read(inventoryQueryProvider).page, 0);
    });

    test('sorting by stock orders ascending then descending', () {
      final c = container();
      c
          .read(inventoryQueryProvider.notifier)
          .setSort(InventorySort.stock, ascending: true);
      final up = c.read(filteredInventoryProvider).map((i) => i.stock).toList();
      expect(up, orderedEquals([...up]..sort()));

      c.read(inventoryQueryProvider.notifier).toggleSort(InventorySort.stock);
      final down = c
          .read(filteredInventoryProvider)
          .map((i) => i.stock)
          .toList();
      expect(down.first, greaterThanOrEqualTo(down.last));
    });

    test('summary counts low and out-of-stock separately', () {
      final c = container();
      final items = c.read(inventoryItemsProvider);
      final summary = c.read(inventorySummaryProvider);

      expect(summary.totalItems, items.length);
      expect(
        summary.lowStockCount,
        items.where((i) => i.status == StockStatus.lowStock).length,
      );
      expect(
        summary.outOfStockCount,
        items.where((i) => i.status == StockStatus.outOfStock).length,
      );
      expect(summary.totalValue, greaterThan(0));
    });

    test('CRUD flows through the notifier', () {
      final c = container();
      final notifier = c.read(inventoryItemsProvider.notifier);
      final before = c.read(inventoryItemsProvider).length;

      final id = notifier.nextId();
      notifier.upsert(
        InventoryItem(
          id: id,
          sku: 'TST-1',
          name: 'Test Item',
          categoryId: 'dry',
          emoji: '📦',
          stock: 5,
          reorderLevel: 10,
          unitCost: 1.00,
        ),
      );
      expect(c.read(inventoryItemsProvider), hasLength(before + 1));

      notifier.adjustStock(id, 20);
      final adjusted = c
          .read(inventoryItemsProvider)
          .firstWhere((i) => i.id == id);
      expect(adjusted.stock, 25);
      expect(adjusted.status, StockStatus.inStock);

      // Stock can run out but must never go negative.
      notifier.adjustStock(id, -999);
      expect(
        c.read(inventoryItemsProvider).firstWhere((i) => i.id == id).stock,
        0,
      );

      notifier.delete(id);
      expect(c.read(inventoryItemsProvider), hasLength(before));
    });

    test('pagination slices the filtered list', () {
      final c = container();
      final total = c.read(filteredInventoryProvider).length;
      final slice = c.read(inventorySliceProvider);

      expect(slice.pageSize, 8);
      expect(slice.items, hasLength(8));
      expect(slice.totalCount, total);

      c.read(inventoryQueryProvider.notifier).setPage(1);
      expect(c.read(inventorySliceProvider).firstRow, 9);
    });
  });

  group('Inventory screen', () {
    testWidgets('no overflow at any target width', (tester) async {
      for (final width in _widths) {
        await pumpInventory(tester, Size(width, 900));
        expect(
          tester.takeException(),
          isNull,
          reason: 'render error at ${width}px',
        );
        expect(find.byType(SummaryMetricCard), findsNWidgets(3));
      }
    });

    testWidgets('mobile stacks metrics and uses cards', (tester) async {
      await pumpInventory(tester, const Size(390, 844));
      await scrollDown(tester);

      expect(find.byType(DataRowCard<InventoryItem>), findsWidgets);
      // Stacked one per row: each card spans the content width.
      final cards = tester
          .widgetList<SummaryMetricCard>(find.byType(SummaryMetricCard))
          .length;
      expect(cards, 3);
    });

    testWidgets('desktop shows the table with all columns', (tester) async {
      await pumpInventory(tester, const Size(1440, 900));

      expect(find.byType(DataRowCard<InventoryItem>), findsNothing);
      expect(find.text('ITEM'), findsOneWidget);
      expect(find.text('CATEGORY'), findsOneWidget);
      expect(find.text('UNIT COST'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
    });

    testWidgets('search narrows the table live', (tester) async {
      final container = await pumpInventory(tester, const Size(1440, 900));

      await tester.enterText(find.byType(TextField).first, 'truffle');
      await tester.pumpAndSettle();

      expect(container.read(filteredInventoryProvider), hasLength(1));
      expect(find.text('Showing 1–1 of 1'), findsOneWidget);
    });

    testWidgets('filter panel applies a category filter', (tester) async {
      final container = await pumpInventory(tester, const Size(1440, 900));

      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Beverages'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await tester.pumpAndSettle();

      final rows = container.read(filteredInventoryProvider);
      expect(rows.every((i) => i.categoryId == 'drinks'), isTrue);
      expect(container.read(inventoryFiltersProvider).activeCount, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('adding an item puts it in the table', (tester) async {
      final container = await pumpInventory(tester, const Size(1440, 900));
      final before = container.read(inventoryItemsProvider).length;

      await tester.tap(find.text('Add item'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(ItemFormKeys.name), 'Smoked Paprika');
      await tester.tap(find.byKey(ItemFormKeys.category));
      await tester.pumpAndSettle();
      // The menu overlay entry, not the field's own rendering of the value.
      await tester.tap(find.text('Dry goods').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(ItemFormKeys.unitCost), '4.50');
      await tester.enterText(find.byKey(ItemFormKeys.lowStockAlert), '5');
      await tester.enterText(find.byKey(ItemFormKeys.stock), '12');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ItemFormKeys.submit));
      await tester.pumpAndSettle();

      final items = container.read(inventoryItemsProvider);
      expect(items, hasLength(before + 1));
      expect(items.first.name, 'Smoked Paprika');
      expect(items.first.categoryId, 'dry');
      expect(items.first.stock, 12);
      expect(items.first.status, StockStatus.inStock);
    });

    testWidgets('the add form stays disabled until it is valid', (
      tester,
    ) async {
      final container = await pumpInventory(tester, const Size(1440, 900));
      final before = container.read(inventoryItemsProvider).length;

      await tester.tap(find.text('Add item'));
      await tester.pumpAndSettle();

      FilledButton submit() =>
          tester.widget<FilledButton>(find.byKey(ItemFormKeys.submit));

      // Nothing filled in: the primary action is dead rather than saving a
      // half-formed item.
      expect(submit().onPressed, isNull);

      await tester.enterText(find.byKey(ItemFormKeys.name), 'Smoked Paprika');
      await tester.pumpAndSettle();

      // A name alone is not enough, and the two fields still missing say so.
      expect(submit().onPressed, isNull);
      expect(find.text('Pick a category'), findsOneWidget);
      expect(find.text('Enter a unit cost'), findsOneWidget);

      await tester.tap(find.byKey(ItemFormKeys.category));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dry goods').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(ItemFormKeys.unitCost), '4.50');
      await tester.pumpAndSettle();

      expect(submit().onPressed, isNotNull);
      expect(container.read(inventoryItemsProvider), hasLength(before));
    });

    testWidgets('row action deletes after confirmation', (tester) async {
      final container = await pumpInventory(tester, const Size(1440, 900));
      final before = container.read(inventoryItemsProvider).length;
      final target = container.read(inventorySliceProvider).items.first;

      await tester.tap(find.byTooltip('Row actions').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete ${target.name}?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(container.read(inventoryItemsProvider), hasLength(before - 1));
    });

    testWidgets('adjust stock updates the count', (tester) async {
      final container = await pumpInventory(tester, const Size(1440, 900));
      final target = container.read(inventorySliceProvider).items.first;

      await tester.tap(find.byTooltip('Row actions').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adjust stock'));
      await tester.pumpAndSettle();

      // "Add stock" is the default adjustment type, so entering a quantity is
      // the whole interaction.
      await tester.enterText(find.byKey(StockDialogKeys.quantity), '1');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(StockDialogKeys.submit));
      await tester.pumpAndSettle();

      final updated = container
          .read(inventoryItemsProvider)
          .firstWhere((item) => item.id == target.id);
      expect(updated.stock, target.stock + 1);
    });

    testWidgets('an adjustment is recorded in the item ledger', (tester) async {
      final container = await pumpInventory(tester, const Size(1440, 900));
      final target = container.read(inventorySliceProvider).items.first;
      final before = container.read(itemStockHistoryProvider(target.id)).length;

      await tester.tap(find.byTooltip('Row actions').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adjust stock'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(StockDialogKeys.quantity), '5');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(StockDialogKeys.submit));
      await tester.pumpAndSettle();

      final history = container.read(itemStockHistoryProvider(target.id));
      expect(history, hasLength(before + 1));

      // The ledger's newest balance has to equal the item's stock, or the
      // history is telling a different story from the table.
      final item = container
          .read(inventoryItemsProvider)
          .firstWhere((i) => i.id == target.id);
      expect(history.first.balance, item.stock);
      expect(history.first.delta, 5);
    });

    testWidgets('waste cannot exceed what is on the shelf', (tester) async {
      final container = await pumpInventory(tester, const Size(1440, 900));
      final target = container
          .read(inventorySliceProvider)
          .items
          .firstWhere((item) => item.stock > 0);
      final index = container
          .read(inventorySliceProvider)
          .items
          .indexOf(target);

      await tester.tap(find.byTooltip('Row actions').at(index));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log waste'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(StockDialogKeys.quantity),
        '${target.stock + 10}',
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Only ${target.stock}'), findsOneWidget);

      final submit = tester.widget<FilledButton>(
        find.byKey(StockDialogKeys.submit),
      );
      expect(submit.onPressed, isNull);
    });

    testWidgets('header sort reorders rows and shows the arrow', (
      tester,
    ) async {
      final container = await pumpInventory(tester, const Size(1440, 900));

      await tester.tap(find.text('STOCK'));
      await tester.pumpAndSettle();

      expect(
        container.read(inventoryQueryProvider).sortField,
        InventorySort.stock,
      );
      expect(find.byIcon(Icons.arrow_upward_rounded), findsWidgets);
    });

    testWidgets('pagination moves through pages', (tester) async {
      final container = await pumpInventory(tester, const Size(1440, 900));
      await scrollDown(tester);
      expect(find.text('Showing 1–8 of 34'), findsOneWidget);

      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();

      expect(container.read(inventoryQueryProvider).page, 1);
      expect(find.text('Showing 9–16 of 34'), findsOneWidget);
    });
  });
}
