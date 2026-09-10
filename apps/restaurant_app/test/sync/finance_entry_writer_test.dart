/// Tests for `FinanceEntryWriter` — the bridge from a saved expense/income
/// form onto the `ExpenseEntries`/`OtherIncomeEntries` outbox.
library;

import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/database/app_database.dart';
import 'package:restaurant_pos/models/order.dart';
import 'package:restaurant_pos/sync/finance_entry_writer.dart';

void main() {
  group('FinanceEntryWriter', () {
    late AppDatabase database;
    late FinanceEntryWriter writer;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      writer = FinanceEntryWriter(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('writeExpense inserts a pending outbox row with a UUID client id', () async {
      final clientId = await writer.writeExpense(
        storeId: 'store-1',
        businessId: 'biz-1',
        actorUserId: 'staff-1',
        occurredAt: DateTime(2026, 1, 1),
        category: 'rent',
        amount: Decimal.parse('120.50'),
        description: 'Monthly rent',
        paymentType: PaymentType.card,
        payee: 'Landlord Co.',
      );

      expect(clientId, isNotEmpty);
      expect(clientId.length, 36); // UUID v4 canonical length

      final rows = await database.select(database.expenseEntries).get();
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.expenseId, clientId);
      expect(row.businessId, 'biz-1');
      expect(row.storeId, 'store-1');
      expect(row.category, 'rent');
      expect(row.amount, Decimal.parse('120.50'));
      expect(row.description, 'Monthly rent');
      expect(row.payee, 'Landlord Co.');
      expect(row.paymentMethod, 'card');
      expect(row.actorUserId, 'staff-1');
      expect(row.syncStatus, 'pending');
    });

    test('writeIncome inserts a pending outbox row', () async {
      final clientId = await writer.writeIncome(
        storeId: 'store-1',
        businessId: 'biz-1',
        actorUserId: 'staff-1',
        occurredAt: DateTime(2026, 1, 1),
        category: 'catering',
        amount: Decimal.parse('300.00'),
        description: 'Wedding deposit',
        paymentType: PaymentType.mobile,
        source: 'J. Doe',
      );

      final rows = await database.select(database.otherIncomeEntries).get();
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.incomeId, clientId);
      expect(row.category, 'catering');
      expect(row.source, 'J. Doe');
      expect(row.paymentMethod, 'mobile_money');
      expect(row.syncStatus, 'pending');
    });

    test('each write gets a distinct client id', () async {
      final id1 = await writer.writeExpense(
        storeId: 's1',
        businessId: 'b1',
        actorUserId: 'u1',
        occurredAt: DateTime.now(),
        category: 'rent',
        amount: Decimal.one,
        description: 'a',
        paymentType: PaymentType.cash,
      );
      final id2 = await writer.writeExpense(
        storeId: 's1',
        businessId: 'b1',
        actorUserId: 'u1',
        occurredAt: DateTime.now(),
        category: 'rent',
        amount: Decimal.one,
        description: 'b',
        paymentType: PaymentType.cash,
      );
      expect(id1, isNot(equals(id2)));
    });
  });
}
