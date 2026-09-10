/// Fake implementation of SuppliersCatalogApi for testing and demo mode.
library;

import 'suppliers_catalog_api.dart';

/// Fake suppliers catalog API — demo mode has no server-side directory to
/// pull; `SuppliersNotifier` falls back to `MockSuppliers` directly rather
/// than routing through this.
class FakeSuppliersCatalogApi extends SuppliersCatalogApi {
  final List<SupplierDto> suppliers;

  FakeSuppliersCatalogApi({this.suppliers = const []});

  @override
  Future<List<SupplierDto>> fetchSuppliers() async => suppliers;
}
