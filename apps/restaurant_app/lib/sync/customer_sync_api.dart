/// Pluggable interface for syncing customers to POS Service.
///
/// Mirrors `finance_sync_api.dart`'s role for other-expenses/other-incomes.
/// `FakeCustomerSyncApi` provides test/demo behavior; `HttpCustomerSyncApi`
/// calls the real `/customers/sync` endpoint.
library;

import 'customer_sync_dtos.dart';

/// Pluggable API for syncing customers.
abstract class CustomerSyncApi {
  /// Syncs a batch of pending customers.
  Future<CustomerSyncBatchResult> syncCustomers(List<CustomerDto> batch);
}
