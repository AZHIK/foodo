/// Fake implementation of PosSyncApi for testing and manual testing.
///
/// `FakeSyncApi` simulates various backend behaviors: all-success,
/// all-failure, selective success per ID, and network errors.
/// Used during development, testing, and for manual feature verification
/// before the real backend integration.
library;

import 'pos_sync_api.dart';
import 'sync_dtos.dart';

/// Fake POS sync API for testing behavior.
class FakeSyncApi extends PosSyncApi {
  /// If true, all sales succeed.
  final bool alwaysSucceed;

  /// If true, all sales fail.
  final bool alwaysFail;

  /// If true, the entire call throws (simulates network error).
  final bool throwsNetworkError;

  /// Map from clientSaleId -> custom SyncRowResult.
  /// Overrides default behavior for specific IDs.
  final Map<String, SyncRowResult> overrides;

  FakeSyncApi({
    this.alwaysSucceed = true,
    this.alwaysFail = false,
    this.throwsNetworkError = false,
    this.overrides = const {},
  });

  @override
  Future<SyncBatchResult> syncSales(List<PendingSaleDto> batch) async {
    if (throwsNetworkError) {
      throw NetworkException('Simulated network error');
    }

    final results = <SyncRowResult>[];
    for (final sale in batch) {
      final override = overrides[sale.clientSaleId];
      if (override != null) {
        results.add(override);
      } else if (alwaysFail) {
        results.add(SyncRowResult(
          clientSaleId: sale.clientSaleId,
          status: 'failed',
          reason: 'Simulated failure',
        ));
      } else {
        // Default: succeed
        results.add(SyncRowResult(
          clientSaleId: sale.clientSaleId,
          status: 'created',
        ));
      }
    }

    return SyncBatchResult(results: results);
  }
}

/// Network error for testing.
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => 'NetworkException: $message';
}
