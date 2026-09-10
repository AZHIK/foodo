/// Maps POS Service's cached/outbox finance rows onto the UI's
/// `OtherExpense`/`OtherIncome` models.
///
/// The read-side counterpart to `finance_entry_writer.dart`. Reuses
/// `paymentMethodToBackend`/`paymentMethodFromBackend` from `order_mapper.dart`
/// rather than re-implementing the same lossy `PaymentType` <-> backend
/// `PaymentMethod` mapping a second time.
library;

import 'package:decimal/decimal.dart';

import '../database/app_database.dart';
import '../models/finance_attachment.dart';
import '../models/other_expense.dart';
import '../models/other_income.dart';
import 'order_mapper.dart';

/// Re-exported so callers building sync DTOs only need to import this one
/// file for both the model mappers and the payment-method conversion.
export 'order_mapper.dart' show paymentMethodToBackend, paymentMethodFromBackend;

double _toDouble(Decimal value) => double.parse(value.toString());

FinanceAttachment? _attachmentFromRemoteId(String? remoteId) =>
    remoteId == null ? null : FinanceAttachment(name: 'Receipt', remoteId: remoteId);

/// Maps a pulled, already-synced expense row to the UI model.
OtherExpense otherExpenseFromCachedRow(CachedOtherExpense row) => OtherExpense(
      id: row.id,
      date: row.occurredAt,
      categoryId: row.category,
      description: row.description,
      amount: _toDouble(row.amount),
      paymentType: paymentMethodFromBackend(row.paymentMethod),
      payee: row.payee ?? '',
      note: row.note ?? '',
      receipt: _attachmentFromRemoteId(row.receiptAttachmentId),
      serverId: row.id,
      syncStatus: 'synced',
    );

/// Maps a not-yet-(fully-)synced outbox row to the UI model, so a
/// locally-created expense is visible immediately and survives a restart
/// before its background sync completes.
OtherExpense otherExpenseFromOutboxRow(ExpenseEntry row) => OtherExpense(
      id: row.expenseId,
      date: row.occurredAt,
      categoryId: row.category,
      description: row.description ?? '',
      amount: _toDouble(row.amount),
      paymentType: paymentMethodFromBackend(row.paymentMethod),
      payee: row.payee ?? '',
      note: row.note ?? '',
      receipt: row.localReceiptPath != null || row.receiptAttachmentId != null
          ? FinanceAttachment(
              name: 'Receipt',
              remoteId: row.receiptAttachmentId,
              localPath: row.localReceiptPath,
            )
          : null,
      serverId: row.serverId,
      syncStatus: row.syncStatus,
    );

/// Maps a pulled, already-synced income row to the UI model.
OtherIncome otherIncomeFromCachedRow(CachedOtherIncome row) => OtherIncome(
      id: row.id,
      date: row.occurredAt,
      categoryId: row.category,
      description: row.description,
      amount: _toDouble(row.amount),
      paymentType: paymentMethodFromBackend(row.paymentMethod),
      source: row.source ?? '',
      note: row.note ?? '',
      receipt: _attachmentFromRemoteId(row.receiptAttachmentId),
      serverId: row.id,
      syncStatus: 'synced',
    );

/// Maps a not-yet-(fully-)synced outbox row to the UI model.
OtherIncome otherIncomeFromOutboxRow(OtherIncomeEntry row) => OtherIncome(
      id: row.incomeId,
      date: row.occurredAt,
      categoryId: row.category,
      description: row.description ?? '',
      amount: _toDouble(row.amount),
      paymentType: paymentMethodFromBackend(row.paymentMethod),
      source: row.source ?? '',
      note: row.note ?? '',
      receipt: row.localReceiptPath != null || row.receiptAttachmentId != null
          ? FinanceAttachment(
              name: 'Receipt',
              remoteId: row.receiptAttachmentId,
              localPath: row.localReceiptPath,
            )
          : null,
      serverId: row.serverId,
      syncStatus: row.syncStatus,
    );
