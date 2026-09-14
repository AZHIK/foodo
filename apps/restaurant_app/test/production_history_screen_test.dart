import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/models/permission.dart';
import 'package:restaurant_pos/providers/permissions_provider.dart';
import 'package:restaurant_pos/providers/production_provider.dart';
import 'package:restaurant_pos/screens/inventory/production_history_screen.dart';
import 'package:restaurant_pos/screens/inventory/record_production_dialog.dart';
import 'package:restaurant_pos/services/inventory_api_service.dart';
import 'package:restaurant_pos/theme/app_theme.dart';

import 'test_helpers/test_container.dart';

ProductionEventDto productionEvent({
  String id = 'e1',
  String suggested = '10.000',
  String actual = '8.000',
}) =>
    ProductionEventDto(
      id: id,
      businessId: 'biz-1',
      storeId: 'store-1',
      recipeId: 'recipe-1',
      recipeName: 'Pilau',
      sellableItemId: 'sellable-1',
      sellableItemName: 'Pilau',
      leadingComponentItemId: 'rice',
      leadingQuantityUsed: Decimal.parse('2.000'),
      suggestedOutputQuantity: Decimal.parse(suggested),
      actualOutputQuantity: Decimal.parse(actual),
      occurredAt: DateTime.utc(2026, 9, 14, 7),
      createdAt: DateTime.utc(2026, 9, 14, 7),
      components: [
        ProductionComponentDto(
          id: 'c1',
          rawMaterialItemId: 'rice',
          rawMaterialName: 'Rice',
          rawMaterialUnit: 'kg',
          quantityConsumed: Decimal.parse('2.000'),
        ),
      ],
    );

RecipeDto pilauRecipeDto() => RecipeDto(
      id: 'recipe-1',
      businessId: 'biz-1',
      sellableItemId: 'sellable-1',
      sellableItemName: 'Pilau',
      name: 'Pilau',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      components: [
        RecipeIngredientDto(
          rawMaterialItemId: 'rice',
          rawMaterialName: 'Rice',
          rawMaterialUnit: 'kg',
          quantityRequired: Decimal.parse('0.2'),
        ),
      ],
    );

/// Pumps the history screen with the ledger, catalog and permissions
/// overridden — no business context needed since nothing here fetches.
Future<void> pumpHistory(
  WidgetTester tester, {
  List<ProductionEventDto> events = const [],
  List<RecipeDto> recipes = const [],
  Set<String> permissions = const {},
}) async {
  final container = newTestContainer(
    extraOverrides: [
      productionHistoryListProvider.overrideWithValue(events),
      recipesCatalogListProvider.overrideWithValue(recipes),
      hasPermissionProvider.overrideWith(
        (ref, code) => permissions.contains(code),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const ProductionHistoryScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ProductionHistoryScreen', () {
    testWidgets('an adjusted run shows its badge and detail', (tester) async {
      await pumpHistory(tester, events: [productionEvent()]);

      expect(find.text('Pilau'), findsWidgets);
      expect(find.text('Adjusted'), findsOneWidget);

      await tester.tap(find.text('Pilau').first);
      await tester.pumpAndSettle();

      // Detail keeps suggested and actual apart.
      expect(find.text('Output'), findsOneWidget);
      expect(find.textContaining('under'), findsOneWidget);
      expect(find.text('Rice'), findsWidgets);
    });

    testWidgets('the record action needs the permission', (tester) async {
      await pumpHistory(tester);

      expect(
        find.byKey(const Key('productionHistory.record')),
        findsNothing,
      );
    });

    testWidgets('record flows through the recipe picker', (tester) async {
      await pumpHistory(
        tester,
        recipes: [pilauRecipeDto()],
        permissions: {AppPermissions.productionCreate},
      );

      await tester.tap(find.byKey(const Key('productionHistory.record')));
      await tester.pumpAndSettle();
      expect(find.text('What are you making?'), findsOneWidget);

      await tester.tap(find.text('Pilau').first);
      await tester.pumpAndSettle();

      // The picker hands off to the record dialog for the chosen recipe.
      expect(find.text('What are you making?'), findsNothing);
      expect(find.byKey(ProductionDialogKeys.leadingQty), findsOneWidget);
    });

    testWidgets('an empty catalog explains itself in the picker', (
      tester,
    ) async {
      await pumpHistory(
        tester,
        permissions: {AppPermissions.productionCreate},
      );

      await tester.tap(find.byKey(const Key('productionHistory.record')));
      await tester.pumpAndSettle();

      expect(find.textContaining('No recipes yet'), findsOneWidget);
    });
  });
}
