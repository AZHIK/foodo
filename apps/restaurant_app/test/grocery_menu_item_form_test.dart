import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/database/app_database.dart';
import 'package:restaurant_pos/main.dart';
import 'package:restaurant_pos/models/inventory_item.dart';
import 'package:restaurant_pos/providers/database_providers.dart';
import 'package:restaurant_pos/providers/grocery_form_provider.dart';
import 'package:restaurant_pos/providers/inventory_provider.dart';
import 'package:restaurant_pos/providers/menu_item_form_provider.dart';
import 'package:restaurant_pos/router/app_router.dart';
import 'package:restaurant_pos/theme/app_theme.dart';
import 'package:restaurant_pos/widgets/dialogs/grocery_form_dialog.dart';
import 'package:restaurant_pos/widgets/dialogs/menu_item_form_dialog.dart';
import 'package:restaurant_pos/widgets/image_upload_field.dart';
import 'package:restaurant_pos/widgets/responsive_form_dialog.dart';

const _widths = <double>[360, 400, 768, 1024, 1440, 1920];

Future<ProviderContainer> pumpGroceries(WidgetTester tester, Size size) async {
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

  container.read(goRouterProvider).go(AppRoute.groceries());
  await tester.pumpAndSettle();
  return container;
}

Future<ProviderContainer> pumpMenuItems(WidgetTester tester, Size size) async {
  final container = await pumpGroceries(tester, size);
  container.read(goRouterProvider).go(AppRoute.menuItems());
  await tester.pumpAndSettle();
  return container;
}

/// Opens the grocery form through the page's own "Add item" button, the way
/// a user does — the dialog's presentation is decided by the helper, not by
/// the test.
Future<void> openGroceryForm(WidgetTester tester) async {
  await tester.tap(find.text('Add item'));
  await tester.pumpAndSettle();
}

Future<void> openMenuForm(WidgetTester tester) async {
  await tester.tap(find.text('Add item'));
  await tester.pumpAndSettle();
}

Future<void> openGroceryEditForm(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Row actions').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Edit item'));
  await tester.pumpAndSettle();
}

Future<void> pickGroceryCategory(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(GroceryFormKeys.category));
  await tester.pumpAndSettle();
  // `.last` — the field renders the value too once one is chosen.
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> pickMenuCategory(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(MenuItemFormKeys.category));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  group('GroceryFormState', () {
    test('required fields gate saving', () {
      var state = GroceryFormState.blank();
      expect(state.canSave, isFalse);

      state = state.copyWith(name: 'Paprika');
      expect(state.canSave, isFalse, reason: 'no category or cost yet');

      state = state.copyWith(categoryId: 'dry');
      expect(state.canSave, isFalse, reason: 'no cost yet');

      state = state.copyWith(unitCost: '4.50');
      expect(state.canSave, isTrue);
    });

    test('a blank low-stock threshold is allowed, a malformed one is not', () {
      final valid = GroceryFormState.blank().copyWith(
        name: 'Paprika',
        categoryId: 'dry',
        unitCost: '4.50',
      );

      expect(valid.copyWith(lowStockAlert: '').canSave, isTrue);
      expect(valid.copyWith(lowStockAlert: '12').canSave, isTrue);
      expect(GroceryFormState.validateLowStockAlert('abc'), isNotNull);
    });

    test('an untracked item never reports as low stock', () {
      const item = InventoryItem(
        id: 'x',
        sku: 'X',
        name: 'X',
        categoryId: 'dry',
        emoji: '📦',
        stock: 0,
        reorderLevel: 10,
        unitCost: 1,
        trackStock: false,
      );

      expect(item.status, StockStatus.inStock);
      expect(item.copyWith(trackStock: true).status, StockStatus.outOfStock);
    });
  });

  group('MenuItemFormState', () {
    test('a fresh form is an untracked dish until the toggle flips', () {
      final state = MenuItemFormState.blank();
      expect(state.trackStock, isFalse);
      expect(state.effectiveItemType, 'sellable');
      expect(
        state.copyWith(trackStock: true).effectiveItemType,
        'both',
      );
    });

    test('name, category, cost and till price gate saving', () {
      var state = MenuItemFormState.blank();
      expect(state.canSave, isFalse);

      state = state.copyWith(name: 'House Salad', categoryId: 'starters');
      expect(state.canSave, isFalse, reason: 'no cost or price yet');

      state = state.copyWith(unitCost: '2.10');
      expect(state.canSave, isFalse, reason: 'no till price yet');

      state = state.copyWith(sellingPrice: '9.50');
      expect(state.canSave, isTrue);
    });

    test('tracked items validate the stock fields, untracked skip them', () {
      final tracked = MenuItemFormState.blank().copyWith(
        name: 'Bottled Cola',
        categoryId: 'drinks',
        unitCost: '0.90',
        sellingPrice: '2.50',
        trackStock: true,
        lowStockAlert: 'nonsense',
      );
      expect(tracked.canSave, isFalse);

      expect(tracked.copyWith(trackStock: false).canSave, isTrue);
    });
  });

  group('Grocery form dialog', () {
    testWidgets('no overflow at any target width', (tester) async {
      for (final width in _widths) {
        await pumpGroceries(tester, Size(width, 900));
        await openGroceryForm(tester);

        expect(
          tester.takeException(),
          isNull,
          reason: 'render error at ${width}px',
        );
        expect(find.byType(ResponsiveFormDialog), findsOneWidget);
        expect(find.byType(ImageUploadField), findsOneWidget);

        await tester.tap(find.byKey(GroceryFormKeys.cancel));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('desktop gets a centered dialog at the form width', (
      tester,
    ) async {
      await pumpGroceries(tester, const Size(1440, 900));
      await openGroceryForm(tester);

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);

      final box = tester.getSize(find.byKey(ResponsiveFormDialog.surfaceKey));
      expect(box.width, GroceryFormDialog.dialogWidth);
      expect(box.height, lessThanOrEqualTo(900 * 0.85));

      // Two columns: the photo sits to the left of the fields, not above them.
      final photo = tester.getTopLeft(find.byType(ImageUploadField));
      final name = tester.getTopLeft(find.byKey(GroceryFormKeys.name));
      expect(name.dx, greaterThan(photo.dx));
    });

    testWidgets('mobile gets a full-height sheet in one column', (
      tester,
    ) async {
      await pumpGroceries(tester, const Size(390, 844));
      await openGroceryForm(tester);

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);

      // Stacked: the fields start below the dropzone, not beside it.
      final photo = tester.getBottomLeft(find.byType(ImageUploadField));
      final name = tester.getTopLeft(find.byKey(GroceryFormKeys.name));
      expect(name.dy, greaterThan(photo.dy));

      // The footer is pinned, so the primary action is on screen without
      // scrolling the body first.
      final sheet = tester.getRect(find.byKey(ResponsiveFormDialog.surfaceKey));
      final submit = tester.getRect(find.byKey(GroceryFormKeys.submit));
      expect(submit.bottom, lessThanOrEqualTo(sheet.bottom));
      expect(submit.bottom, lessThanOrEqualTo(844));
      expect(submit.height, greaterThanOrEqualTo(44));
    });

    testWidgets('the grocery form has no selling-price field', (tester) async {
      await pumpGroceries(tester, const Size(1440, 900));
      await openGroceryForm(tester);

      // Groceries are never sold: stock fields show, price does not exist.
      expect(find.byKey(GroceryFormKeys.reorderQuantity), findsOneWidget);
      expect(find.byKey(GroceryFormKeys.allowNegativeStock), findsOneWidget);
      expect(find.byKey(GroceryFormKeys.unit), findsOneWidget);
      expect(find.text('Selling price'), findsNothing);
    });

    testWidgets('saving adds a tracked raw_material line', (tester) async {
      final container = await pumpGroceries(tester, const Size(1440, 900));

      await openGroceryForm(tester);
      await tester.enterText(find.byKey(GroceryFormKeys.name), 'Smoked Paprika');
      await pickGroceryCategory(tester, 'Dry goods');
      await tester.enterText(find.byKey(GroceryFormKeys.unitCost), '4.50');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(GroceryFormKeys.submit));
      await tester.pumpAndSettle();

      final saved = container
          .read(inventoryItemsListProvider)
          .firstWhere((i) => i.name == 'Smoked Paprika');
      expect(saved.itemType, 'raw_material');
      expect(saved.trackStock, isTrue);
      expect(saved.isSellable, isFalse);
      expect(container.read(groceryItemsProvider).map((i) => i.id),
          contains(saved.id));
      expect(container.read(menuCatalogItemsProvider).map((i) => i.id),
          isNot(contains(saved.id)));
    });

    testWidgets('saving an edit updates the list in place', (tester) async {
      final container = await pumpGroceries(tester, const Size(1440, 900));
      final target = container.read(inventorySliceProvider).items.first;

      await openGroceryEditForm(tester);
      expect(find.text('Edit item'), findsOneWidget);
      expect(find.widgetWithText(TextField, target.name), findsOneWidget);

      // Current stock is shown but has no input to type into.
      expect(find.text('Current stock'), findsOneWidget);
      expect(find.byKey(GroceryFormKeys.stock), findsNothing);
      expect(find.text('Changes go through Stock Adjust'), findsOneWidget);

      await tester.enterText(find.byKey(GroceryFormKeys.name), 'Renamed Item');
      await tester.enterText(find.byKey(GroceryFormKeys.unitCost), '99.00');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(GroceryFormKeys.submit));
      await tester.pumpAndSettle();

      final updated = container
          .read(inventoryItemsListProvider)
          .firstWhere((item) => item.id == target.id);
      expect(updated.name, 'Renamed Item');
      expect(updated.unitCost, 99.00);
      expect(
        container
            .read(inventoryItemsListProvider)
            .where((i) => i.id == target.id),
        hasLength(1),
      );
      expect(find.byType(ResponsiveFormDialog), findsNothing);
    });

    testWidgets('cancel discards the edit', (tester) async {
      final container = await pumpGroceries(tester, const Size(1440, 900));
      final target = container.read(inventorySliceProvider).items.first;

      await openGroceryEditForm(tester);
      await tester.enterText(find.byKey(GroceryFormKeys.name), 'Discard me');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(GroceryFormKeys.cancel));
      await tester.pumpAndSettle();

      expect(
        container
            .read(inventoryItemsListProvider)
            .firstWhere((i) => i.id == target.id)
            .name,
        target.name,
      );
    });

    testWidgets('editing an item with an unknown category does not crash', (
      tester,
    ) async {
      const item = InventoryItem(
        id: 'item-unknown-cat',
        sku: 'SKU-X',
        name: 'Mystery Flour',
        categoryId: 'uncategorized',
        emoji: '🌾',
        stock: 10,
        reorderLevel: 2,
        unitCost: 2.5,
        itemType: 'raw_material',
      );
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          inventoryItemsListProvider.overrideWithValue([item]),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(
              body: GroceryFormDialog(itemId: 'item-unknown-cat'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(GroceryFormKeys.category), findsOneWidget);
      final field = tester.widget<DropdownButtonFormField<String>>(
        find.byKey(GroceryFormKeys.category),
      );
      expect(field.initialValue, isNull);
    });
  });

  group('Menu item form dialog', () {
    testWidgets('no overflow at any target width', (tester) async {
      for (final width in _widths) {
        await pumpMenuItems(tester, Size(width, 900));
        await openMenuForm(tester);

        expect(
          tester.takeException(),
          isNull,
          reason: 'render error at ${width}px',
        );
        expect(find.byType(ResponsiveFormDialog), findsOneWidget);

        await tester.tap(find.byKey(MenuItemFormKeys.cancel));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('price is required, stock fields hide until tracked', (
      tester,
    ) async {
      await pumpMenuItems(tester, const Size(1440, 900));
      await openMenuForm(tester);

      // Untracked by default, so the stock-only fields never render.
      expect(find.byKey(MenuItemFormKeys.reorderQuantity), findsNothing);
      expect(find.byKey(MenuItemFormKeys.allowNegativeStock), findsNothing);
      expect(find.byKey(MenuItemFormKeys.stock), findsNothing);
      // Selling price is enabled and prominent.
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(MenuItemFormKeys.sellingPrice),
                matching: find.byType(TextField),
              ),
            )
            .enabled,
        isTrue,
      );
      // Submit stays disabled until the till price is set.
      expect(
        tester.widget<FilledButton>(find.byKey(MenuItemFormKeys.submit)).onPressed,
        isNull,
      );
    });

    testWidgets('saving untracked creates a sellable dish', (tester) async {
      final container = await pumpMenuItems(tester, const Size(1440, 900));

      await openMenuForm(tester);
      await tester.enterText(find.byKey(MenuItemFormKeys.name), 'House Salad');
      await pickMenuCategory(tester, 'Starters');
      await tester.enterText(find.byKey(MenuItemFormKeys.unitCost), '2.10');
      await tester.enterText(find.byKey(MenuItemFormKeys.sellingPrice), '9.50');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(MenuItemFormKeys.submit));
      await tester.pumpAndSettle();

      final saved = container
          .read(inventoryItemsListProvider)
          .firstWhere((i) => i.name == 'House Salad');
      expect(saved.itemType, 'sellable');
      expect(saved.trackStock, isFalse);
      expect(saved.isSellable, isTrue);
    });

    testWidgets('flipping the stock switch saves a tracked both line', (
      tester,
    ) async {
      final container = await pumpMenuItems(tester, const Size(1440, 900));

      await openMenuForm(tester);
      await tester.tap(find.byKey(MenuItemFormKeys.trackStock));
      await tester.pumpAndSettle();

      expect(find.byKey(MenuItemFormKeys.reorderQuantity), findsOneWidget);
      expect(find.byKey(MenuItemFormKeys.stock), findsOneWidget);

      await tester.enterText(find.byKey(MenuItemFormKeys.name), 'Bottled Cola');
      await pickMenuCategory(tester, 'Beverages');
      await tester.enterText(find.byKey(MenuItemFormKeys.unitCost), '0.90');
      await tester.enterText(find.byKey(MenuItemFormKeys.sellingPrice), '2.50');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(MenuItemFormKeys.submit));
      await tester.pumpAndSettle();

      final saved = container
          .read(inventoryItemsListProvider)
          .firstWhere((i) => i.name == 'Bottled Cola');
      expect(saved.itemType, 'both');
      expect(saved.trackStock, isTrue);
      // A counted menu line lives on Menu Items — never on Groceries.
      expect(container.read(menuCatalogItemsProvider).map((i) => i.id),
          contains(saved.id));
      expect(container.read(groceryItemsProvider).map((i) => i.id),
          isNot(contains(saved.id)));
    });
  });
}
