/// Tests for the customer sync engine.
///
/// Mirrors `finance_sync_service_test.dart`: batch processing, partial
/// failure, idempotency, and retry logic.
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos/database/app_database.dart';
import 'package:restaurant_pos/sync/customer_sync_dtos.dart';
import 'package:restaurant_pos/sync/customer_sync_service.dart';
import 'package:restaurant_pos/sync/fake_customer_sync_api.dart';

void main() {
  group('CustomerSyncService', () {
    late AppDatabase database;
    late CustomerSyncService syncService;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      syncService = CustomerSyncService(db: database, api: FakeCustomerSyncApi());
    });

    tearDown(() async {
      await database.close();
    });

    Future<void> insertCustomer(String customerId, {String name = 'Jane Doe'}) {
      final now = DateTime.now();
      return database.into(database.customerEntries).insert(
            CustomerEntriesCompanion.insert(
              customerId: customerId,
              businessId: 'biz-1',
              name: name,
              phone: '+1-555-0100',
              joinedAt: now,
              actorUserId: 'staff-1',
              createdAt: now,
            ),
          );
    }

    test('all-success batch marks all customers as synced', () async {
      await insertCustomer('cust-1');
      await insertCustomer('cust-2');

      await syncService.syncNow();

      final synced = await (database.select(database.customerEntries)
            ..where((r) => r.syncStatus.equals('synced')))
          .get();
      expect(synced.length, 2);
    });

    test('partial failure updates per-row status', () async {
      await insertCustomer('cust-good');
      await insertCustomer('cust-bad');

      final api = FakeCustomerSyncApi(
        overrides: {
          'cust-bad': CustomerSyncRowResult(
            clientCustomerId: 'cust-bad',
            status: 'failed',
            reason: 'customer id is already in use',
          ),
        },
      );
      final service = CustomerSyncService(db: database, api: api);
      await service.syncNow();

      final good = await (database.select(database.customerEntries)
            ..where((r) => r.customerId.equals('cust-good')))
          .getSingleOrNull();
      expect(good!.syncStatus, 'synced');

      final bad = await (database.select(database.customerEntries)
            ..where((r) => r.customerId.equals('cust-bad')))
          .getSingleOrNull();
      expect(bad!.syncStatus, 'failed');
      expect(bad.syncError, 'customer id is already in use');
    });

    test('synced customers are never re-synced', () async {
      await insertCustomer('cust-1');
      await syncService.syncNow();

      await insertCustomer('cust-2');

      var pending = await (database.select(database.customerEntries)
            ..where((r) => r.syncStatus.isIn(const ['pending', 'failed'])))
          .get();
      expect(pending.length, 1);

      await syncService.syncNow();
      pending = await (database.select(database.customerEntries)
            ..where((r) => r.syncStatus.isIn(const ['pending', 'failed'])))
          .get();
      expect(pending.length, 0);
    });

    test('failed customers are retried on next sync', () async {
      await insertCustomer('cust-retry');

      final failApi = FakeCustomerSyncApi(alwaysFail: true);
      final failService = CustomerSyncService(db: database, api: failApi);
      await failService.syncNow();

      var rows = await database.select(database.customerEntries).get();
      expect(rows.first.syncStatus, 'failed');
      expect(rows.first.syncAttemptCount, 1);

      final succeedApi = FakeCustomerSyncApi();
      final succeedService = CustomerSyncService(db: database, api: succeedApi);
      await succeedService.syncNow();

      rows = await database.select(database.customerEntries).get();
      expect(rows.first.syncStatus, 'synced');
    });

    test('network error reverts claimed rows to pending and bumps attempt count', () async {
      await insertCustomer('cust-net');

      final netApi = FakeCustomerSyncApi(throwsNetworkError: true);
      final netService = CustomerSyncService(db: database, api: netApi);
      await netService.syncNow();

      final rows = await database.select(database.customerEntries).get();
      expect(rows.first.syncStatus, 'pending');
      expect(rows.first.syncAttemptCount, 1);
      expect(netService.lastSyncError, isNotNull);
    });

    test('syncNow is reentrant-safe — concurrent calls do not double-claim rows', () async {
      await insertCustomer('cust-1');
      expect(syncService.isSyncing, isFalse);

      final first = syncService.syncNow();
      expect(syncService.isSyncing, isTrue);
      final second = syncService.syncNow();

      await Future.wait([first, second]);
      expect(syncService.isSyncing, isFalse);

      final rows = await database.select(database.customerEntries).get();
      expect(rows.length, 1);
      expect(rows.single.syncStatus, 'synced');
    });
  });
}
