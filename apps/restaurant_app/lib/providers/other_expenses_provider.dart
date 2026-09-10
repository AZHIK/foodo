import 'dart:async';
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../data/mock_finance.dart';
import '../database/app_database.dart';
import '../models/finance_attachment.dart';
import '../models/order.dart';
import '../models/other_expense.dart';
import '../models/table_query.dart';
import '../sync/finance_entry_mapper.dart';
import 'database_providers.dart';
import 'finance_api_provider.dart';
import 'permissions_provider.dart';
import 'session_provider.dart';
import 'table_query_provider.dart';

abstract final class OtherExpenseSort {
  static const date = 'date';
  static const category = 'category';
  static const description = 'description';
  static const amount = 'amount';
  static const payee = 'payee';
  static const payment = 'payment';
}

/// Thrown when editing/deleting an already-synced entry with no connection.
///
/// There is no correction/offsetting-entry workflow in this UI (see
/// `services/pos-service/app/models/finance.py`'s "FINANCE ENTRIES ARE
/// MUTABLE" note) and no second outbox for mutations of already-synced
/// rows — a silent local edit that never reaches the server would be worse
/// than a clear refusal, so this surfaces to the dialog as an error instead
/// of queuing.
class FinanceOfflineMutationException implements Exception {
  final String message;
  FinanceOfflineMutationException(this.message);
  @override
  String toString() => message;
}

/// Source of other-expense entries, backed by POS Service once a store
/// context exists.
///
/// Same stale-while-revalidate contract as `OrdersNotifier`/`InventoryNotifier`:
/// `build()` never blocks on the network, a background refresh keeps the
/// cache current, and with no store context at all this falls back to
/// [MockFinance] so demo mode stays populated.
class OtherExpensesNotifier extends AsyncNotifier<List<OtherExpense>> {
  @override
  Future<List<OtherExpense>> build() async {
    final storeId = ref.watch(currentStoreIdProvider);
    if (storeId == null) return List.of(MockFinance.expenses);

    var disposed = false;
    ref.onDispose(() => disposed = true);
    unawaited(_refreshFromApi(storeId, isDisposed: () => disposed));

    return _loadFromCache(storeId);
  }

  Future<void> _refreshFromApi(
    String storeId, {
    required bool Function() isDisposed,
  }) async {
    try {
      await ref.read(financeSyncServiceProvider).syncNow();
      await ref.read(financeLedgerSyncServiceProvider).syncExpenses(storeId: storeId);
      if (!isDisposed()) {
        state = AsyncData(await _loadFromCache(storeId));
      }
    } catch (_) {
      // Offline, no permission, or a transient failure — the cached read
      // from `build()` already reflects the last known-good state.
    }
  }

  Future<List<OtherExpense>> _loadFromCache(String storeId) async {
    final db = ref.read(appDatabaseProvider);

    final cached = await (db.select(db.cachedOtherExpenses)
          ..where((row) =>
              row.storeId.equals(storeId) & row.isDeleted.equals(false)))
        .get();
    final cachedClientIds = cached.map((row) => row.clientExpenseId).toSet();

    final outbox = await (db.select(db.expenseEntries)
          ..where((row) => row.storeId.equals(storeId)))
        .get();

    final rows = [
      for (final row in cached) otherExpenseFromCachedRow(row),
      for (final row in outbox)
        if (!cachedClientIds.contains(row.expenseId)) otherExpenseFromOutboxRow(row),
    ];
    rows.sort((a, b) => b.date.compareTo(a.date));
    return rows;
  }

  /// Re-runs sync and waits for it — for a manual refresh action. A no-op
  /// with no store context (demo mode has nothing to pull).
  Future<void> refresh() async {
    final storeId = ref.read(currentStoreIdProvider);
    if (storeId == null) return;
    state = const AsyncLoading<List<OtherExpense>>().copyWithPrevious(state);
    await ref.read(financeSyncServiceProvider).syncNow();
    await ref.read(financeLedgerSyncServiceProvider).syncExpenses(storeId: storeId);
    state = AsyncData(await _loadFromCache(storeId));
  }

  /// Creates a new expense entry.
  Future<OtherExpense> create({
    required DateTime date,
    required String categoryId,
    required String description,
    required double amount,
    required PaymentType paymentType,
    String payee = '',
    String note = '',
    FinanceAttachment? receipt,
  }) async {
    final storeId = ref.read(currentStoreIdProvider);
    final current = state.valueOrNull ?? const <OtherExpense>[];

    if (storeId == null) {
      final expense = OtherExpense(
        id: _nextMockId(current),
        date: date,
        categoryId: categoryId,
        description: description,
        amount: amount,
        paymentType: paymentType,
        payee: payee,
        note: note,
        receipt: receipt,
      );
      state = AsyncData([expense, ...current]);
      return expense;
    }

    final localReceiptPath = await _persistReceiptLocally(receipt);
    final clientId = await ref.read(financeEntryWriterProvider).writeExpense(
      storeId: storeId,
      businessId: _businessId,
      actorUserId: _actorUserId,
      occurredAt: date,
      category: categoryId,
      amount: Decimal.parse(amount.toStringAsFixed(2)),
      description: description,
      paymentType: paymentType,
      payee: payee.isEmpty ? null : payee,
      note: note.isEmpty ? null : note,
      localReceiptPath: localReceiptPath,
    );

    final expense = OtherExpense(
      id: clientId,
      date: date,
      categoryId: categoryId,
      description: description,
      amount: amount,
      paymentType: paymentType,
      payee: payee,
      note: note,
      receipt: receipt,
      syncStatus: 'pending',
    );
    state = AsyncData([expense, ...current]);
    unawaited(_syncThenRefresh(storeId));
    return expense;
  }

  /// Edits [existing]. A still-unsynced outbox row is updated in place and
  /// re-queued; an already-synced row is PATCHed directly, which requires
  /// connectivity (throws [FinanceOfflineMutationException] otherwise).
  /// Demo mode edits in-memory only.
  ///
  /// Named `edit` rather than `update` — `AsyncNotifier` already declares a
  /// built-in `update(...)` helper method, which this would otherwise
  /// silently and incompatibly override.
  Future<OtherExpense> edit(
    OtherExpense existing, {
    required DateTime date,
    required String categoryId,
    required String description,
    required double amount,
    required PaymentType paymentType,
    String payee = '',
    String note = '',
    FinanceAttachment? receipt,
    bool clearReceipt = false,
  }) async {
    final storeId = ref.read(currentStoreIdProvider);
    final updated = existing.copyWith(
      date: date,
      categoryId: categoryId,
      description: description,
      amount: amount,
      paymentType: paymentType,
      payee: payee,
      note: note,
      receipt: receipt,
      clearReceipt: clearReceipt,
    );

    if (storeId == null) {
      _replaceInState(updated);
      return updated;
    }

    final db = ref.read(appDatabaseProvider);
    final outboxRow = await (db.select(db.expenseEntries)
          ..where((row) => row.expenseId.equals(existing.id)))
        .getSingleOrNull();

    if (outboxRow != null && outboxRow.syncStatus != 'synced') {
      final newLocalPath = await _persistReceiptLocally(receipt);
      await (db.update(db.expenseEntries)
            ..where((row) => row.id.equals(outboxRow.id)))
          .write(ExpenseEntriesCompanion(
            category: Value(categoryId),
            amount: Value(Decimal.parse(amount.toStringAsFixed(2))),
            description: Value(description),
            payee: Value(payee.isEmpty ? null : payee),
            note: Value(note.isEmpty ? null : note),
            paymentMethod: Value(paymentMethodToBackend(paymentType)),
            occurredAt: Value(date),
            localReceiptPath: clearReceipt
                ? const Value(null)
                : (newLocalPath != null ? Value(newLocalPath) : const Value.absent()),
            receiptAttachmentId: (clearReceipt || newLocalPath != null)
                ? const Value(null)
                : const Value.absent(),
            syncStatus: const Value('pending'),
          ));
      unawaited(_syncThenRefresh(storeId));
      final pendingUpdate = updated.copyWith(syncStatus: 'pending');
      _replaceInState(pendingUpdate);
      return pendingUpdate;
    }

    final serverId = existing.serverId ?? outboxRow?.serverId;
    if (serverId == null) {
      throw FinanceOfflineMutationException(
        'This entry has not finished syncing yet — try again once it does.',
      );
    }
    await ref.read(financeApiServiceProvider).updateExpense(
      businessId: _businessId,
      expenseId: serverId,
      category: categoryId,
      amount: Decimal.parse(amount.toStringAsFixed(2)),
      description: description,
      paymentMethod: paymentMethodToBackend(paymentType),
      payee: payee,
      note: note,
      occurredAt: date,
    );
    await refresh();
    return updated;
  }

  /// Deletes the expense entry [id]. See [update] for the pending-vs-synced
  /// split and the offline-mutation refusal.
  Future<void> delete(String id) async {
    final storeId = ref.read(currentStoreIdProvider);
    final current = state.valueOrNull ?? const <OtherExpense>[];

    if (storeId == null) {
      state = AsyncData(current.where((e) => e.id != id).toList());
      return;
    }

    final db = ref.read(appDatabaseProvider);
    final outboxRow = await (db.select(db.expenseEntries)
          ..where((row) => row.expenseId.equals(id)))
        .getSingleOrNull();

    if (outboxRow != null && outboxRow.syncStatus != 'synced') {
      await (db.delete(db.expenseEntries)..where((row) => row.id.equals(outboxRow.id))).go();
      state = AsyncData(current.where((e) => e.id != id).toList());
      return;
    }

    String? serverId = outboxRow?.serverId;
    for (final expense in current) {
      if (expense.id == id) serverId ??= expense.serverId;
    }
    if (serverId == null) {
      throw FinanceOfflineMutationException(
        'This entry has not finished syncing yet — try again once it does.',
      );
    }
    await ref.read(financeApiServiceProvider).deleteExpense(
      businessId: _businessId,
      expenseId: serverId,
    );
    await refresh();
  }

  Future<void> _syncThenRefresh(String storeId) async {
    await ref.read(financeSyncServiceProvider).syncNow();
    await ref.read(financeLedgerSyncServiceProvider).syncExpenses(storeId: storeId);
    state = AsyncData(await _loadFromCache(storeId));
  }

  void _replaceInState(OtherExpense expense) {
    final current = state.valueOrNull ?? const <OtherExpense>[];
    state = AsyncData([
      for (final e in current) if (e.id == expense.id) expense else e,
    ]);
  }

  String get _businessId {
    final id = ref.read(currentBusinessIdProvider);
    if (id == null) throw StateError('No active business context');
    return id;
  }

  String get _actorUserId => ref.read(sessionStaffProvider)?.id ?? '';

  String _nextMockId(List<OtherExpense> current) {
    var highest = 0;
    for (final e in current) {
      final n = int.tryParse(e.id.split('-').last);
      if (n != null && n > highest) highest = n;
    }
    return 'exp-${(highest + 1).toString().padLeft(2, '0')}';
  }

  /// Persists picked receipt bytes to app-local storage so they survive a
  /// restart before `FinanceSyncService` uploads them. Returns null if
  /// [receipt] carries no fresh bytes (nothing to persist).
  Future<String?> _persistReceiptLocally(FinanceAttachment? receipt) async {
    final bytes = receipt?.bytes;
    if (bytes == null) return null;
    final dir = await getApplicationSupportDirectory();
    final receiptsDir = Directory('${dir.path}/receipts');
    await receiptsDir.create(recursive: true);
    final ext = receipt!.name.contains('.') ? receipt.name.split('.').last : 'jpg';
    final path = '${receiptsDir.path}/${const Uuid().v4()}.$ext';
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }
}

final otherExpensesProvider =
    AsyncNotifierProvider<OtherExpensesNotifier, List<OtherExpense>>(
  OtherExpensesNotifier.new,
);

/// The list, unwrapped — mirrors `ordersListProvider`/`inventoryItemsListProvider`.
final otherExpensesListProvider = Provider<List<OtherExpense>>(
  (ref) => ref.watch(otherExpensesProvider).valueOrNull ?? const [],
);

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
  final expenses = ref.watch(otherExpensesListProvider);
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
