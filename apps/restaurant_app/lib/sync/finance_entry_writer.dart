/// Writes new expense/income entries to their outbox tables for sync.
///
/// The producer side for `FinanceSyncService`, mirroring `PendingSaleWriter`.
/// Unlike a sale (which is skipped entirely if its items don't resolve to a
/// catalog), a finance entry has no such precondition — it always writes and
/// returns the client-generated id.
library;

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import 'order_mapper.dart' show paymentMethodToBackend;
import '../models/order.dart' show PaymentType;

/// Writes expense/income entries to their sync outbox tables.
class FinanceEntryWriter {
  final AppDatabase _db;

  FinanceEntryWriter(this._db);

  /// Writes a new expense to the outbox and returns its client-generated id.
  Future<String> writeExpense({
    required String storeId,
    required String businessId,
    required String actorUserId,
    required DateTime occurredAt,
    required String category,
    required Decimal amount,
    required String description,
    required PaymentType paymentType,
    String? payee,
    String? note,
    String? localReceiptPath,
  }) async {
    final clientExpenseId = const Uuid().v4();
    await _db.into(_db.expenseEntries).insert(
      ExpenseEntriesCompanion.insert(
        expenseId: clientExpenseId,
        businessId: businessId,
        storeId: storeId,
        category: category,
        amount: amount,
        description: Value(description),
        payee: Value(payee),
        note: Value(note),
        paymentMethod: Value(paymentMethodToBackend(paymentType)),
        localReceiptPath: Value(localReceiptPath),
        occurredAt: occurredAt,
        actorUserId: actorUserId,
        createdAt: DateTime.now(),
      ),
    );
    return clientExpenseId;
  }

  /// Writes a new income entry to the outbox and returns its client-generated id.
  Future<String> writeIncome({
    required String storeId,
    required String businessId,
    required String actorUserId,
    required DateTime occurredAt,
    required String category,
    required Decimal amount,
    required String description,
    required PaymentType paymentType,
    String? source,
    String? note,
    String? localReceiptPath,
  }) async {
    final clientIncomeId = const Uuid().v4();
    await _db.into(_db.otherIncomeEntries).insert(
      OtherIncomeEntriesCompanion.insert(
        incomeId: clientIncomeId,
        businessId: businessId,
        storeId: storeId,
        category: category,
        amount: amount,
        description: Value(description),
        source: Value(source),
        note: Value(note),
        paymentMethod: Value(paymentMethodToBackend(paymentType)),
        localReceiptPath: Value(localReceiptPath),
        occurredAt: occurredAt,
        actorUserId: actorUserId,
        createdAt: DateTime.now(),
      ),
    );
    return clientIncomeId;
  }
}
