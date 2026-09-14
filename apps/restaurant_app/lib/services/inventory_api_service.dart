/// Write-side API client for Inventory Service — item CRUD and stock
/// operations (adjust/waste/transfer).
///
/// Unlike `sync/inventory_catalog_api.dart` (a pluggable Fake/Http pair for
/// the read-side catalog pull), this is a plain Dio-wrapping class, matching
/// `StoreApiService`/`BusinessApiService` — there is no offline/demo mode for
/// writes; every call here requires connectivity.
library;

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';

import '../sync/inventory_catalog_api.dart' show CatalogItemDto;

/// A single stock movement, as returned by the adjust/waste/transfer
/// endpoints. This is an audit-trail record, not a stock level — callers
/// that need the item's new on-hand quantity must re-sync stock levels
/// after a successful write (see `CatalogSyncService.syncStockLevels`).
class StockMovementDto {
  final String id;
  final String itemId;
  final String businessId;
  final String storeId;
  final Decimal quantityDelta;
  final String movementType;
  final String? reason;
  final DateTime createdAt;

  StockMovementDto({
    required this.id,
    required this.itemId,
    required this.businessId,
    required this.storeId,
    required this.quantityDelta,
    required this.movementType,
    this.reason,
    required this.createdAt,
  });

  factory StockMovementDto.fromJson(Map<String, dynamic> json) => StockMovementDto(
        id: json['id'] as String,
        itemId: json['item_id'] as String,
        businessId: json['business_id'] as String,
        storeId: json['store_id'] as String,
        quantityDelta: Decimal.parse(json['quantity_delta'].toString()),
        movementType: json['movement_type'] as String,
        reason: json['reason'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// Thrown when the backend rejects a write with a domain-specific error
/// (insufficient stock, item-type mismatch, validation) — callers can show
/// [message] directly rather than a generic "something went wrong".
class InventoryApiException implements Exception {
  final String message;
  final int? statusCode;

  InventoryApiException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'InventoryApiException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

/// One ingredient line of a recipe, with resolved item details.
class RecipeIngredientDto {
  final String rawMaterialItemId;
  final String rawMaterialName;
  final String rawMaterialUnit;
  final Decimal quantityRequired;

  RecipeIngredientDto({
    required this.rawMaterialItemId,
    required this.rawMaterialName,
    required this.rawMaterialUnit,
    required this.quantityRequired,
  });

  factory RecipeIngredientDto.fromJson(Map<String, dynamic> json) =>
      RecipeIngredientDto(
        rawMaterialItemId: json['raw_material_item_id'] as String,
        rawMaterialName: json['raw_material_name'] as String,
        rawMaterialUnit: json['raw_material_unit'] as String? ?? '',
        quantityRequired: Decimal.parse(
          json['quantity_required'].toString(),
        ),
      );
}

/// One ingredient line on a recipe create/update payload: just the raw
/// item id and the quantity in that item's own unit.
class RecipeComponentInput {
  RecipeComponentInput({
    required this.rawMaterialItemId,
    required this.quantityRequired,
  });

  final String rawMaterialItemId;
  final Decimal quantityRequired;

  Map<String, dynamic> toJson() => {
        'raw_material_item_id': rawMaterialItemId,
        'quantity_required': quantityRequired.toString(),
      };
}

/// A recipe header with its full ingredient set.
class RecipeDto {
  final String id;
  final String businessId;
  final String sellableItemId;
  final String sellableItemName;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RecipeIngredientDto> components;

  RecipeDto({
    required this.id,
    required this.businessId,
    required this.sellableItemId,
    required this.sellableItemName,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.components,
  });

  factory RecipeDto.fromJson(Map<String, dynamic> json) => RecipeDto(
        id: json['id'] as String,
        businessId: json['business_id'] as String,
        sellableItemId: json['sellable_item_id'] as String,
        sellableItemName: json['sellable_item_name'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        components: (json['components'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(RecipeIngredientDto.fromJson)
            .toList(),
      );
}

/// One ingredient consumed by a production event, with resolved item details.
class ProductionComponentDto {
  final String id;
  final String rawMaterialItemId;
  final String rawMaterialName;
  final String rawMaterialUnit;
  final Decimal quantityConsumed;

  ProductionComponentDto({
    required this.id,
    required this.rawMaterialItemId,
    required this.rawMaterialName,
    required this.rawMaterialUnit,
    required this.quantityConsumed,
  });

  factory ProductionComponentDto.fromJson(Map<String, dynamic> json) =>
      ProductionComponentDto(
        id: json['id'] as String,
        rawMaterialItemId: json['raw_material_item_id'] as String,
        rawMaterialName: json['raw_material_name'] as String,
        rawMaterialUnit: json['raw_material_unit'] as String? ?? '',
        quantityConsumed: Decimal.parse(json['quantity_consumed'].toString()),
      );
}

/// A recorded production run: measured input plus suggested vs actual output.
class ProductionEventDto {
  final String id;
  final String businessId;
  final String storeId;
  final String recipeId;
  final String recipeName;
  final String sellableItemId;
  final String sellableItemName;
  final String leadingComponentItemId;
  final Decimal leadingQuantityUsed;
  final Decimal suggestedOutputQuantity;
  final Decimal actualOutputQuantity;
  final String? actorId;
  final DateTime occurredAt;
  final DateTime createdAt;
  final List<ProductionComponentDto> components;

  ProductionEventDto({
    required this.id,
    required this.businessId,
    required this.storeId,
    required this.recipeId,
    required this.recipeName,
    required this.sellableItemId,
    required this.sellableItemName,
    required this.leadingComponentItemId,
    required this.leadingQuantityUsed,
    required this.suggestedOutputQuantity,
    required this.actualOutputQuantity,
    this.actorId,
    required this.occurredAt,
    required this.createdAt,
    required this.components,
  });

  factory ProductionEventDto.fromJson(Map<String, dynamic> json) =>
      ProductionEventDto(
        id: json['id'] as String,
        businessId: json['business_id'] as String,
        storeId: json['store_id'] as String,
        recipeId: json['recipe_id'] as String,
        recipeName: json['recipe_name'] as String,
        sellableItemId: json['sellable_item_id'] as String,
        sellableItemName: json['sellable_item_name'] as String,
        leadingComponentItemId: json['leading_component_item_id'] as String,
        leadingQuantityUsed: Decimal.parse(
          json['leading_quantity_used'].toString(),
        ),
        suggestedOutputQuantity: Decimal.parse(
          json['suggested_output_quantity'].toString(),
        ),
        actualOutputQuantity: Decimal.parse(
          json['actual_output_quantity'].toString(),
        ),
        actorId: json['actor_id'] as String?,
        occurredAt: DateTime.parse(json['occurred_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        components: (json['components'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(ProductionComponentDto.fromJson)
            .toList(),
      );
}

class InventoryApiService {
  const InventoryApiService({required this._dio});

  final Dio _dio;

  CatalogItemDto _itemFromJson(Map<String, dynamic> item) => CatalogItemDto(
        id: item['id'] as String,
        businessId: item['business_id'] as String,
        storeId: item['store_id'] as String,
        name: item['name'] as String,
        unitId: item['unit_id'] as String?,
        category: item['category_id'] as String?,
        reorderThreshold: Decimal.parse(item['reorder_threshold'].toString()),
        reorderQuantity: Decimal.parse(item['reorder_quantity'].toString()),
        sellingPrice: item['selling_price'] != null
            ? Decimal.parse(item['selling_price'].toString())
            : null,
        unitCost:
            item['unit_cost'] != null ? Decimal.parse(item['unit_cost'].toString()) : null,
        allowNegativeStock: item['allow_negative_stock'] as bool? ?? false,
        itemType: item['item_type'] as String,
        isActive: item['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(item['created_at'] as String),
        updatedAt: DateTime.parse(item['updated_at'] as String),
      );

  Never _rethrowAsInventoryError(DioException e) {
    final detail = e.response?.data is Map
        ? (e.response?.data as Map)['detail']
        : null;
    throw InventoryApiException(
      detail?.toString() ?? e.message ?? 'Request failed',
      e.response?.statusCode,
    );
  }

  /// Creates a new item. Requires `inventory.items.create`.
  /// [initialQuantity] is the opening on-hand stock — sent as
  /// `initial_quantity` so the backend can create the stock level +
  /// audit movement atomically with the item.
  Future<CatalogItemDto> createItem({
    required String businessId,
    required String storeId,
    required String name,
    required String unitId,
    required String itemType,
    required Decimal reorderThreshold,
    required Decimal reorderQuantity,
    String? categoryId,
    Decimal? sellingPrice,
    Decimal? unitCost,
    bool allowNegativeStock = false,
    Decimal? initialQuantity,
  }) async {
    try {
      final response = await _dio.post(
        '/businesses/$businessId/items',
        data: {
          'store_id': storeId,
          'name': name,
          'unit_id': unitId,
          'item_type': itemType,
          'reorder_threshold': reorderThreshold.toString(),
          'reorder_quantity': reorderQuantity.toString(),
          if (categoryId != null) 'category_id': categoryId,
          if (sellingPrice != null) 'selling_price': sellingPrice.toString(),
          if (unitCost != null) 'unit_cost': unitCost.toString(),
          'allow_negative_stock': allowNegativeStock,
          if (initialQuantity != null)
            'initial_quantity': initialQuantity.toString(),
        },
      );
      return _itemFromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _rethrowAsInventoryError(e);
    }
  }

  /// Updates mutable fields on an item (partial update). Requires
  /// `inventory.items.update`. Only non-null parameters are sent.
  Future<CatalogItemDto> updateItem({
    required String businessId,
    required String itemId,
    String? name,
    String? unitId,
    String? categoryId,
    Decimal? reorderThreshold,
    Decimal? reorderQuantity,
    Decimal? sellingPrice,
    Decimal? unitCost,
    bool? allowNegativeStock,
    String? itemType,
  }) async {
    try {
      final response = await _dio.patch(
        '/businesses/$businessId/items/$itemId',
        data: {
          if (name != null) 'name': name,
          if (unitId != null) 'unit_id': unitId,
          if (categoryId != null) 'category_id': categoryId,
          if (reorderThreshold != null) 'reorder_threshold': reorderThreshold.toString(),
          if (reorderQuantity != null) 'reorder_quantity': reorderQuantity.toString(),
          if (sellingPrice != null) 'selling_price': sellingPrice.toString(),
          if (unitCost != null) 'unit_cost': unitCost.toString(),
          if (allowNegativeStock != null) 'allow_negative_stock': allowNegativeStock,
          if (itemType != null) 'item_type': itemType,
        },
      );
      return _itemFromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _rethrowAsInventoryError(e);
    }
  }

  /// Soft-deactivates an item. Requires `inventory.items.deactivate`.
  Future<void> deactivateItem({
    required String businessId,
    required String itemId,
  }) async {
    try {
      await _dio.delete('/businesses/$businessId/items/$itemId');
    } on DioException catch (e) {
      _rethrowAsInventoryError(e);
    }
  }

  /// Manually adjusts stock by a positive or negative delta. Requires
  /// `inventory.adjust`. [reason] must be at least 3 characters — the
  /// backend rejects anything shorter with a 422.
  Future<StockMovementDto> adjustStock({
    required String businessId,
    required String itemId,
    required Decimal quantityDelta,
    required String reason,
  }) async {
    try {
      final response = await _dio.post(
        '/businesses/$businessId/items/$itemId/adjust',
        data: {'quantity_delta': quantityDelta.toString(), 'reason': reason},
      );
      return StockMovementDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _rethrowAsInventoryError(e);
    }
  }

  /// Records wasted/spoiled stock. Requires `inventory.waste.record`.
  /// [quantity] must be positive — the backend negates it internally.
  Future<StockMovementDto> recordWaste({
    required String businessId,
    required String itemId,
    required Decimal quantity,
    required String reason,
  }) async {
    try {
      final response = await _dio.post(
        '/businesses/$businessId/items/$itemId/waste',
        data: {'quantity': quantity.toString(), 'reason': reason},
      );
      return StockMovementDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _rethrowAsInventoryError(e);
    }
  }

  /// Transfers stock between two stores within the same business. Requires
  /// `inventory.transfer`. [sourceStoreId] and [destinationStoreId] must
  /// differ — the backend rejects a self-transfer with a 422.
  Future<List<StockMovementDto>> transferStock({
    required String businessId,
    required String itemId,
    required String sourceStoreId,
    required String destinationStoreId,
    required Decimal quantity,
  }) async {
    try {
      final response = await _dio.post(
        '/businesses/$businessId/transfer',
        data: {
          'item_id': itemId,
          'source_store_id': sourceStoreId,
          'destination_store_id': destinationStoreId,
          'quantity': quantity.toString(),
        },
      );
      return (response.data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(StockMovementDto.fromJson)
          .toList();
    } on DioException catch (e) {
      _rethrowAsInventoryError(e);
    }
  }

  /// Records a production run against a recipe. Requires `production.create`.
  /// [actualOutputQuantity] is optional — omit it and the server commits the
  /// computed suggestion, so callers never have to echo it back.
  Future<ProductionEventDto> recordProduction({
    required String businessId,
    required String recipeId,
    required String leadingItemId,
    required Decimal leadingQuantityUsed,
    Decimal? actualOutputQuantity,
  }) async {
    try {
      final response = await _dio.post(
        '/businesses/$businessId/recipes/$recipeId/produce',
        data: {
          'leading_item_id': leadingItemId,
          'leading_quantity_used': leadingQuantityUsed.toString(),
          if (actualOutputQuantity != null)
            'actual_output_quantity': actualOutputQuantity.toString(),
        },
      );
      return ProductionEventDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _rethrowAsInventoryError(e);
    }
  }

  /// Lists production history, newest first. Requires `production.view`.
  /// [from]/[to] are calendar dates (inclusive) on the event's occurred time.
  Future<List<ProductionEventDto>> fetchProductionEvents({
    required String businessId,
    DateTime? from,
    DateTime? to,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/businesses/$businessId/production-events',
        queryParameters: {
          if (from != null) 'from': _isoDate(from),
          if (to != null) 'to': _isoDate(to),
          'limit': limit,
          'offset': offset,
        },
      );
      return (response.data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(ProductionEventDto.fromJson)
          .toList();
    } on DioException catch (e) {
      _rethrowAsInventoryError(e);
    }
  }

  /// Full detail for one production event. Requires `production.view`.
  Future<ProductionEventDto> fetchProductionEvent({
    required String businessId,
    required String eventId,
  }) async {
    try {
      final response = await _dio.get(
        '/businesses/$businessId/production-events/$eventId',
      );
      return ProductionEventDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _rethrowAsInventoryError(e);
    }
  }

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Lists this business's recipes with resolved ingredients.
  /// Requires `recipes.view`.
  Future<List<RecipeDto>> fetchRecipes({
    required String businessId,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/businesses/$businessId/recipes',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      return (response.data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(RecipeDto.fromJson)
          .toList();
    } on DioException catch (e) {
      _rethrowAsInventoryError(e);
    }
  }

  /// Creates a recipe for a sellable item. Requires `recipes.create`.
  /// At least one component is required — the backend rejects an empty set.
  Future<RecipeDto> createRecipe({
    required String businessId,
    required String sellableItemId,
    String? name,
    required List<RecipeComponentInput> components,
  }) async {
    try {
      final response = await _dio.post(
        '/businesses/$businessId/recipes',
        data: {
          'sellable_item_id': sellableItemId,
          if (name != null) 'name': name,
          'components': [for (final c in components) c.toJson()],
        },
      );
      return RecipeDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _rethrowAsInventoryError(e);
    }
  }

  /// Replaces a recipe's component list as a full set (plus optional rename).
  /// Requires `recipes.update`. Lines absent from [components] are deleted.
  Future<RecipeDto> updateRecipe({
    required String businessId,
    required String recipeId,
    String? name,
    required List<RecipeComponentInput> components,
  }) async {
    try {
      final response = await _dio.patch(
        '/businesses/$businessId/recipes/$recipeId',
        data: {
          if (name != null) 'name': name,
          'components': [for (final c in components) c.toJson()],
        },
      );
      return RecipeDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _rethrowAsInventoryError(e);
    }
  }

  /// Hard-deletes a recipe. Requires `recipes.delete`. Refused with a 409
  /// when production runs were recorded against it.
  Future<void> deleteRecipe({
    required String businessId,
    required String recipeId,
  }) async {
    try {
      await _dio.delete('/businesses/$businessId/recipes/$recipeId');
    } on DioException catch (e) {
      _rethrowAsInventoryError(e);
    }
  }
}
