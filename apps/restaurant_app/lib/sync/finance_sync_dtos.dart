/// Data transfer objects for the finance sync API layer (push side).
///
/// Mirrors `sync_dtos.dart`'s shape for sales — hand-written, decoupled from
/// Drift-generated row types. A separate file from `sync_dtos.dart` rather
/// than reusing its types: `SyncRowResult.clientSaleId` is sales-specific,
/// and expense/income batches carry different fields (`category`, `payee`/
/// `source`, `receiptAttachmentId`) than a sale ever would.
library;

import 'package:decimal/decimal.dart';

/// A pending expense entry ready for sync.
class OtherExpenseDto {
  final String clientExpenseId;
  final String storeId;
  final String category;
  final Decimal amount;
  final String description;
  final String paymentMethod;
  final String? payee;
  final String? note;
  final String? receiptAttachmentId;
  final DateTime occurredAt;
  final int? deviceSequence;

  OtherExpenseDto({
    required this.clientExpenseId,
    required this.storeId,
    required this.category,
    required this.amount,
    required this.description,
    required this.paymentMethod,
    this.payee,
    this.note,
    this.receiptAttachmentId,
    required this.occurredAt,
    this.deviceSequence,
  });

  Map<String, dynamic> toJson() => {
    'client_expense_id': clientExpenseId,
    'store_id': storeId,
    'category': category,
    'amount': amount.toString(),
    'description': description,
    'payment_method': paymentMethod,
    'payee': payee,
    'note': note,
    'receipt_attachment_id': receiptAttachmentId,
    // See `PendingSaleDto.toJson`'s comment: `.toUtc()` first is what
    // actually makes `occurred_at` UTC on the wire.
    'occurred_at': occurredAt.toUtc().toIso8601String(),
    'device_sequence': deviceSequence,
  };
}

/// A pending income entry ready for sync.
class OtherIncomeDto {
  final String clientIncomeId;
  final String storeId;
  final String category;
  final Decimal amount;
  final String description;
  final String paymentMethod;
  final String? source;
  final String? note;
  final String? receiptAttachmentId;
  final DateTime occurredAt;
  final int? deviceSequence;

  OtherIncomeDto({
    required this.clientIncomeId,
    required this.storeId,
    required this.category,
    required this.amount,
    required this.description,
    required this.paymentMethod,
    this.source,
    this.note,
    this.receiptAttachmentId,
    required this.occurredAt,
    this.deviceSequence,
  });

  Map<String, dynamic> toJson() => {
    'client_income_id': clientIncomeId,
    'store_id': storeId,
    'category': category,
    'amount': amount.toString(),
    'description': description,
    'payment_method': paymentMethod,
    'source': source,
    'note': note,
    'receipt_attachment_id': receiptAttachmentId,
    'occurred_at': occurredAt.toUtc().toIso8601String(),
    'device_sequence': deviceSequence,
  };
}

/// Result of syncing one expense or income entry.
class FinanceSyncRowResult {
  final String clientEntryId;
  final String status; // 'created' | 'duplicate' | 'failed'
  final String? reason;

  FinanceSyncRowResult({
    required this.clientEntryId,
    required this.status,
    this.reason,
  });
}

/// Batch result from the finance sync API.
class FinanceSyncBatchResult {
  final List<FinanceSyncRowResult> results;

  FinanceSyncBatchResult({required this.results});
}
