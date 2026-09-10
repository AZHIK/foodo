/// Tests for the finance (other-expenses/other-incomes) sync engine.
///
/// Mirrors `sync_service_test.dart`: batch processing, partial failure,
/// idempotency, and retry logic — for both expense and income outboxes.
library;

import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos/database/app_database.dart';
import 'package:restaurant_pos/sync/fake_finance_sync_api.dart';
import 'package:restaurant_pos/sync/finance_sync_dtos.dart';
import 'package:restaurant_pos/sync/finance_sync_service.dart';

void main() {
  group('FinanceSyncService — expenses', () {
    late AppDatabase database;
    late FinanceSyncService syncService;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      syncService = FinanceSyncService(db: database, api: FakeFinanceSyncApi());
    });

    tearDown(() async {
      await database.close();
    });

    Future<void> insertExpense(String expenseId, {String category = 'rent'}) {
      final now = DateTime.now();
      return database.into(database.expenseEntries).insert(
            ExpenseEntriesCompanion.insert(
              expenseId: expenseId,
              businessId: 'biz-1',
              storeId: 'loc-1',
              category: category,
              amount: Decimal.parse('10.00'),
              occurredAt: now,
              actorUserId: 'staff-1',
              createdAt: now,
            ),
          );
    }

    test('all-success batch marks all expenses as synced', () async {
      await insertExpense('exp-1');
      await insertExpense('exp-2');

      await syncService.syncNow();

      final synced = await (database.select(database.expenseEntries)
            ..where((r) => r.syncStatus.equals('synced')))
          .get();
      expect(synced.length, 2);
    });

    test('partial failure updates per-row status', () async {
      await insertExpense('exp-good');
      await insertExpense('exp-bad');

      final api = FakeFinanceSyncApi(
        overrides: {
          'exp-bad': FinanceSyncRowResult(
            clientEntryId: 'exp-bad',
            status: 'failed',
            reason: 'Invalid category',
          ),
        },
      );
      final service = FinanceSyncService(db: database, api: api);
      await service.syncNow();

      final good = await (database.select(database.expenseEntries)
            ..where((r) => r.expenseId.equals('exp-good')))
          .getSingleOrNull();
      expect(good!.syncStatus, 'synced');

      final bad = await (database.select(database.expenseEntries)
            ..where((r) => r.expenseId.equals('exp-bad')))
          .getSingleOrNull();
      expect(bad!.syncStatus, 'failed');
      expect(bad.syncError, 'Invalid category');
    });

    test('synced expenses are never re-synced', () async {
      await insertExpense('exp-1');
      await syncService.syncNow();

      await insertExpense('exp-2');

      var pending = await (database.select(database.expenseEntries)
            ..where((r) => r.syncStatus.isIn(const ['pending', 'failed'])))
          .get();
      expect(pending.length, 1);

      await syncService.syncNow();
      pending = await (database.select(database.expenseEntries)
            ..where((r) => r.syncStatus.isIn(const ['pending', 'failed'])))
          .get();
      expect(pending.length, 0);
    });

    test('failed expenses are retried on next sync', () async {
      await insertExpense('exp-retry');

      final failApi = FakeFinanceSyncApi(alwaysFail: true);
      final failService = FinanceSyncService(db: database, api: failApi);
      await failService.syncNow();

      var rows = await database.select(database.expenseEntries).get();
      expect(rows.first.syncStatus, 'failed');
      expect(rows.first.syncAttemptCount, 1);

      final succeedApi = FakeFinanceSyncApi();
      final succeedService = FinanceSyncService(db: database, api: succeedApi);
      await succeedService.syncNow();

      rows = await database.select(database.expenseEntries).get();
      expect(rows.first.syncStatus, 'synced');
    });

    test('network error reverts claimed rows to pending and bumps attempt count', () async {
      await insertExpense('exp-net');

      final netApi = FakeFinanceSyncApi(throwsNetworkError: true);
      final netService = FinanceSyncService(db: database, api: netApi);
      await netService.syncNow();

      final rows = await database.select(database.expenseEntries).get();
      expect(rows.first.syncStatus, 'pending');
      expect(rows.first.syncAttemptCount, 1);
      expect(netService.lastSyncError, isNotNull);
    });
  });

  group('FinanceSyncService — incomes', () {
    late AppDatabase database;
    late FinanceSyncService syncService;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      syncService = FinanceSyncService(db: database, api: FakeFinanceSyncApi());
    });

    tearDown(() async {
      await database.close();
    });

    Future<void> insertIncome(String incomeId) {
      final now = DateTime.now();
      return database.into(database.otherIncomeEntries).insert(
            OtherIncomeEntriesCompanion.insert(
              incomeId: incomeId,
              businessId: 'biz-1',
              storeId: 'loc-1',
              category: 'catering',
              amount: Decimal.parse('20.00'),
              occurredAt: now,
              actorUserId: 'staff-1',
              createdAt: now,
            ),
          );
    }

    test('all-success batch marks all incomes as synced', () async {
      await insertIncome('inc-1');
      await insertIncome('inc-2');

      await syncService.syncNow();

      final synced = await (database.select(database.otherIncomeEntries)
            ..where((r) => r.syncStatus.equals('synced')))
          .get();
      expect(synced.length, 2);
    });

    test('both expense and income outboxes drain in one syncNow call', () async {
      await database.into(database.expenseEntries).insert(
            ExpenseEntriesCompanion.insert(
              expenseId: 'exp-both',
              businessId: 'biz-1',
              storeId: 'loc-1',
              category: 'rent',
              amount: Decimal.parse('5.00'),
              occurredAt: DateTime.now(),
              actorUserId: 'staff-1',
              createdAt: DateTime.now(),
            ),
          );
      await insertIncome('inc-both');

      await syncService.syncNow();

      final expenseRow = await database.select(database.expenseEntries).getSingle();
      final incomeRow = await database.select(database.otherIncomeEntries).getSingle();
      expect(expenseRow.syncStatus, 'synced');
      expect(incomeRow.syncStatus, 'synced');
    });
  });
}
