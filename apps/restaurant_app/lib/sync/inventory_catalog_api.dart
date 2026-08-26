/// Pluggable interface for fetching the inventory catalog.
///
/// This abstract interface decouples the catalog sync from the actual HTTP backend.
/// For this task, `FakeInventoryCatalogApi` provides test/demo behavior.
/// A later task wires the real HTTP client to call Inventory Service's item-list endpoint.
library;

import 'package:decimal/decimal.dart';

/// Data transfer object for a cached item.
class CatalogItemDto {
  final String id;
  final String businessId;
  final String businessLocationId;
  final String name;
  final String unitOfMeasure;
  final String? category;
  final Decimal reorderThreshold;
  final Decimal reorderQuantity;
  final Decimal? sellingPrice;
  final bool allowNegativeStock;
  final String itemType;
  final DateTime createdAt;
  final DateTime updatedAt;

  CatalogItemDto({
    required this.id,
    required this.businessId,
    required this.businessLocationId,
    required this.name,
    required this.unitOfMeasure,
    this.category,
    required this.reorderThreshold,
    required this.reorderQuantity,
    this.sellingPrice,
    required this.allowNegativeStock,
    required this.itemType,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// Pluggable API for fetching the inventory catalog.
abstract class InventoryCatalogApi {
  /// Fetches all active items for a business location.
  Future<List<CatalogItemDto>> fetchItems({
    required String businessLocationId,
  });
}
