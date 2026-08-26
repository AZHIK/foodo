/// Pluggable interface for syncing sales to POS Service.
///
/// This abstract interface decouples the sync engine from the actual HTTP/backend
/// implementation. For this task, `FakeSyncApi` provides test behavior.
/// A later task wires the real HTTP client to call `services/pos-service`'s
/// `/sales/sync` endpoint.
library;

import 'sync_dtos.dart';

/// Pluggable API for syncing sales.
abstract class PosSyncApi {
  /// Syncs a batch of pending sales.
  ///
  /// Returns a `SyncBatchResult` with one `SyncRowResult` per submitted sale,
  /// indicating `created`, `duplicate`, or `failed` for each `clientSaleId`.
  Future<SyncBatchResult> syncSales(List<PendingSaleDto> batch);
}
