import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_finance.dart';
import '../models/order.dart';
import '../models/other_expense.dart';
import '../models/table_query.dart';
import 'table_query_provider.dart';

abstract final class OtherExpenseSort {
  static const date = 'date';
  static const category = 'category';
  static const description = 'description';
  static const amount = 'amount';
  static const payee = 'payee';
  static const payment = 'payment';
}

class OtherExpensesNotifier extends Notifier<List<OtherExpense>> {
  @override
  List<OtherExpense> build() => List.of(MockFinance.expenses);
  void upsert(OtherExpense expense) {
    final index = state.indexWhere((e) => e.id == expense.id);
    if (index == -1) {
      state = [expense, ...state];
    } else {
      final next = [...state];
      next[index] = expense;
      state = next;
    }
  }
  void delete(String id) => state = state.where((e) => e.id != id).toList();
  String nextId() {
    var highest = 0;
    for (final e in state) {
      final n = int.tryParse(e.id.split('-').last);
      if (n != null && n > highest) highest = n;
    }
    return 'exp-${(highest + 1).toString().padLeft(2, '0')}';
  }
}

final otherExpensesProvider = NotifierProvider<OtherExpensesNotifier, List<OtherExpense>>(OtherExpensesNotifier.new);

final otherExpensesQueryProvider = NotifierProvider<TableQueryNotifier, TableQuery>(
  () => TableQueryNotifier(const TableQuery(sortField: OtherExpenseSort.date, ascending: false, pageSize: 8)),
);

@immutable
class OtherExpenseFilters {
  const OtherExpenseFilters({this.categoryIds = const {}, this.payments = const {}, this.dateRange});
  final Set<String> categoryIds;
  final Set<PaymentType> payments;
  final DateTimeRange? dateRange;
  int get activeCount => categoryIds.length + payments.length + (dateRange == null ? 0 : 1);
  bool matches(OtherExpense e) {
    if (categoryIds.isNotEmpty && !categoryIds.contains(e.categoryId)) return false;
    if (payments.isNotEmpty && !payments.contains(e.paymentType)) return false;
    if (dateRange != null && (e.date.isBefore(dateRange!.start) || e.date.isAfter(dateRange!.end))) return false;
    return true;
  }
  OtherExpenseFilters copyWith({Set<String>? categoryIds, Set<PaymentType>? payments, DateTimeRange? dateRange, bool clearDateRange = false}) {
    return OtherExpenseFilters(categoryIds: categoryIds ?? this.categoryIds, payments: payments ?? this.payments, dateRange: clearDateRange ? null : (dateRange ?? this.dateRange));
  }
}

class OtherExpenseFiltersNotifier extends Notifier<OtherExpenseFilters> {
  @override
  OtherExpenseFilters build() => const OtherExpenseFilters();
  void toggleCategory(String id) {
    final next = Set<String>.of(state.categoryIds);
    next.contains(id) ? next.remove(id) : next.add(id);
    state = state.copyWith(categoryIds: next);
    _resetPage();
  }
  void togglePayment(PaymentType p) {
    final next = Set<PaymentType>.of(state.payments);
    next.contains(p) ? next.remove(p) : next.add(p);
    state = state.copyWith(payments: next);
    _resetPage();
  }
  void setDateRange(DateTimeRange? range) {
    state = range == null ? state.copyWith(clearDateRange: true) : state.copyWith(dateRange: range);
    _resetPage();
  }
  void clear() {
    state = const OtherExpenseFilters();
    _resetPage();
  }
  void _resetPage() => ref.read(otherExpensesQueryProvider.notifier).resetPage();
}

final otherExpenseFiltersProvider = NotifierProvider<OtherExpenseFiltersNotifier, OtherExpenseFilters>(OtherExpenseFiltersNotifier.new);

final filteredOtherExpensesProvider = Provider<List<OtherExpense>>((ref) {
  final expenses = ref.watch(otherExpensesProvider);
  final query = ref.watch(otherExpensesQueryProvider);
  final filters = ref.watch(otherExpenseFiltersProvider);
  final search = query.search.trim().toLowerCase();
  final rows = expenses.where((e) {
    if (!filters.matches(e)) return false;
    if (search.isEmpty) return true;
    return e.description.toLowerCase().contains(search) || e.payee.toLowerCase().contains(search) || MockFinance.expenseCategoryLabel(e.categoryId).toLowerCase().contains(search) || e.paymentType.label.toLowerCase().contains(search);
  }).toList();
  final direction = query.ascending ? 1 : -1;
  rows.sort((a, b) {
    final cmp = switch (query.sortField) {
      OtherExpenseSort.date => a.date.compareTo(b.date),
      OtherExpenseSort.category => MockFinance.expenseCategoryLabel(a.categoryId).compareTo(MockFinance.expenseCategoryLabel(b.categoryId)),
      OtherExpenseSort.description => a.description.toLowerCase().compareTo(b.description.toLowerCase()),
      OtherExpenseSort.amount => a.amount.compareTo(b.amount),
      OtherExpenseSort.payee => a.payee.toLowerCase().compareTo(b.payee.toLowerCase()),
      OtherExpenseSort.payment => a.paymentType.label.compareTo(b.paymentType.label),
      _ => a.date.compareTo(b.date),
    };
    return cmp != 0 ? cmp * direction : a.id.compareTo(b.id);
  });
  return rows;
});

final otherExpensesSliceProvider = Provider<PageSlice<OtherExpense>>((ref) => PageSlice.of(ref.watch(filteredOtherExpensesProvider), ref.watch(otherExpensesQueryProvider)));

@immutable
class OtherExpensesSummary {
  const OtherExpensesSummary({required this.total, required this.entryCount, required this.largestCategoryLabel, required this.largestCategoryAmount});
  final double total;
  final int entryCount;
  final String largestCategoryLabel;
  final double largestCategoryAmount;
  double get average => entryCount == 0 ? 0 : total / entryCount;
}

final otherExpensesSummaryProvider = Provider<OtherExpensesSummary>((ref) {
  final expenses = ref.watch(filteredOtherExpensesProvider);
  var total = 0.0;
  final byCategory = <String, double>{};
  for (final e in expenses) {
    total += e.amount;
    byCategory[e.categoryId] = (byCategory[e.categoryId] ?? 0) + e.amount;
  }
  final largest = byCategory.isEmpty ? null : byCategory.entries.reduce((a, b) => a.value > b.value ? a : b);
  return OtherExpensesSummary(total: total, entryCount: expenses.length, largestCategoryLabel: largest == null ? '—' : MockFinance.expenseCategoryLabel(largest.key), largestCategoryAmount: largest?.value ?? 0);
});
