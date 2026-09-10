/// POS Service wiring: the shared Dio client, the read-side sales sync
/// pipeline, and the write-side void/refund API service — the sales-specific
/// analogue of `inventory_api_provider.dart`.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_refresh_interceptor.dart';
import '../auth/token_storage.dart';
import '../config/api_config.dart';
import '../services/pos_api_service.dart';
import '../sync/http_pos_catalog_api.dart';
import '../sync/pos_catalog_api.dart';
import '../sync/sales_sync_service.dart';
import 'database_providers.dart';
import 'permissions_cache_tick_provider.dart';
import 'permissions_provider.dart';

/// Dio client for POS Service calls.
///
/// Token refresh is always an Identity Service concern even though this
/// client's own `baseUrl` points at POS Service — same pattern as
/// `inventoryServiceDioProvider`.
final posServiceDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.posServiceBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
  ));

  dio.interceptors.add(TokenRefreshInterceptor(
    tokenStorage: TokenStorage(),
    baseUrl: ApiConfig.identityServiceBaseUrl,
    profileRepo: ref.watch(localProfileRepositoryProvider),
    onPermissionsSynced: () => ref.read(permissionsCacheTickProvider.notifier).state++,
  ));

  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));

  return dio;
});

/// The one real client for the read-side sales-ledger pull.
final posCatalogApiProvider = Provider<PosCatalogApi>((ref) {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId == null) throw StateError('No active business context');
  return HttpPosCatalogApi(
    dio: ref.watch(posServiceDioProvider),
    businessId: businessId,
  );
});

/// Pulls completed sales into the local cache. Depends on
/// [posCatalogApiProvider], so only read once a business context exists.
final salesSyncServiceProvider = Provider<SalesSyncService>((ref) {
  return SalesSyncService(
    db: ref.watch(appDatabaseProvider),
    api: ref.watch(posCatalogApiProvider),
  );
});

/// The one real client for void/refund.
final posApiServiceProvider = Provider<PosApiService>(
  (ref) => PosApiService(dio: ref.watch(posServiceDioProvider)),
);
