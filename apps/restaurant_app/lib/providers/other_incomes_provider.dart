import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_finance.dart';
import '../models/order.dart';
import '../models/other_income.dart';
import '../models/table_query.dart';
import 'table_query_provider.dart';

abstract final class OtherIncomeSort {
  static const date = 'date';
  static const category = 'category';
  static const description = 'description';
  static const amount = 'amount';
  static const source = 'source';
  static const payment = 'payment';
}

class OtherIncomesNotifier extends Notifier<List<OtherIncome>> {
  @override
  List<OtherIncome> build() => List.of(MockFinance.incomes);

  void upsert(OtherIncome income) {
    final index = state.indexWhere((i) => i.id == income.id);
    if (index == -1) {
      state = [income, ...state];
      return;
    }
    final next = [...state];
    next[index] = income;
    state = next;
  }

  void delete(String id) =>
      state = state.where((income) => income.id != id).toList();

  String nextId() {
    var highest = 0;
    for (final income in state) {
      final n = int.tryParse(income.id.split('-').last);
      if (n != null && n > highest) highest = n;
    }
    return 'inc-${(highest + 1).toString().padLeft(2, '0')}';
  }
}

final otherIncomesProvider =
    NotifierProvider<OtherIncomesNotifier, List<OtherIncome>>(
      OtherIncomesNotifier.new,
    );

// ---------------------------------------------------------------------------
// Search / sort / pagination
// ---------------------------------------------------------------------------

final otherIncomesQueryProvider = NotifierProvider<TableQueryNotifier, TableQuery>(
  () => TableQueryNotifier(
    const TableQuery(sortField: OtherIncomeSort.date, ascending: false, pageSize: 8),
  ),
);

// ---------------------------------------------------------------------------
// Filters
// ---------------------------------------------------------------------------

@immutable
class OtherIncomeFilters {
  const OtherIncomeFilters({
    this.categoryIds = const {},
    this.payments = const {},
    this.dateRange,
  });

  final Set<String> categoryIds;
  final Set<PaymentType> payments;
  final DateTimeRange? dateRange;

  bool get hasDateRange => dateRange != null;

  int get activeCount =>
      categoryIds.length + payments.length + (hasDateRange ? 1 : 0);

  bool matches(OtherIncome income) {
    if (categoryIds.isNotEmpty && !categoryIds.contains(income.categoryId)) {
      return false;
    }
    if (payments.isNotEmpty && !payments.contains(income.paymentType)) {
      return false;
    }
    if (dateRange != null &&
        (income.date.isBefore(dateRange!.start) ||
            income.date.isAfter(dateRange!.end))) {
      return false;
    }
    return true;
  }

  OtherIncomeFilters copyWith({
    Set<String>? categoryIds,
    Set<PaymentType>? payments,
    DateTimeRange? dateRange,
    bool clearDateRange = false,
  }) {
    return OtherIncomeFilters(
      categoryIds: categoryIds ?? this.categoryIds,
      payments: payments ?? this.payments,
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
    );
  }
}

class OtherIncomeFiltersNotifier extends Notifier<OtherIncomeFilters> {
  @override
  OtherIncomeFilters build() => const OtherIncomeFilters();

  void toggleCategory(String id) {
    final next = Set<String>.of(state.categoryIds);
    next.contains(id) ? next.remove(id) : next.add(id);
    state = state.copyWith(categoryIds: next);
    _resetPage();
  }

  void togglePayment(PaymentType payment) {
    final next = Set<PaymentType>.of(state.payments);
    next.contains(payment) ? next.remove(payment) : next.add(payment);
    state = state.copyWith(payments: next);
    _resetPage();
  }

  void setDateRange(DateTimeRange? range) {
    state = range == null
        ? state.copyWith(clearDateRange: true)
        : state.copyWith(dateRange: range);
    _resetPage();
  }

  void clear() {
    state = const OtherIncomeFilters();
    _resetPage();
  }

  void _resetPage() => ref.read(otherIncomesQueryProvider.notifier).resetPage();
}

final otherIncomeFiltersProvider =
    NotifierProvider<OtherIncomeFiltersNotifier, OtherIncomeFilters>(
      OtherIncomeFiltersNotifier.new,
    );

// ---------------------------------------------------------------------------
// Derived views
// ---------------------------------------------------------------------------

final filteredOtherIncomesProvider = Provider<List<OtherIncome>>((ref) {
  final incomes = ref.watch(otherIncomesProvider);
  final query = ref.watch(otherIncomesQueryProvider);
  final filters = ref.watch(otherIncomeFiltersProvider);
  final search = query.search.trim().toLowerCase();

  final rows = incomes.where((income) {
    if (!filters.matches(income)) return false;
    if (search.isEmpty) return true;
    return income.description.toLowerCase().contains(search) ||
        income.source.toLowerCase().contains(search) ||
        MockFinance.incomeCategoryLabel(income.categoryId)
            .toLowerCase()
            .contains(search) ||
        income.paymentType.label.toLowerCase().contains(search);
  }).toList();

  final direction = query.ascending ? 1 : -1;
  rows.sort((a, b) {
    final cmp = switch (query.sortField) {
      OtherIncomeSort.date => a.date.compareTo(b.date),
      OtherIncomeSort.category => MockFinance.incomeCategoryLabel(a.categoryId)
          .compareTo(MockFinance.incomeCategoryLabel(b.categoryId)),
      OtherIncomeSort.description =>
          a.description.toLowerCase().compareTo(b.description.toLowerCase()),
      OtherIncomeSort.amount => a.amount.compareTo(b.amount),
      OtherIncomeSort.source =>
          a.source.toLowerCase().compareTo(b.source.toLowerCase()),
      OtherIncomeSort.payment =>
          a.paymentType.label.compareTo(b.paymentType.label),
      _ => a.date.compareTo(b.date),
    };
    return cmp != 0 ? cmp * direction : a.id.compareTo(b.id);
  });

  return rows;
});

final otherIncomesSliceProvider = Provider<PageSlice<OtherIncome>>(
  (ref) => PageSlice.of(
    ref.watch(filteredOtherIncomesProvider),
    ref.watch(otherIncomesQueryProvider),
  ),
);

@immutable
class OtherIncomesSummary {
  const OtherIncomesSummary({
    required this.total,
    required this.entryCount,
  });

  final double total;
  final int entryCount;

  double get average => entryCount == 0 ? 0 : total / entryCount;
}

final otherIncomesSummaryProvider = Provider<OtherIncomesSummary>((ref) {
  final incomes = ref.watch(filteredOtherIncomesProvider);
  var total = 0.0;
  for (final income in incomes) {
    total += income.amount;
  }

  return OtherIncomesSummary(
    total: total,
    entryCount: incomes.length,
  );
});
