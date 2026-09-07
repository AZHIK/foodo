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

class InventoryApiService {
  const InventoryApiService({required this._dio});

  final Dio _dio;

  CatalogItemDto _itemFromJson(Map<String, dynamic> item) => CatalogItemDto(
        id: item['id'] as String,
        businessId: item['business_id'] as String,
        storeId: item['store_id'] as String,
        name: item['name'] as String,
        unitOfMeasure: item['unit_of_measure'] as String,
        category: item['category'] as String?,
        reorderThreshold: Decimal.parse(item['reorder_threshold'].toString()),
        reorderQuantity: Decimal.parse(item['reorder_quantity'].toString()),
        sellingPrice: item['selling_price'] != null
            ? Decimal.parse(item['selling_price'].toString())
            : null,
        unitCost:
            item['unit_cost'] != null ? Decimal.parse(item['unit_cost'].toString()) : null,
        allowNegativeStock: item['allow_negative_stock'] as bool? ?? false,
        itemType: item['item_type'] as String,
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
  Future<CatalogItemDto> createItem({
    required String businessId,
    required String storeId,
    required String name,
    required String unitOfMeasure,
    required String itemType,
    required Decimal reorderThreshold,
    required Decimal reorderQuantity,
    String? category,
    Decimal? sellingPrice,
    Decimal? unitCost,
    bool allowNegativeStock = false,
  }) async {
    try {
      final response = await _dio.post(
        '/businesses/$businessId/items',
        data: {
          'store_id': storeId,
          'name': name,
          'unit_of_measure': unitOfMeasure,
          'item_type': itemType,
          'reorder_threshold': reorderThreshold.toString(),
          'reorder_quantity': reorderQuantity.toString(),
          if (category != null) 'category': category,
          if (sellingPrice != null) 'selling_price': sellingPrice.toString(),
          if (unitCost != null) 'unit_cost': unitCost.toString(),
          'allow_negative_stock': allowNegativeStock,
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
    String? unitOfMeasure,
    String? category,
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
          if (unitOfMeasure != null) 'unit_of_measure': unitOfMeasure,
          if (category != null) 'category': category,
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
}
