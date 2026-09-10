/// Customer wiring: sync services and the direct-write API client — the
/// customer-specific analogue of `finance_api_provider.dart`. Customers
/// live in pos-service, so this reuses `posServiceDioProvider` rather than
/// introducing a new base URL.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/customer_api_service.dart';
import '../sync/customer_catalog_api.dart';
import '../sync/customer_entry_writer.dart';
import '../sync/customer_ledger_sync_service.dart';
import '../sync/customer_sync_api.dart';
import '../sync/customer_sync_service.dart';
import '../sync/fake_customer_catalog_api.dart';
import '../sync/fake_customer_sync_api.dart';
import '../sync/http_customer_catalog_api.dart';
import '../sync/http_customer_sync_api.dart';
import 'database_providers.dart';
import 'permissions_provider.dart';
import 'pos_api_provider.dart';

/// The real HTTP client once a business context exists, otherwise a fake —
/// same branching shape as `financeSyncApiProvider`.
final customerSyncApiProvider = Provider<CustomerSyncApi>((ref) {
  final businessId = ref.watch(currentBusinessIdProvider);
  return businessId == null
      ? FakeCustomerSyncApi()
      : HttpCustomerSyncApi(
          dio: ref.watch(posServiceDioProvider),
          businessId: businessId,
        );
});

final customerCatalogApiProvider = Provider<CustomerCatalogApi>((ref) {
  final businessId = ref.watch(currentBusinessIdProvider);
  return businessId == null
      ? FakeCustomerCatalogApi()
      : HttpCustomerCatalogApi(
          dio: ref.watch(posServiceDioProvider),
          businessId: businessId,
        );
});

/// Push: drains the customer outbox table.
final customerSyncServiceProvider = Provider<CustomerSyncService>((ref) {
  return CustomerSyncService(
    db: ref.watch(appDatabaseProvider),
    api: ref.watch(customerSyncApiProvider),
  );
});

/// Pull: refreshes the customer read cache.
final customerLedgerSyncServiceProvider = Provider<CustomerLedgerSyncService>((ref) {
  return CustomerLedgerSyncService(
    db: ref.watch(appDatabaseProvider),
    api: ref.watch(customerCatalogApiProvider),
  );
});

/// Direct (non-outbox) writes for already-synced customers.
final customerApiServiceProvider = Provider<CustomerApiService>(
  (ref) => CustomerApiService(dio: ref.watch(posServiceDioProvider)),
);

/// Producer side: converts a form submission into an outbox row.
final customerEntryWriterProvider = Provider<CustomerEntryWriter>(
  (ref) => CustomerEntryWriter(ref.watch(appDatabaseProvider)),
);
