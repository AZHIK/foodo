import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';

import 'package:restaurant_pos/models/inventory_item.dart';
import 'package:restaurant_pos/models/permission.dart';
import 'package:restaurant_pos/providers/inventory_provider.dart';
import 'package:restaurant_pos/providers/permissions_provider.dart';
import 'package:restaurant_pos/providers/production_provider.dart';
import 'package:restaurant_pos/screens/inventory/menu_item_detail_screen.dart';
import 'package:restaurant_pos/services/inventory_api_service.dart';
import 'package:restaurant_pos/theme/app_theme.dart';
import 'package:restaurant_pos/utils/formatters.dart';

import 'test_helpers/test_container.dart';

/// An untracked prepared-to-order dish backed by a backend item — the exact
/// line the recipe actions exist for, and the one the tracked-stock guard
/// used to swallow whole.
InventoryItem untrackedDish() => const InventoryItem(
      id: 'inv-99',
      sku: 'MNU-9999',
      name: 'Pilau Plate',
      categoryId: 'mains',
      emoji: '🍚',
      stock: 0,
      reorderLevel: 0,
      unitCost: 4.2,
      trackStock: false,
      catalogItemId: 'backend-pilau',
      itemType: 'sellable',
    );

class _EmptyCatalog extends RecipesCatalogNotifier {
  @override
  Future<List<RecipeDto>> build() async => const [];
}

Future<void> pumpDetail(
  WidgetTester tester, {
  Set<String> permissions = const {},
}) async {
  final container = newTestContainer(
    extraOverrides: [
      inventoryItemsListProvider.overrideWithValue([untrackedDish()]),
      recipesCatalogProvider.overrideWith(_EmptyCatalog.new),
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
        home: const MenuItemDetailScreen(itemId: 'inv-99'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('MenuItemDetailScreen recipe actions', () {
    testWidgets('an untracked dish still offers Add recipe', (tester) async {
      await pumpDetail(tester, permissions: {AppPermissions.recipesCreate});

      // Production and recipe actions live outside any stock guard: the
      // items being made are very often untracked prepared-to-order lines.
      expect(find.text('Add recipe'), findsOneWidget);
      // No stock operations on a menu-item screen at all.
      expect(find.text('Adjust stock'), findsNothing);
    });

    testWidgets('no button without the permission', (tester) async {
      await pumpDetail(tester);

      expect(find.text('Add recipe'), findsNothing);
      expect(find.text('Edit recipe'), findsNothing);
    });

    testWidgets('the Cost tile values the dish at its recipe cost', (
      tester,
    ) async {
      final container = newTestContainer(
        extraOverrides: [
          inventoryItemsListProvider.overrideWithValue([untrackedDish()]),
          recipesCatalogListProvider.overrideWithValue([
            RecipeDto(
              id: 'recipe-1',
              businessId: 'biz-1',
              sellableItemId: 'backend-pilau',
              sellableItemName: 'Pilau Plate',
              name: 'Pilau',
              targetYieldQuantity: Decimal.fromInt(1),
              totalCost: Decimal.parse('2.00'),
              costPerUnit: Decimal.parse('2.00'),
              costComplete: true,
              createdAt: DateTime.utc(2026, 1, 1),
              updatedAt: DateTime.utc(2026, 1, 1),
              components: const [],
            ),
          ]),
          hasPermissionProvider.overrideWith((ref, code) => false),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const MenuItemDetailScreen(itemId: 'inv-99'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Recipe raw materials (2.00), not the line's own unit cost (4.20).
      expect(find.text('COST'), findsOneWidget);
      expect(find.text(Fmt.money(2.0)), findsWidgets);
    });

    testWidgets('the Cost tile falls back to unit cost with no recipe', (
      tester,
    ) async {
      await pumpDetail(tester, permissions: {AppPermissions.recipesCreate});

      expect(find.text('COST'), findsOneWidget);
      expect(find.text(Fmt.money(4.2)), findsWidgets);
    });
  });
}
