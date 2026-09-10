/// Tests for the finance read-side mapper: cached-row and outbox-row ->
/// `OtherExpense`/`OtherIncome` mapping, and category id round-tripping.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/database/app_database.dart';
import 'package:restaurant_pos/models/order.dart';
import 'package:restaurant_pos/sync/finance_entry_mapper.dart';

void main() {
  group('otherExpenseFromCachedRow', () {
    test('maps a synced cached expense row', () {
      final row = CachedOtherExpense(
        id: 'srv-1',
        businessId: 'biz-1',
        storeId: 'store-1',
        clientExpenseId: 'client-1',
        category: 'rent',
        amount: Decimal.parse('300.00'),
        description: 'Monthly rent',
        payee: 'Landlord Co.',
        note: null,
        paymentMethod: 'card',
        receiptAttachmentId: null,
        actorId: 'staff-1',
        occurredAt: DateTime(2026, 1, 5),
        syncedAt: DateTime(2026, 1, 5, 1),
        updatedAt: DateTime(2026, 1, 5, 1),
        isDeleted: false,
        createdAt: DateTime(2026, 1, 5),
        lastSyncedAt: DateTime(2026, 1, 6),
      );

      final expense = otherExpenseFromCachedRow(row);

      expect(expense.id, 'srv-1');
      expect(expense.serverId, 'srv-1');
      expect(expense.categoryId, 'rent');
      expect(expense.amount, 300.00);
      expect(expense.payee, 'Landlord Co.');
      expect(expense.paymentType, PaymentType.card);
      expect(expense.syncStatus, 'synced');
      expect(expense.receipt, isNull);
    });

    test('a receipt_attachment_id becomes a receipt with only remoteId set', () {
      final row = CachedOtherExpense(
        id: 'srv-1',
        businessId: 'biz-1',
        storeId: 'store-1',
        clientExpenseId: 'client-1',
        category: 'rent',
        amount: Decimal.parse('1.00'),
        description: 'x',
        payee: null,
        note: null,
        paymentMethod: 'cash',
        receiptAttachmentId: 'attach-1',
        actorId: null,
        occurredAt: DateTime(2026),
        syncedAt: DateTime(2026),
        updatedAt: DateTime(2026),
        isDeleted: false,
        createdAt: DateTime(2026),
        lastSyncedAt: DateTime(2026),
      );

      final expense = otherExpenseFromCachedRow(row);
      expect(expense.receipt, isNotNull);
      expect(expense.receipt!.remoteId, 'attach-1');
      expect(expense.receipt!.bytes, isNull);
    });
  });

  group('otherExpenseFromOutboxRow', () {
    test('maps a pending outbox row with syncStatus preserved', () {
      final row = ExpenseEntry(
        id: 1,
        expenseId: 'client-1',
        businessId: 'biz-1',
        storeId: 'store-1',
        category: 'utilities',
        amount: Decimal.parse('45.00'),
        description: 'Electricity',
        payee: null,
        note: 'urgent',
        paymentMethod: 'mobile_money',
        receiptAttachmentId: null,
        localReceiptPath: null,
        occurredAt: DateTime(2026, 2, 1),
        actorUserId: 'staff-1',
        serverId: null,
        syncStatus: 'pending',
        syncError: null,
        syncAttemptCount: 0,
        lastAttemptAt: null,
        syncedAt: null,
        createdAt: DateTime(2026, 2, 1),
      );

      final expense = otherExpenseFromOutboxRow(row);

      expect(expense.id, 'client-1');
      expect(expense.serverId, isNull);
      expect(expense.syncStatus, 'pending');
      expect(expense.categoryId, 'utilities');
      expect(expense.note, 'urgent');
      expect(expense.paymentType, PaymentType.mobile);
    });

    test('a local receipt path with no attachment id yet is still surfaced', () {
      final row = ExpenseEntry(
        id: 1,
        expenseId: 'client-1',
        businessId: 'biz-1',
        storeId: 'store-1',
        category: 'rent',
        amount: Decimal.parse('1.00'),
        description: 'x',
        payee: null,
        note: null,
        paymentMethod: 'cash',
        receiptAttachmentId: null,
        localReceiptPath: '/tmp/receipt.jpg',
        occurredAt: DateTime(2026),
        actorUserId: 'staff-1',
        serverId: null,
        syncStatus: 'pending',
        syncError: null,
        syncAttemptCount: 0,
        lastAttemptAt: null,
        syncedAt: null,
        createdAt: DateTime(2026),
      );

      final expense = otherExpenseFromOutboxRow(row);
      expect(expense.receipt, isNotNull);
      expect(expense.receipt!.localPath, '/tmp/receipt.jpg');
      expect(expense.receipt!.remoteId, isNull);
    });
  });

  group('otherIncomeFromCachedRow / otherIncomeFromOutboxRow', () {
    test('maps source instead of payee', () {
      final cachedRow = CachedOtherIncome(
        id: 'srv-1',
        businessId: 'biz-1',
        storeId: 'store-1',
        clientIncomeId: 'client-1',
        category: 'catering',
        amount: Decimal.parse('900.00'),
        description: 'Wedding deposit',
        source: 'J. Doe',
        note: null,
        paymentMethod: 'mobile_money',
        receiptAttachmentId: null,
        actorId: null,
        occurredAt: DateTime(2026),
        syncedAt: DateTime(2026),
        updatedAt: DateTime(2026),
        isDeleted: false,
        createdAt: DateTime(2026),
        lastSyncedAt: DateTime(2026),
      );

      final income = otherIncomeFromCachedRow(cachedRow);
      expect(income.source, 'J. Doe');
      expect(income.paymentType, PaymentType.mobile);
      expect(income.syncStatus, 'synced');
    });
  });

  group('paymentMethodToBackend / paymentMethodFromBackend round-trip', () {
    test('cash, card, and mobile round-trip exactly', () {
      for (final type in [PaymentType.cash, PaymentType.card, PaymentType.mobile]) {
        final backend = paymentMethodToBackend(type);
        expect(paymentMethodFromBackend(backend), type);
      }
    });
  });
}
