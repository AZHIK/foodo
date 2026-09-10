/// Fake implementation of FinanceCatalogApi for testing and demo mode.
library;

import 'finance_catalog_api.dart';

/// Fake finance catalog API — returns nothing by default (demo mode has no
/// server-side ledger to pull; `OtherExpensesNotifier`/`OtherIncomesNotifier`
/// fall back to `MockFinance` directly rather than routing through this).
class FakeFinanceCatalogApi extends FinanceCatalogApi {
  final List<OtherExpenseServerDto> expenses;
  final List<OtherIncomeServerDto> incomes;

  FakeFinanceCatalogApi({this.expenses = const [], this.incomes = const []});

  @override
  Future<List<OtherExpenseServerDto>> fetchExpenses({
    required String storeId,
  }) async =>
      expenses.where((e) => e.storeId == storeId).toList();

  @override
  Future<List<OtherIncomeServerDto>> fetchIncomes({
    required String storeId,
  }) async =>
      incomes.where((i) => i.storeId == storeId).toList();
}
