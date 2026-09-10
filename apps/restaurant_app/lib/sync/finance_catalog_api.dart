/// Pluggable interface for fetching the other-expenses/other-incomes ledger
/// from POS Service.
///
/// The read-side counterpart to `finance_sync_api.dart`, mirroring how
/// `pos_catalog_api.dart` pairs with `pos_sync_api.dart`. `FakeFinanceCatalogApi`
/// provides test/demo behavior; `HttpFinanceCatalogApi` calls the real
/// `GET /other-expenses` and `GET /other-incomes` endpoints.
library;

import 'package:decimal/decimal.dart';

/// Mirrors the backend's `OtherExpenseRead`/`OtherExpenseListItem`.
class OtherExpenseServerDto {
  final String id;
  final String businessId;
  final String storeId;
  final String clientExpenseId;
  final String category;
  final Decimal amount;
  final String description;
  final String? payee;
  final String? note;
  final String paymentMethod;
  final String? receiptAttachmentId;
  final String? actorId;
  final DateTime occurredAt;
  final DateTime syncedAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final DateTime createdAt;

  OtherExpenseServerDto({
    required this.id,
    required this.businessId,
    required this.storeId,
    required this.clientExpenseId,
    required this.category,
    required this.amount,
    required this.description,
    this.payee,
    this.note,
    required this.paymentMethod,
    this.receiptAttachmentId,
    this.actorId,
    required this.occurredAt,
    required this.syncedAt,
    required this.updatedAt,
    required this.isDeleted,
    required this.createdAt,
  });
}

/// Mirrors the backend's `OtherIncomeRead`/`OtherIncomeListItem`.
class OtherIncomeServerDto {
  final String id;
  final String businessId;
  final String storeId;
  final String clientIncomeId;
  final String category;
  final Decimal amount;
  final String description;
  final String? source;
  final String? note;
  final String paymentMethod;
  final String? receiptAttachmentId;
  final String? actorId;
  final DateTime occurredAt;
  final DateTime syncedAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final DateTime createdAt;

  OtherIncomeServerDto({
    required this.id,
    required this.businessId,
    required this.storeId,
    required this.clientIncomeId,
    required this.category,
    required this.amount,
    required this.description,
    this.source,
    this.note,
    required this.paymentMethod,
    this.receiptAttachmentId,
    this.actorId,
    required this.occurredAt,
    required this.syncedAt,
    required this.updatedAt,
    required this.isDeleted,
    required this.createdAt,
  });
}

/// Pluggable API for fetching the finance ledgers.
abstract class FinanceCatalogApi {
  /// Fetches other expenses for a store, including soft-deleted rows (so a
  /// delete made on another device propagates into this device's cache —
  /// see `finance_ledger_sync_service.dart`).
  Future<List<OtherExpenseServerDto>> fetchExpenses({required String storeId});

  /// Fetches other incomes for a store, including soft-deleted rows.
  Future<List<OtherIncomeServerDto>> fetchIncomes({required String storeId});
}
