/// Fake implementation of CustomerCatalogApi for testing and demo mode.
library;

import 'customer_catalog_api.dart';

/// Fake customer catalog API — demo mode has no server-side ledger to
/// pull; `CustomersNotifier` falls back to `MockCustomers` directly rather
/// than routing through this.
class FakeCustomerCatalogApi extends CustomerCatalogApi {
  final List<CustomerServerDto> customers;

  FakeCustomerCatalogApi({this.customers = const []});

  @override
  Future<List<CustomerServerDto>> fetchCustomers() async => customers;
}
