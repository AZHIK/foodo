/// Pluggable interface for syncing other-expense/other-income entries and
/// receipt uploads to POS Service.
///
/// Mirrors `pos_sync_api.dart`'s role for sales. `FakeFinanceSyncApi`
/// provides test/demo behavior; `HttpFinanceSyncApi` calls the real
/// `/other-expenses/sync`, `/other-incomes/sync`, and
/// `/finance/attachments` endpoints.
library;

import 'dart:typed_data';

import 'finance_sync_dtos.dart';

/// Pluggable API for syncing finance entries and receipts.
abstract class FinanceSyncApi {
  /// Syncs a batch of pending expense entries.
  Future<FinanceSyncBatchResult> syncExpenses(List<OtherExpenseDto> batch);

  /// Syncs a batch of pending income entries.
  Future<FinanceSyncBatchResult> syncIncomes(List<OtherIncomeDto> batch);

  /// Uploads a receipt file and returns the server-assigned attachment id.
  Future<String> uploadReceipt({
    required Uint8List bytes,
    required String filename,
    required String contentType,
  });
}
