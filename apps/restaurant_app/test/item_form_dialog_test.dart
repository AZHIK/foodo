import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/database/app_database.dart';
import 'package:restaurant_pos/main.dart';
import 'package:restaurant_pos/models/inventory_item.dart';
import 'package:restaurant_pos/providers/database_providers.dart';
import 'package:restaurant_pos/providers/inventory_provider.dart';
import 'package:restaurant_pos/providers/item_form_provider.dart';
import 'package:restaurant_pos/router/app_router.dart';
import 'package:restaurant_pos/widgets/dialogs/item_form_dialog.dart';
import 'package:restaurant_pos/widgets/image_upload_field.dart';
import 'package:restaurant_pos/widgets/responsive_form_dialog.dart';

const _widths = <double>[360, 400, 768, 1024, 1440, 1920];

Future<ProviderContainer> pumpInventory(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.reset);

  // See inventory_screen_test.dart's pumpInventory for why this override is
  // required now that InventoryNotifier watches authProvider.
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

  container.read(goRouterProvider).go('/inventory');
  await tester.pumpAndSettle();
  return container;
}

/// Opens the form through the page's own "Add item" button, the way a user
/// does — the dialog's presentation is decided by the helper, not by the test.
///
/// Also answers the entry-choice step with "both bought and sold", which
/// shows every field the pre-split dialog used to show unconditionally — the
/// tests below that are not specifically about the chooser rely on that full
/// field set. The chooser itself is exercised separately, in the "Item type
/// entry choice" group.
Future<void> openAddForm(WidgetTester tester) async {
  await tester.tap(find.text('Add item'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ItemFormKeys.chooseBoth));
  await tester.pumpAndSettle();
}

Future<void> openEditForm(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Row actions').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Edit item'));
  await tester.pumpAndSettle();
}

Future<void> pickCategory(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(ItemFormKeys.category));
  await tester.pumpAndSettle();
  // `.last` — the field renders the value too once one is chosen.
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  group('ItemFormState', () {
    test('a fresh add-item state cannot save until a type is chosen', () {
      final state = ItemFormState.blank().copyWith(
        name: 'Paprika',
        categoryId: 'dry',
        unitCost: '4.50',
      );
      expect(state.itemType, isEmpty);
      expect(state.canSave, isFalse, reason: 'no type chosen yet');
      expect(state.copyWith(itemType: 'raw_material').canSave, isTrue);
    });

    test('required fields gate saving', () {
      // itemType set throughout, as it would be after the entry choice —
      // these cases are about the *other* required fields.
      var state = ItemFormState.blank().copyWith(itemType: 'raw_material');
      expect(state.canSave, isFalse);

      state = state.copyWith(name: 'Paprika');
      expect(state.canSave, isFalse, reason: 'no category or cost yet');

      state = state.copyWith(categoryId: 'dry');
      expect(state.canSave, isFalse, reason: 'no cost yet');

      state = state.copyWith(unitCost: '4.50');
      expect(state.canSave, isTrue);
    });

    test('a blank low-stock threshold is allowed, a malformed one is not', () {
      final valid = ItemFormState.blank().copyWith(
        itemType: 'raw_material',
        name: 'Paprika',
        categoryId: 'dry',
        unitCost: '4.50',
      );

      expect(valid.copyWith(lowStockAlert: '').canSave, isTrue);
      expect(valid.copyWith(lowStockAlert: '12').canSave, isTrue);
      expect(ItemFormState.validateLowStockAlert('abc'), isNotNull);
    });

    test('untracked items skip the stock validators entirely', () {
      final state = ItemFormState.blank().copyWith(
        itemType: 'raw_material',
        name: 'Table salt',
        categoryId: 'dry',
        unitCost: '1.20',
        lowStockAlert: 'nonsense',
        reorderQuantity: 'nonsense',
        trackStock: false,
      );

      expect(state.canSave, isTrue);
      expect(state.copyWith(trackStock: true).canSave, isFalse);
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

  group('Item form dialog', () {
    testWidgets('no overflow at any target width', (tester) async {
      for (final width in _widths) {
        await pumpInventory(tester, Size(width, 900));
        await openAddForm(tester);

        expect(
          tester.takeException(),
          isNull,
          reason: 'render error at ${width}px',
        );
        expect(find.byType(ResponsiveFormDialog), findsOneWidget);
        expect(find.byType(ImageUploadField), findsOneWidget);

        // Closed before the next size: leaving the last dialog mounted at the
        // end of the test strands Riverpod's autoDispose timer.
        await tester.tap(find.byKey(ItemFormKeys.cancel));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('desktop gets a centered dialog at the form width', (
      tester,
    ) async {
      await pumpInventory(tester, const Size(1440, 900));
      await openAddForm(tester);

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);

      final box = tester.getSize(find.byKey(ResponsiveFormDialog.surfaceKey));
      expect(box.width, ItemFormDialog.dialogWidth);
      expect(box.height, lessThanOrEqualTo(900 * 0.85));

      // Two columns: the photo sits to the left of the fields, not above them.
      final photo = tester.getTopLeft(find.byType(ImageUploadField));
      final name = tester.getTopLeft(find.byKey(ItemFormKeys.name));
      expect(name.dx, greaterThan(photo.dx));
    });

    testWidgets('mobile gets a full-height sheet in one column', (
      tester,
    ) async {
      await pumpInventory(tester, const Size(390, 844));
      await openAddForm(tester);

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);

      // Stacked: the fields start below the dropzone, not beside it.
      final photo = tester.getBottomLeft(find.byType(ImageUploadField));
      final name = tester.getTopLeft(find.byKey(ItemFormKeys.name));
      expect(name.dy, greaterThan(photo.dy));

      // The footer is pinned, so the primary action is on screen without
      // scrolling the body first.
      final sheet = tester.getRect(find.byKey(ResponsiveFormDialog.surfaceKey));
      final submit = tester.getRect(find.byKey(ItemFormKeys.submit));
      expect(submit.bottom, lessThanOrEqualTo(sheet.bottom));
      expect(submit.bottom, lessThanOrEqualTo(844));
      expect(submit.height, greaterThanOrEqualTo(44));
    });

    testWidgets('the mobile footer stays above the system keyboard', (
      tester,
    ) async {
      await pumpInventory(tester, const Size(390, 844));
      await openAddForm(tester);

      final before = tester.getRect(find.byKey(ItemFormKeys.submit));

      // Raise a 320px keyboard, as focusing a field does on a real handset.
      tester.view.viewInsets = FakeViewPadding(
        bottom: 320 * tester.view.devicePixelRatio,
      );
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      final after = tester.getRect(find.byKey(ItemFormKeys.submit));
      expect(after.bottom, lessThanOrEqualTo(844 - 320));
      expect(
        after.top,
        lessThan(before.top),
        reason: 'the sheet shortens and lifts rather than sliding under it',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('edit mode pre-fills from the provider and locks stock', (
      tester,
    ) async {
      final container = await pumpInventory(tester, const Size(1440, 900));
      final target = container.read(inventorySliceProvider).items.first;

      await openEditForm(tester);

      expect(find.text('Edit item'), findsOneWidget);
      expect(find.widgetWithText(TextField, target.name), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);

      // Current stock is shown but has no input to type into.
      expect(find.text('Current stock'), findsOneWidget);
      expect(find.byKey(ItemFormKeys.stock), findsNothing);
      expect(find.text('Changes go through Stock Adjust'), findsOneWidget);
    });

    testWidgets('saving an edit updates the list and the summary cards', (
      tester,
    ) async {
      final container = await pumpInventory(tester, const Size(1440, 900));
      final target = container.read(inventorySliceProvider).items.first;

      await openEditForm(tester);
      await tester.enterText(find.byKey(ItemFormKeys.name), 'Renamed Item');
      await tester.enterText(find.byKey(ItemFormKeys.unitCost), '99.00');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ItemFormKeys.submit));
      await tester.pumpAndSettle();

      final updated = container
          .read(inventoryItemsListProvider)
          .firstWhere((item) => item.id == target.id);
      expect(updated.name, 'Renamed Item');
      expect(updated.unitCost, 99.00);
      // Same id in place, not a duplicate row.
      expect(
        container.read(inventoryItemsListProvider).where((i) => i.id == target.id),
        hasLength(1),
      );
      expect(find.byType(ResponsiveFormDialog), findsNothing);
    });

    testWidgets('the stock toggle disables the threshold field', (
      tester,
    ) async {
      await pumpInventory(tester, const Size(1440, 900));
      await openAddForm(tester);

      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(ItemFormKeys.lowStockAlert),
                matching: find.byType(TextField),
              ),
            )
            .enabled,
        isTrue,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(ItemFormKeys.lowStockAlert),
                matching: find.byType(TextField),
              ),
            )
            .enabled,
        isFalse,
      );
      // The opening-stock row goes with it.
      expect(find.byKey(ItemFormKeys.stock), findsNothing);
    });

    testWidgets('archiving is carried through to the saved item', (
      tester,
    ) async {
      final container = await pumpInventory(tester, const Size(1440, 900));

      await openAddForm(tester);
      await tester.enterText(find.byKey(ItemFormKeys.name), 'Retired Line');
      await pickCategory(tester, 'Supplies');
      await tester.enterText(find.byKey(ItemFormKeys.unitCost), '2.00');
      await tester.enterText(find.byKey(ItemFormKeys.sellingPrice), '5.00');
      // The Status section can sit below the fold in a short window.
      await tester.ensureVisible(find.text('Archived'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archived'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ItemFormKeys.submit));
      await tester.pumpAndSettle();

      final saved = container.read(inventoryItemsListProvider).first;
      expect(saved.name, 'Retired Line');
      expect(saved.isArchived, isTrue);
      expect(saved.sku, startsWith('RET-'), reason: 'SKU generated from name');
    });

    testWidgets('cancel and close both discard the edit', (tester) async {
      final container = await pumpInventory(tester, const Size(1440, 900));
      final target = container.read(inventorySliceProvider).items.first;

      await openEditForm(tester);
      await tester.enterText(find.byKey(ItemFormKeys.name), 'Discard me');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ItemFormKeys.cancel));
      await tester.pumpAndSettle();

      expect(
        container
            .read(inventoryItemsListProvider)
            .firstWhere((i) => i.id == target.id)
            .name,
        target.name,
      );

      // Reopening starts from the stored item, not the abandoned draft.
      await openEditForm(tester);
      expect(find.widgetWithText(TextField, target.name), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Discard me'), findsNothing);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(ResponsiveFormDialog), findsNothing);
    });

    testWidgets('adding on mobile reaches the same provider', (tester) async {
      final container = await pumpInventory(tester, const Size(390, 844));
      final before = container.read(inventoryItemsListProvider).length;

      await openAddForm(tester);
      await tester.enterText(find.byKey(ItemFormKeys.name), 'Pocket Item');
      await pickCategory(tester, 'Beverages');
      await tester.enterText(find.byKey(ItemFormKeys.unitCost), '3.25');
      await tester.enterText(find.byKey(ItemFormKeys.sellingPrice), '4.00');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ItemFormKeys.submit));
      await tester.pumpAndSettle();

      final items = container.read(inventoryItemsListProvider);
      expect(items, hasLength(before + 1));
      expect(items.first.name, 'Pocket Item');
      expect(items.first.categoryId, 'drinks');
      expect(container.read(inventorySummaryProvider).totalItems, before + 1);
    });
  });

  group('Item type entry choice', () {
    testWidgets('opening "Add item" leads with the chooser, not the fields', (
      tester,
    ) async {
      await pumpInventory(tester, const Size(1440, 900));
      await tester.tap(find.text('Add item'));
      await tester.pumpAndSettle();

      expect(find.text('What are you adding?'), findsOneWidget);
      expect(find.byKey(ItemFormKeys.chooseGrocery), findsOneWidget);
      expect(find.byKey(ItemFormKeys.chooseMenuItem), findsOneWidget);
      expect(find.byKey(ItemFormKeys.chooseBoth), findsOneWidget);
      // None of the ordinary fields exist yet — the choice comes first.
      expect(find.byKey(ItemFormKeys.name), findsNothing);
      // Submit is disabled until a type is picked.
      expect(
        tester.widget<FilledButton>(find.byKey(ItemFormKeys.submit)).onPressed,
        isNull,
      );
    });

    testWidgets('choosing Grocery pre-sets raw_material and leads with stock fields', (
      tester,
    ) async {
      final container = await pumpInventory(tester, const Size(1440, 900));
      await tester.tap(find.text('Add item'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ItemFormKeys.chooseGrocery));
      await tester.pumpAndSettle();

      // Stock-relevant fields are enabled and prominent.
      expect(find.byKey(ItemFormKeys.reorderQuantity), findsOneWidget);
      expect(find.byKey(ItemFormKeys.allowNegativeStock), findsOneWidget);
      expect(find.byKey(ItemFormKeys.unit), findsOneWidget);
      // Selling price is present but disabled — de-emphasised, not hidden.
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(ItemFormKeys.sellingPrice),
                matching: find.byType(TextField),
              ),
            )
            .enabled,
        isFalse,
      );

      await tester.enterText(find.byKey(ItemFormKeys.name), 'Smoked Paprika');
      await pickCategory(tester, 'Dry goods');
      await tester.enterText(find.byKey(ItemFormKeys.unitCost), '4.50');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ItemFormKeys.submit));
      await tester.pumpAndSettle();

      final saved = container
          .read(inventoryItemsListProvider)
          .firstWhere((i) => i.name == 'Smoked Paprika');
      expect(saved.itemType, 'raw_material');
      expect(saved.isGroceryItem, isTrue);
      expect(saved.isMenuCatalogItem, isFalse);
    });

    testWidgets('choosing Menu item pre-sets sellable and leads with price', (
      tester,
    ) async {
      final container = await pumpInventory(tester, const Size(1440, 900));
      await tester.tap(find.text('Add item'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ItemFormKeys.chooseMenuItem));
      await tester.pumpAndSettle();

      // Untracked by default, so the stock-only fields never render.
      expect(find.byKey(ItemFormKeys.reorderQuantity), findsNothing);
      expect(find.byKey(ItemFormKeys.allowNegativeStock), findsNothing);
      expect(find.byKey(ItemFormKeys.stock), findsNothing);
      // Selling price is enabled and prominent.
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(ItemFormKeys.sellingPrice),
                matching: find.byType(TextField),
              ),
            )
            .enabled,
        isTrue,
      );

      await tester.enterText(find.byKey(ItemFormKeys.name), 'House Salad');
      await pickCategory(tester, 'Starters');
      await tester.enterText(find.byKey(ItemFormKeys.unitCost), '2.10');
      await tester.enterText(find.byKey(ItemFormKeys.sellingPrice), '9.50');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ItemFormKeys.submit));
      await tester.pumpAndSettle();

      final saved = container
          .read(inventoryItemsListProvider)
          .firstWhere((i) => i.name == 'House Salad');
      expect(saved.itemType, 'sellable');
      expect(saved.isMenuCatalogItem, isTrue);
      expect(saved.isGroceryItem, isFalse);
      expect(saved.isSellable, isTrue);
    });

    testWidgets('choosing "both" shows every field group and saves as both', (
      tester,
    ) async {
      final container = await pumpInventory(tester, const Size(1440, 900));
      await tester.tap(find.text('Add item'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ItemFormKeys.chooseBoth));
      await tester.pumpAndSettle();

      expect(find.byKey(ItemFormKeys.reorderQuantity), findsOneWidget);
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(ItemFormKeys.sellingPrice),
                matching: find.byType(TextField),
              ),
            )
            .enabled,
        isTrue,
      );

      await tester.enterText(find.byKey(ItemFormKeys.name), 'Bottled Cola');
      await pickCategory(tester, 'Beverages');
      await tester.enterText(find.byKey(ItemFormKeys.unitCost), '0.90');
      await tester.enterText(find.byKey(ItemFormKeys.sellingPrice), '2.50');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ItemFormKeys.submit));
      await tester.pumpAndSettle();

      final saved = container
          .read(inventoryItemsListProvider)
          .firstWhere((i) => i.name == 'Bottled Cola');
      expect(saved.itemType, 'both');
      // The concrete proof a 'both' item is not forced into one view.
      expect(saved.isGroceryItem, isTrue);
      expect(saved.isMenuCatalogItem, isTrue);
    });

    testWidgets('"Change" returns to the chooser without losing other fields', (
      tester,
    ) async {
      await pumpInventory(tester, const Size(1440, 900));
      await tester.tap(find.text('Add item'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ItemFormKeys.chooseGrocery));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(ItemFormKeys.name), 'Kept Name');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ItemFormKeys.changeType));
      await tester.pumpAndSettle();
      expect(find.text('What are you adding?'), findsOneWidget);

      await tester.tap(find.byKey(ItemFormKeys.chooseMenuItem));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Kept Name'), findsOneWidget);
    });
  });
}
