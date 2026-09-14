import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/providers/production_provider.dart';
import 'package:restaurant_pos/services/inventory_api_service.dart';

RecipeDto pilauRecipe() => RecipeDto(
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
        RecipeIngredientDto(
          rawMaterialItemId: 'meat',
          rawMaterialName: 'Meat',
          rawMaterialUnit: 'kg',
          quantityRequired: Decimal.parse('0.1'),
        ),
      ],
    );

void main() {
  group('ProductionPreview', () {
    test('computes the ratio and every consumption from the leading qty', () {
      final preview = ProductionPreview.of(
        recipe: pilauRecipe(),
        leadingItemId: 'rice',
        leadingQty: 2,
      )!;

      // 2kg ÷ 0.2kg per plate = 10 plates; meat follows the same ratio.
      expect(preview.ratio, 10);
      expect(preview.suggestedOutput, 10);
      expect(preview.consumedByItemId['rice'], 2);
      expect(preview.consumedByItemId['meat'], closeTo(1, 0.0001));
    });

    test('the leading entry is the typed value, never ratio-rounded', () {
      final preview = ProductionPreview.of(
        recipe: pilauRecipe(),
        leadingItemId: 'meat',
        leadingQty: 0.35,
      )!;

      expect(preview.consumedByItemId['meat'], 0.35);
      expect(preview.suggestedOutput, closeTo(3.5, 0.0001));
    });

    test('returns null when no preview is possible', () {
      final recipe = pilauRecipe();
      expect(
        ProductionPreview.of(
          recipe: recipe,
          leadingItemId: 'sugar',
          leadingQty: 2,
        ),
        isNull,
        reason: 'unknown ingredient',
      );
      expect(
        ProductionPreview.of(
          recipe: recipe,
          leadingItemId: 'rice',
          leadingQty: 0,
        ),
        isNull,
        reason: 'empty quantity',
      );
      expect(
        ProductionPreview.of(
          recipe: recipe,
          leadingItemId: 'rice',
          leadingQty: -1,
        ),
        isNull,
        reason: 'negative quantity',
      );
    });
  });

  group('production DTOs', () {
    test('RecipeDto parses a Stage 1 list response', () {
      final dto = RecipeDto.fromJson({
        'id': 'r1',
        'business_id': 'b1',
        'sellable_item_id': 's1',
        'sellable_item_name': 'Pilau',
        'name': 'Pilau',
        'created_at': '2026-09-14T07:00:00Z',
        'updated_at': '2026-09-14T07:00:00Z',
        'components': [
          {
            'raw_material_item_id': 'rice',
            'raw_material_name': 'Rice',
            'raw_material_unit': 'kg',
            'quantity_required': '0.200',
          },
        ],
      });

      expect(dto.sellableItemName, 'Pilau');
      expect(dto.components, hasLength(1));
      expect(dto.components.first.quantityRequired, Decimal.parse('0.2'));
    });

    test('ProductionEventDto keeps suggested and actual apart', () {
      final dto = ProductionEventDto.fromJson({
        'id': 'e1',
        'business_id': 'b1',
        'store_id': 'st1',
        'recipe_id': 'r1',
        'recipe_name': 'Pilau',
        'sellable_item_id': 's1',
        'sellable_item_name': 'Pilau',
        'leading_component_item_id': 'rice',
        'leading_quantity_used': '2.000',
        'suggested_output_quantity': '10.000',
        'actual_output_quantity': '8.000',
        'actor_id': null,
        'occurred_at': '2026-09-14T07:00:00Z',
        'created_at': '2026-09-14T07:00:00Z',
        'components': [
          {
            'id': 'c1',
            'recipe_id': 'r1',
            'raw_material_item_id': 'rice',
            'raw_material_name': 'Rice',
            'raw_material_unit': 'kg',
            'quantity_consumed': '2.000',
          },
        ],
      });

      // The gap is the over-portioning signal — both must survive parsing.
      expect(dto.suggestedOutputQuantity, Decimal.parse('10'));
      expect(dto.actualOutputQuantity, Decimal.parse('8'));
      expect(dto.components.first.rawMaterialUnit, 'kg');
    });
  });

  group('ProductionDateFilter', () {
    test('copyWith keeps the untouched end', () {
      const filter = ProductionDateFilter();
      final from = DateTime.utc(2026, 9, 1);
      final ranged = filter.copyWith(from: from);
      expect(ranged.from, from);
      expect(ranged.to, isNull);
    });
  });
}
