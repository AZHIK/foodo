/// Finance wiring: sync services and the direct-write API client — the
/// finance-specific analogue of `pos_api_provider.dart`. Finance lives in
/// POS Service, so this reuses `posServiceDioProvider` rather than
/// introducing a new base URL.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/finance_api_service.dart';
import '../sync/fake_finance_catalog_api.dart';
import '../sync/fake_finance_sync_api.dart';
import '../sync/finance_catalog_api.dart';
import '../sync/finance_entry_writer.dart';
import '../sync/finance_ledger_sync_service.dart';
import '../sync/finance_sync_api.dart';
import '../sync/finance_sync_service.dart';
import '../sync/http_finance_catalog_api.dart';
import '../sync/http_finance_sync_api.dart';
import 'database_providers.dart';
import 'permissions_provider.dart';
import 'pos_api_provider.dart';

/// The real HTTP client once a business context exists, otherwise a fake —
/// same branching shape as `syncServiceProvider`, so the outbox has
/// something harmless to push to in demo mode instead of throwing.
final financeSyncApiProvider = Provider<FinanceSyncApi>((ref) {
  final businessId = ref.watch(currentBusinessIdProvider);
  return businessId == null
      ? FakeFinanceSyncApi()
      : HttpFinanceSyncApi(
          dio: ref.watch(posServiceDioProvider),
          businessId: businessId,
        );
});

final financeCatalogApiProvider = Provider<FinanceCatalogApi>((ref) {
  final businessId = ref.watch(currentBusinessIdProvider);
  return businessId == null
      ? FakeFinanceCatalogApi()
      : HttpFinanceCatalogApi(
          dio: ref.watch(posServiceDioProvider),
          businessId: businessId,
        );
});

/// Push: drains the expense/income outbox tables.
final financeSyncServiceProvider = Provider<FinanceSyncService>((ref) {
  return FinanceSyncService(
    db: ref.watch(appDatabaseProvider),
    api: ref.watch(financeSyncApiProvider),
  );
});

/// Pull: refreshes the read caches.
final financeLedgerSyncServiceProvider = Provider<FinanceLedgerSyncService>((ref) {
  return FinanceLedgerSyncService(
    db: ref.watch(appDatabaseProvider),
    api: ref.watch(financeCatalogApiProvider),
  );
});

/// Direct (non-outbox) writes for already-synced entries, and receipt fetch.
final financeApiServiceProvider = Provider<FinanceApiService>(
  (ref) => FinanceApiService(dio: ref.watch(posServiceDioProvider)),
);

/// Producer side: converts a form submission into an outbox row.
final financeEntryWriterProvider = Provider<FinanceEntryWriter>(
  (ref) => FinanceEntryWriter(ref.watch(appDatabaseProvider)),
);
