/// Pluggable interface for fetching the inventory catalog and stock levels.
///
/// This abstract interface decouples the catalog sync from the actual HTTP backend.
/// For this task, `FakeInventoryCatalogApi` provides test/demo behavior.
/// `HttpInventoryCatalogApi` calls Inventory Service's real endpoints.
library;

import 'package:decimal/decimal.dart';

/// Data transfer object for a cached item.
class CatalogItemDto {
  final String id;
  final String businessId;
  final String storeId;
  final String name;
  final String unitOfMeasure;
  final String? category;
  final Decimal reorderThreshold;
  final Decimal reorderQuantity;
  final Decimal? sellingPrice;
  final Decimal? unitCost;
  final bool allowNegativeStock;
  final String itemType;
  final DateTime createdAt;
  final DateTime updatedAt;

  CatalogItemDto({
    required this.id,
    required this.businessId,
    required this.storeId,
    required this.name,
    required this.unitOfMeasure,
    this.category,
    required this.reorderThreshold,
    required this.reorderQuantity,
    this.sellingPrice,
    this.unitCost,
    required this.allowNegativeStock,
    required this.itemType,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// Data transfer object for a cached stock level.
class StockLevelDto {
  final String itemId;
  final String storeId;
  final Decimal currentQuantity;
  final DateTime updatedAt;

  StockLevelDto({
    required this.itemId,
    required this.storeId,
    required this.currentQuantity,
    required this.updatedAt,
  });
}

/// Pluggable API for fetching the inventory catalog and stock levels.
abstract class InventoryCatalogApi {
  /// Fetches all active items for a store.
  Future<List<CatalogItemDto>> fetchItems({required String storeId});

  /// Fetches current stock levels for a store.
  Future<List<StockLevelDto>> fetchStockLevels({required String storeId});
}
