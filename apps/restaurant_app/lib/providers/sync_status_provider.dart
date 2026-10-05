/// Sync status and pending sales state exposed to the UI.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_durations.dart';
import '../sync/sync_service.dart';
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

/// Provides the sync service instance, backed by the real HTTP API.
/// Requires a business context — without one there is no ledger to sync
/// against, so reading this provider throws instead of returning a stub.
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId == null) throw StateError('No active business context');

  final api = HttpSyncApi(dio: ref.watch(posServiceDioProvider), businessId: businessId);

  return SyncService(db: db, api: api);
});

/// Provides sync status: pending count, last sync time, last error, syncing flag.
///
/// Safe to watch before sign-in: with no active business context there is
/// no ledger to report on, so it yields an idle snapshot instead of throwing.
/// Once a business id appears this rebuilds and reports the real status.
final syncStatusProvider = StreamProvider<SyncStatusState>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  if (ref.watch(currentBusinessIdProvider) == null) {
    yield SyncStatusState(pendingCount: 0, isSyncing: false);
    return;
  }

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
    await Future.delayed(AppDurations.syncPollDelay);
  }
});
