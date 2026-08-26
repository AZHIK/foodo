/// Tests for the core sync engine.
///
/// Verifies batch processing, partial failure handling, idempotency, and retry logic.
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos/database/app_database.dart';
import 'package:restaurant_pos/sync/fake_sync_api.dart';
import 'package:restaurant_pos/sync/sync_dtos.dart';
import 'package:restaurant_pos/sync/sync_service.dart';

void main() {
  group('SyncService', () {
    late AppDatabase database;
    late SyncService syncService;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      syncService = SyncService(db: database, api: FakeSyncApi());
    });

    tearDown(() async {
      await database.close();
    });

    test('all-success batch marks all sales as synced', () async {
      final now = DateTime.now();

      // Insert two pending sales.
      await database.into(database.pendingSales).insert(
            PendingSalesCompanion.insert(
              clientSaleId: 'sale-1',
              status: 'completed',
              businessLocationId: 'loc-1',
              paymentMethod: 'cash',
              occurredAt: now,
              createdAt: now,
            ),
          );
      await database.into(database.pendingSales).insert(
            PendingSalesCompanion.insert(
              clientSaleId: 'sale-2',
              status: 'completed',
              businessLocationId: 'loc-1',
              paymentMethod: 'cash',
              occurredAt: now,
              createdAt: now,
            ),
          );

      // Sync with API that succeeds.
      await syncService.syncNow();

      // Verify both are now synced.
      final synced = await (database.select(database.pendingSales)
            ..where((r) => r.syncStatus.equals('synced')))
          .get();
      expect(synced.length, 2);
    });

    test('partial failure updates per-row status', () async {
      final now = DateTime.now();

      // Insert two pending sales.
      await database.into(database.pendingSales).insert(
            PendingSalesCompanion.insert(
              clientSaleId: 'sale-good',
              status: 'completed',
              businessLocationId: 'loc-1',
              paymentMethod: 'cash',
              occurredAt: now,
              createdAt: now,
            ),
          );
      await database.into(database.pendingSales).insert(
            PendingSalesCompanion.insert(
              clientSaleId: 'sale-bad',
              status: 'completed',
              businessLocationId: 'loc-1',
              paymentMethod: 'cash',
              occurredAt: now,
              createdAt: now,
            ),
          );

      // Use an API that fails one and succeeds the other.
      final api = FakeSyncApi(
        overrides: {
          'sale-bad': SyncRowResult(
            clientSaleId: 'sale-bad',
            status: 'failed',
            reason: 'Invalid item',
          ),
        },
      );
      final service = SyncService(db: database, api: api);

      await service.syncNow();

      // Verify statuses.
      final good = await (database.select(database.pendingSales)
            ..where((r) => r.clientSaleId.equals('sale-good')))
          .getSingleOrNull();
      expect(good!.syncStatus, 'synced');

      final bad = await (database.select(database.pendingSales)
            ..where((r) => r.clientSaleId.equals('sale-bad')))
          .getSingleOrNull();
      expect(bad!.syncStatus, 'failed');
      expect(bad.syncError, 'Invalid item');
    });

    test('synced sales are never re-synced', () async {
      final now = DateTime.now();

      // Insert and sync one sale.
      await database.into(database.pendingSales).insert(
            PendingSalesCompanion.insert(
              clientSaleId: 'sale-1',
              status: 'completed',
              businessLocationId: 'loc-1',
              paymentMethod: 'cash',
              occurredAt: now,
              createdAt: now,
            ),
          );

      await syncService.syncNow();

      // Insert another pending sale.
      await database.into(database.pendingSales).insert(
            PendingSalesCompanion.insert(
              clientSaleId: 'sale-2',
              status: 'completed',
              businessLocationId: 'loc-1',
              paymentMethod: 'cash',
              occurredAt: now,
              createdAt: now,
            ),
          );

      // Query pending before second sync.
      var pending = await syncService.queryPendingSales();
      expect(pending.length, 1); // Only sale-2 should be pending.

      // After sync, both should be synced.
      await syncService.syncNow();
      pending = await syncService.queryPendingSales();
      expect(pending.length, 0); // All synced.
    });

    test('failed sales are retried on next sync', () async {
      final now = DateTime.now();

      // Insert a sale.
      await database.into(database.pendingSales).insert(
            PendingSalesCompanion.insert(
              clientSaleId: 'sale-retry',
              status: 'completed',
              businessLocationId: 'loc-1',
              paymentMethod: 'cash',
              occurredAt: now,
              createdAt: now,
            ),
          );

      // First sync fails.
      final failApi = FakeSyncApi(alwaysFail: true);
      final failService = SyncService(db: database, api: failApi);
      await failService.syncNow();

      // Verify it's in failed state.
      var sales = await database.select(database.pendingSales).get();
      expect(sales.first.syncStatus, 'failed');

      // Second sync succeeds.
      final succeedApi = FakeSyncApi();
      final succeedService = SyncService(db: database, api: succeedApi);
      await succeedService.syncNow();

      // Verify it's now synced.
      sales = await database.select(database.pendingSales).get();
      expect(sales.first.syncStatus, 'synced');
    });
  });
}
