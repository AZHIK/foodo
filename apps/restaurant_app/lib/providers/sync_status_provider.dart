/// Sync status and pending sales state exposed to the UI.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/token_refresh_interceptor.dart';
import '../auth/token_storage.dart';
import '../sync/sync_service.dart';
import '../sync/fake_sync_api.dart';
import 'database_providers.dart';

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

/// Provides the HTTP Dio client configured with backend base URL and token refresh.
final dioClientProvider = Provider<Dio>((ref) {
  // TODO: Replace with real backend URL from config/environment
  const baseUrl = 'http://localhost:8009/api/v1';

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
  ));

  // Add logging interceptor in dev mode
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
  ));

  // Add token refresh interceptor for automatic token refresh on 401.
  // The interceptor gets its own bare Dio for refresh calls to avoid reentrancy.
  final tokenStorage = TokenStorage();
  dio.interceptors.add(TokenRefreshInterceptor(
    tokenStorage: tokenStorage,
    baseUrl: baseUrl,
  ));

  return dio;
});

/// Provides the sync service instance (uses real HTTP API).
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final dio = ref.watch(dioClientProvider);

  // Get bearer token from session (for now, hardcoded; in real app, from auth)
  const bearerToken = 'your-bearer-token-here'; // TODO: Get from session/auth

  // For this MVP: use fake API to avoid real backend dependency during testing.
  // To switch to real API, comment out FakeSyncApi and uncomment HttpSyncApi:
  // final api = HttpSyncApi(
  //   dio: dio,
  //   businessId: 'biz-001',
  //   bearerToken: bearerToken,
  // );
  final api = FakeSyncApi(); // Using fake for MVP

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
