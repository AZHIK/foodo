/// Fake inventory catalog API for testing and manual testing.
library;

import 'package:decimal/decimal.dart';
import 'inventory_catalog_api.dart';

/// Fake inventory catalog API for testing.
class FakeInventoryCatalogApi extends InventoryCatalogApi {
  /// Optional override list (if null, uses default seed data).
  final List<CatalogItemDto>? overrideCatalog;

  FakeInventoryCatalogApi({this.overrideCatalog});

  @override
  Future<List<CatalogItemDto>> fetchItems({
    required String businessLocationId,
  }) async {
    return overrideCatalog ??
        _defaultCatalog(businessLocationId);
  }

  List<CatalogItemDto> _defaultCatalog(String locationId) {
    final now = DateTime.now();
    return [
      CatalogItemDto(
        id: 'item-001',
        businessId: 'biz-001',
        businessLocationId: locationId,
        name: 'Tomato',
        unitOfMeasure: 'kg',
        category: 'Produce',
        reorderThreshold: Decimal.fromInt(10),
        reorderQuantity: Decimal.fromInt(50),
        sellingPrice: Decimal.parse('2.50'),
        allowNegativeStock: false,
        itemType: 'sellable',
        createdAt: now,
        updatedAt: now,
      ),
      CatalogItemDto(
        id: 'item-002',
        businessId: 'biz-001',
        businessLocationId: locationId,
        name: 'Onion',
        unitOfMeasure: 'kg',
        category: 'Produce',
        reorderThreshold: Decimal.fromInt(20),
        reorderQuantity: Decimal.fromInt(100),
        sellingPrice: Decimal.parse('1.50'),
        allowNegativeStock: false,
        itemType: 'sellable',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
