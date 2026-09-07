/// Inventory Service wiring: the shared Dio client, the read-side catalog
/// sync pipeline, and the write-side API service — the inventory-specific
/// analogue of `identityServiceDioProvider`/`store_api_provider_real.dart`.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_refresh_interceptor.dart';
import '../auth/token_storage.dart';
import '../config/api_config.dart';
import '../services/inventory_api_service.dart';
import '../sync/catalog_sync_service.dart';
import '../sync/http_inventory_catalog_api.dart';
import '../sync/inventory_catalog_api.dart';
import 'auth_provider.dart';
import 'database_providers.dart';
import 'permissions_cache_tick_provider.dart';
import 'permissions_provider.dart';

/// Dio client for Inventory Service calls.
///
/// Token refresh is always an Identity Service concern even though this
/// client's own `baseUrl` points at Inventory Service — `TokenRefreshInterceptor`
/// is given Identity Service's base URL so a 401 here still refreshes
/// against the service that actually issues tokens, exactly like
/// `identityServiceDioProvider`.
final inventoryServiceDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.inventoryServiceBaseUrl,
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

/// The one real client for the read-side catalog/stock pull.
final inventoryCatalogApiProvider = Provider<InventoryCatalogApi>((ref) {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId == null) throw StateError('No active business context');
  return HttpInventoryCatalogApi(
    dio: ref.watch(inventoryServiceDioProvider),
    businessId: businessId,
  );
});

/// Pulls the catalog/stock levels into the local cache. Depends on
/// [inventoryCatalogApiProvider], so only read once a business context
/// exists (callers already know this from `currentBusinessIdProvider`).
final catalogSyncServiceProvider = Provider<CatalogSyncService>((ref) {
  return CatalogSyncService(
    db: ref.watch(appDatabaseProvider),
    api: ref.watch(inventoryCatalogApiProvider),
  );
});

/// The one real client for item CRUD and stock operations (adjust/waste/
/// transfer).
final inventoryApiServiceProvider = Provider<InventoryApiService>(
  (ref) => InventoryApiService(dio: ref.watch(inventoryServiceDioProvider)),
);
