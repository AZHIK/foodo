/// Fake inventory catalog API for testing and manual testing.
library;

import 'package:decimal/decimal.dart';
import 'inventory_catalog_api.dart';

/// Fake inventory catalog API for testing.
class FakeInventoryCatalogApi extends InventoryCatalogApi {
  /// Optional override list (if null, uses default seed data).
  final List<CatalogItemDto>? overrideCatalog;

  /// Optional override list (if null, derives quantities from the catalog).
  final List<StockLevelDto>? overrideStockLevels;

  FakeInventoryCatalogApi({this.overrideCatalog, this.overrideStockLevels});

  @override
  Future<List<CatalogItemDto>> fetchItems({required String storeId}) async {
    return overrideCatalog ?? _defaultCatalog(storeId);
  }

  @override
  Future<List<StockLevelDto>> fetchStockLevels({required String storeId}) async {
    return overrideStockLevels ?? _defaultStockLevels(storeId);
  }

  List<CatalogItemDto> _defaultCatalog(String storeId) {
    final now = DateTime.now();
    return [
      CatalogItemDto(
        id: 'item-001',
        businessId: 'biz-001',
        storeId: storeId,
        name: 'Tomato',
        unitId: 'unit-kg',
        category: 'category-produce',
        reorderThreshold: Decimal.fromInt(10),
        reorderQuantity: Decimal.fromInt(50),
        sellingPrice: Decimal.parse('2.50'),
        unitCost: Decimal.parse('1.20'),
        allowNegativeStock: false,
        itemType: 'sellable',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      CatalogItemDto(
        id: 'item-002',
        businessId: 'biz-001',
        storeId: storeId,
        name: 'Onion',
        unitId: 'unit-kg',
        category: 'category-produce',
        reorderThreshold: Decimal.fromInt(20),
        reorderQuantity: Decimal.fromInt(100),
        sellingPrice: Decimal.parse('1.50'),
        unitCost: Decimal.parse('0.70'),
        allowNegativeStock: false,
        itemType: 'sellable',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  List<StockLevelDto> _defaultStockLevels(String storeId) {
    final now = DateTime.now();
    return [
      StockLevelDto(
        itemId: 'item-001',
        storeId: storeId,
        currentQuantity: Decimal.fromInt(35),
        updatedAt: now,
      ),
      StockLevelDto(
        itemId: 'item-002',
        storeId: storeId,
        currentQuantity: Decimal.fromInt(8),
        updatedAt: now,
      ),
    ];
  }
}
