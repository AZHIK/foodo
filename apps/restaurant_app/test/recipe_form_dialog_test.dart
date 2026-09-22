import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/models/inventory_item.dart';
import 'package:restaurant_pos/providers/inventory_provider.dart';
import 'package:restaurant_pos/screens/inventory/recipe_form_dialog.dart';
import 'package:restaurant_pos/services/inventory_api_service.dart';
import 'package:restaurant_pos/theme/app_theme.dart';

import 'test_helpers/test_container.dart';

InventoryItem stockItem({
  required String id,
  required String name,
  String unit = 'kg',
  String itemType = 'raw_material',
}) =>
    InventoryItem(
      id: id,
      sku: 'SKU-$id',
      name: name,
      categoryId: 'dry',
      emoji: '📦',
      stock: 10,
      reorderLevel: 2,
      unitCost: 1,
      unit: unit,
      catalogItemId: 'backend-$id',
      itemType: itemType,
    );

RecipeDto pilauRecipeDto() => RecipeDto(
      id: 'recipe-1',
      businessId: 'biz-1',
      sellableItemId: 'backend-pizza',
      sellableItemName: 'Pilau',
      name: 'Pilau',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      components: [
        RecipeIngredientDto(
          rawMaterialItemId: 'backend-rice',
          rawMaterialName: 'Rice',
          rawMaterialUnit: 'kg',
          quantityRequired: Decimal.parse('0.2'),
        ),
        RecipeIngredientDto(
          rawMaterialItemId: 'backend-meat',
          rawMaterialName: 'Meat',
          rawMaterialUnit: 'kg',
          quantityRequired: Decimal.parse('0.1'),
        ),
      ],
    );

/// Pumps the recipe form with the grocery picker overridden — the dialog
/// reads real providers, and demo-mode mock items carry no backend ids, so
/// tests supply their own pickable lines.
Future<ProviderContainer> pumpForm(
  WidgetTester tester, {
  InventoryItem? sellable,
  RecipeDto? recipe,
  List<InventoryItem> groceries = const [],
}) async {
  final container = newTestContainer(
    extraOverrides: [
      groceryItemsProvider.overrideWithValue(groceries),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showRecipeFormDialog(
                context,
                sellable: sellable,
                recipe: recipe,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return container;
}

List<InventoryItem> get demoGroceries => [
      stockItem(id: 'rice', name: 'Rice'),
      stockItem(id: 'meat', name: 'Meat'),
    ];

/// Taps a control that may sit below the fold: the form body scrolls by
/// design (longer since batch-yield fields joined it), so tests bring the
/// target into view before tapping instead of assuming it is visible.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('RecipeFormDialog edit mode', () {
    testWidgets('pre-fills name and rows; submit is live', (tester) async {
      await pumpForm(
        tester,
        recipe: pilauRecipeDto(),
        groceries: demoGroceries,
      );

      expect(find.widgetWithText(TextField, 'Pilau'), findsOneWidget);
      expect(find.byKey(RecipeFormKeys.ingredientQty(0)), findsOneWidget);
      expect(find.byKey(RecipeFormKeys.ingredientQty(1)), findsOneWidget);
      expect(find.byKey(RecipeFormKeys.ingredientQty(2)), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.byKey(RecipeFormKeys.submit))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('clearing every quantity disables submit', (tester) async {
      await pumpForm(
        tester,
        recipe: pilauRecipeDto(),
        groceries: demoGroceries,
      );

      await tester.enterText(find.byKey(RecipeFormKeys.ingredientQty(0)), '');
      await tester.enterText(find.byKey(RecipeFormKeys.ingredientQty(1)), '');
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<FilledButton>(find.byKey(RecipeFormKeys.submit))
            .onPressed,
        isNull,
      );
    });

    testWidgets('rows can be added and removed', (tester) async {
      await pumpForm(
        tester,
        recipe: pilauRecipeDto(),
        groceries: demoGroceries,
      );

      await tapVisible(tester, find.byKey(RecipeFormKeys.addIngredient));
      expect(find.byKey(RecipeFormKeys.ingredientQty(2)), findsOneWidget);

      await tapVisible(
          tester, find.byKey(RecipeFormKeys.removeIngredient(2)));
      expect(find.byKey(RecipeFormKeys.ingredientQty(2)), findsNothing);
    });

    testWidgets('a duplicated ingredient is rejected', (tester) async {
      await pumpForm(
        tester,
        recipe: pilauRecipeDto(),
        groceries: demoGroceries,
      );

      // Second row currently Meat — switch it to Rice as well.
      await tapVisible(tester, find.byKey(RecipeFormKeys.ingredientItem(1)));
      await tester.tap(find.text('Rice (kg)').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('only once'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(RecipeFormKeys.submit))
            .onPressed,
        isNull,
      );
    });

    testWidgets('submitting without a backend shows the error', (
      tester,
    ) async {
      await pumpForm(
        tester,
        recipe: pilauRecipeDto(),
        groceries: demoGroceries,
      );

      await tester.tap(find.byKey(RecipeFormKeys.submit));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not save'), findsOneWidget);
    });

    testWidgets('delete asks first and keeps on cancel', (tester) async {
      await pumpForm(
        tester,
        recipe: pilauRecipeDto(),
        groceries: demoGroceries,
      );

      await tester.tap(find.byKey(RecipeFormKeys.delete));
      await tester.pumpAndSettle();
      expect(find.text('Delete this recipe?'), findsOneWidget);

      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this recipe?'), findsNothing);
      // The form itself is still open.
      expect(find.byKey(RecipeFormKeys.submit), findsOneWidget);
    });
  });

  group('RecipeFormDialog add mode', () {
    testWidgets('submit waits for a sellable, an item and a qty', (
      tester,
    ) async {
      await pumpForm(
        tester,
        sellable: stockItem(id: 'pizza', name: 'Pilau', itemType: 'both'),
        groceries: demoGroceries,
      );

      expect(find.text('Add recipe'), findsWidgets);
      expect(
        tester
            .widget<FilledButton>(find.byKey(RecipeFormKeys.submit))
            .onPressed,
        isNull,
        reason: 'nothing picked yet',
      );

      await tapVisible(tester, find.byKey(RecipeFormKeys.ingredientItem(0)));
      await tester.tap(find.text('Rice (kg)').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(RecipeFormKeys.ingredientQty(0)),
        '0.2',
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<FilledButton>(find.byKey(RecipeFormKeys.submit))
            .onPressed,
        isNotNull,
      );
      expect(find.byKey(RecipeFormKeys.delete), findsNothing);
    });
  });
}
