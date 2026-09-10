/// Fake POS catalog (read-side) API for testing and manual testing.
library;

import 'pos_catalog_api.dart';

/// Fake POS catalog API for testing.
class FakePosCatalogApi extends PosCatalogApi {
  /// Optional override list (if null, returns no sales — an empty ledger is
  /// a perfectly normal state, unlike Inventory's catalog which always has
  /// some seed).
  final List<SaleDto>? overrideSales;

  /// Optional override map, keyed by sale id (if null, returns no line
  /// items for any sale).
  final Map<String, List<SaleLineItemDto>>? overrideLineItems;

  FakePosCatalogApi({this.overrideSales, this.overrideLineItems});

  @override
  Future<List<SaleDto>> fetchSales({required String storeId}) async {
    return overrideSales ?? const [];
  }

  @override
  Future<List<SaleLineItemDto>> fetchSaleLineItems({
    required String saleId,
  }) async {
    return overrideLineItems?[saleId] ?? const [];
  }
}
