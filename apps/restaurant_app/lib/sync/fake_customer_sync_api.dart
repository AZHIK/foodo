/// Fake implementation of CustomerSyncApi for testing and demo mode.
///
/// Mirrors `FakeFinanceSyncApi`'s behavior knobs.
library;

import 'customer_sync_api.dart';
import 'customer_sync_dtos.dart';

/// Fake customer sync API for testing behavior.
class FakeCustomerSyncApi extends CustomerSyncApi {
  /// If true, all customers fail.
  final bool alwaysFail;

  /// If true, the entire call throws (simulates network error).
  final bool throwsNetworkError;

  /// Map from customer id -> custom result. Overrides default behavior.
  final Map<String, CustomerSyncRowResult> overrides;

  FakeCustomerSyncApi({
    this.alwaysFail = false,
    this.throwsNetworkError = false,
    this.overrides = const {},
  });

  @override
  Future<CustomerSyncBatchResult> syncCustomers(List<CustomerDto> batch) async {
    if (throwsNetworkError) {
      throw CustomerNetworkException('Simulated network error');
    }
    return CustomerSyncBatchResult(
      results: [for (final c in batch) _resultFor(c.id)],
    );
  }

  CustomerSyncRowResult _resultFor(String customerId) {
    final override = overrides[customerId];
    if (override != null) return override;
    if (alwaysFail) {
      return CustomerSyncRowResult(
        clientCustomerId: customerId,
        status: 'failed',
        reason: 'Simulated failure',
      );
    }
    return CustomerSyncRowResult(clientCustomerId: customerId, status: 'created');
  }
}

/// Network error for testing.
class CustomerNetworkException implements Exception {
  final String message;
  CustomerNetworkException(this.message);
  @override
  String toString() => 'CustomerNetworkException: $message';
}
