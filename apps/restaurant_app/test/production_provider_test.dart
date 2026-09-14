import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/providers/production_provider.dart';
import 'package:restaurant_pos/services/inventory_api_service.dart';

import 'test_helpers/test_container.dart';

void main() {
  group('production providers without a business context', () {
    test('history and catalog are empty, recording is impossible', () async {
      final container = newTestContainer();

      expect(container.read(productionHistoryListProvider), isEmpty);
      expect(container.read(recipesCatalogListProvider), isEmpty);

      await expectLater(
        container.read(productionHistoryProvider.notifier).recordProduction(
              recipeId: 'r1',
              leadingItemId: 'rice',
              leadingQuantity: 2,
            ),
        throwsStateError,
      );
    });

    test('the date filter sets and clears', () {
      final container = newTestContainer();
      final notifier = container.read(productionDateFilterProvider.notifier);

      final from = DateTime.utc(2026, 9, 1);
      final to = DateTime.utc(2026, 9, 30);
      notifier.setRange(from, to);
      expect(container.read(productionDateFilterProvider).from, from);
      expect(container.read(productionDateFilterProvider).to, to);

      notifier.clear();
      expect(container.read(productionDateFilterProvider).from, isNull);
      expect(container.read(productionDateFilterProvider).to, isNull);
    });
    test('recipe writes are impossible without a business context', () async {
      final container = newTestContainer();
      final notifier = container.read(recipesCatalogProvider.notifier);
      final input = RecipeComponentInput(
        rawMaterialItemId: 'rice',
        quantityRequired: Decimal.parse('0.2'),
      );

      await expectLater(
        notifier.createRecipe(sellableItemId: 's1', components: [input]),
        throwsStateError,
      );
      await expectLater(
        notifier.updateRecipe(recipeId: 'r1', components: [input]),
        throwsStateError,
      );
      await expectLater(
        notifier.deleteRecipe('r1'),
        throwsStateError,
      );
    });
  });
}
