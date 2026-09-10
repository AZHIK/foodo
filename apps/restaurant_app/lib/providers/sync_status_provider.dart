/// Sync status and pending sales state exposed to the UI.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../sync/sync_service.dart';
import '../sync/fake_sync_api.dart';
import '../sync/http_sync_api.dart';
import 'database_providers.dart';
import 'permissions_provider.dart';
import 'pos_api_provider.dart';

/// Sync status snapshot.
class SyncStatusState {
  final int pendingCount;
  final DateTime? lastSyncTime;
  final String? lastSyncError;
  final bool isSyncing;

  SyncStatusState({
    required this.pendingCount,
    this.lastSyncTime,
    this.lastSyncError,
    required this.isSyncing,
  });
}

/// Provides the sync service instance: the real HTTP API once a business
/// context exists, otherwise a fake — same branching shape as
/// `InventoryNotifier.build()`'s mock fallback, so the outbox has something
/// to push to (harmlessly) in demo/no-backend mode instead of throwing.
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final businessId = ref.watch(currentBusinessIdProvider);

  final api = businessId == null
      ? FakeSyncApi()
      : HttpSyncApi(dio: ref.watch(posServiceDioProvider), businessId: businessId);

  return SyncService(db: db, api: api);
});

/// Provides sync status: pending count, last sync time, last error, syncing flag.
final syncStatusProvider = StreamProvider<SyncStatusState>((ref) async* {
  final db = ref.watch(appDatabaseProvider);

  // Watch for changes to pending sales count.
  while (true) {
    final pending = await (db.select(db.pendingSales)
          ..where((row) =>
              row.syncStatus.isIn(const ['pending', 'failed'])))
        .get();

    final syncService = ref.watch(syncServiceProvider);
    yield SyncStatusState(
      pendingCount: pending.length,
      lastSyncTime: syncService.lastSyncTime,
      lastSyncError: syncService.lastSyncError,
      isSyncing: syncService.isSyncing,
    );

    // Poll every 2 seconds (in a real app, this would use proper notifications).
    await Future.delayed(const Duration(seconds: 2));
  }
});
