import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/models/inventory_item.dart';
import 'package:restaurant_pos/models/permission.dart';
import 'package:restaurant_pos/providers/inventory_provider.dart';
import 'package:restaurant_pos/providers/permissions_provider.dart';
import 'package:restaurant_pos/providers/production_provider.dart';
import 'package:restaurant_pos/screens/inventory/item_detail_screen.dart';
import 'package:restaurant_pos/services/inventory_api_service.dart';
import 'package:restaurant_pos/theme/app_theme.dart';

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
        home: const ItemDetailScreen(itemId: 'inv-99'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ItemDetailScreen recipe actions', () {
    testWidgets('an untracked dish still offers Add recipe', (tester) async {
      await pumpDetail(tester, permissions: {AppPermissions.recipesCreate});

      // The regression: the tracked-stock early return used to hide the
      // entire actions row for untracked lines, so sellables never showed
      // the button groceries did.
      expect(find.text('Add recipe'), findsOneWidget);
      expect(find.text('Adjust stock'), findsNothing);
    });

    testWidgets('no button without the permission', (tester) async {
      await pumpDetail(tester);

      expect(find.text('Add recipe'), findsNothing);
      expect(find.text('Edit recipe'), findsNothing);
    });
  });
}
