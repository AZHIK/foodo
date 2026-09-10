/// Fake implementation of FinanceSyncApi for testing and demo mode.
///
/// Mirrors `FakeSyncApi`'s behavior knobs.
library;

import 'dart:typed_data';
import 'package:uuid/uuid.dart';

import 'finance_sync_api.dart';
import 'finance_sync_dtos.dart';

/// Fake finance sync API for testing behavior.
class FakeFinanceSyncApi extends FinanceSyncApi {
  /// If true, all entries fail.
  final bool alwaysFail;

  /// If true, the entire call throws (simulates network error).
  final bool throwsNetworkError;

  /// Map from client entry id -> custom result. Overrides default behavior.
  final Map<String, FinanceSyncRowResult> overrides;

  FakeFinanceSyncApi({
    this.alwaysFail = false,
    this.throwsNetworkError = false,
    this.overrides = const {},
  });

  @override
  Future<FinanceSyncBatchResult> syncExpenses(
    List<OtherExpenseDto> batch,
  ) async {
    if (throwsNetworkError) {
      throw FinanceNetworkException('Simulated network error');
    }
    return FinanceSyncBatchResult(
      results: [for (final e in batch) _resultFor(e.clientExpenseId)],
    );
  }

  @override
  Future<FinanceSyncBatchResult> syncIncomes(
    List<OtherIncomeDto> batch,
  ) async {
    if (throwsNetworkError) {
      throw FinanceNetworkException('Simulated network error');
    }
    return FinanceSyncBatchResult(
      results: [for (final i in batch) _resultFor(i.clientIncomeId)],
    );
  }

  @override
  Future<String> uploadReceipt({
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    if (throwsNetworkError) {
      throw FinanceNetworkException('Simulated network error');
    }
    return const Uuid().v4();
  }

  FinanceSyncRowResult _resultFor(String clientEntryId) {
    final override = overrides[clientEntryId];
    if (override != null) return override;
    if (alwaysFail) {
      return FinanceSyncRowResult(
        clientEntryId: clientEntryId,
        status: 'failed',
        reason: 'Simulated failure',
      );
    }
    return FinanceSyncRowResult(clientEntryId: clientEntryId, status: 'created');
  }
}

/// Network error for testing.
class FinanceNetworkException implements Exception {
  final String message;
  FinanceNetworkException(this.message);
  @override
  String toString() => 'FinanceNetworkException: $message';
}
