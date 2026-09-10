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
import '../models/other_income.dart';
import '../models/table_query.dart';
import '../sync/finance_entry_mapper.dart';
import 'database_providers.dart';
import 'finance_api_provider.dart';
import 'other_expenses_provider.dart' show FinanceOfflineMutationException;
import 'permissions_provider.dart';
import 'session_provider.dart';
import 'table_query_provider.dart';

abstract final class OtherIncomeSort {
  static const date = 'date';
  static const category = 'category';
  static const description = 'description';
  static const amount = 'amount';
  static const source = 'source';
  static const payment = 'payment';
}

/// Source of other-income entries, backed by POS Service once a store
/// context exists. Mirror of `OtherExpensesNotifier` — see that file for the
/// stale-while-revalidate contract and the pending-vs-synced mutation split.
class OtherIncomesNotifier extends AsyncNotifier<List<OtherIncome>> {
  @override
  Future<List<OtherIncome>> build() async {
    final storeId = ref.watch(currentStoreIdProvider);
    if (storeId == null) return List.of(MockFinance.incomes);

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
      await ref.read(financeLedgerSyncServiceProvider).syncIncomes(storeId: storeId);
      if (!isDisposed()) {
        state = AsyncData(await _loadFromCache(storeId));
      }
    } catch (_) {
      // Offline, no permission, or a transient failure — keep last known-good.
    }
  }

  Future<List<OtherIncome>> _loadFromCache(String storeId) async {
    final db = ref.read(appDatabaseProvider);

    final cached = await (db.select(db.cachedOtherIncomes)
          ..where((row) =>
              row.storeId.equals(storeId) & row.isDeleted.equals(false)))
        .get();
    final cachedClientIds = cached.map((row) => row.clientIncomeId).toSet();

    final outbox = await (db.select(db.otherIncomeEntries)
          ..where((row) => row.storeId.equals(storeId)))
        .get();

    final rows = [
      for (final row in cached) otherIncomeFromCachedRow(row),
      for (final row in outbox)
        if (!cachedClientIds.contains(row.incomeId)) otherIncomeFromOutboxRow(row),
    ];
    rows.sort((a, b) => b.date.compareTo(a.date));
    return rows;
  }

  Future<void> refresh() async {
    final storeId = ref.read(currentStoreIdProvider);
    if (storeId == null) return;
    state = const AsyncLoading<List<OtherIncome>>().copyWithPrevious(state);
    await ref.read(financeSyncServiceProvider).syncNow();
    await ref.read(financeLedgerSyncServiceProvider).syncIncomes(storeId: storeId);
    state = AsyncData(await _loadFromCache(storeId));
  }

  Future<OtherIncome> create({
    required DateTime date,
    required String categoryId,
    required String description,
    required double amount,
    required PaymentType paymentType,
    String source = '',
    String note = '',
    FinanceAttachment? receipt,
  }) async {
    final storeId = ref.read(currentStoreIdProvider);
    final current = state.valueOrNull ?? const <OtherIncome>[];

    if (storeId == null) {
      final income = OtherIncome(
        id: _nextMockId(current),
        date: date,
        categoryId: categoryId,
        description: description,
        amount: amount,
        paymentType: paymentType,
        source: source,
        note: note,
        receipt: receipt,
      );
      state = AsyncData([income, ...current]);
      return income;
    }

    final localReceiptPath = await _persistReceiptLocally(receipt);
    final clientId = await ref.read(financeEntryWriterProvider).writeIncome(
      storeId: storeId,
      businessId: _businessId,
      actorUserId: _actorUserId,
      occurredAt: date,
      category: categoryId,
      amount: Decimal.parse(amount.toStringAsFixed(2)),
      description: description,
      paymentType: paymentType,
      source: source.isEmpty ? null : source,
      note: note.isEmpty ? null : note,
      localReceiptPath: localReceiptPath,
    );

    final income = OtherIncome(
      id: clientId,
      date: date,
      categoryId: categoryId,
      description: description,
      amount: amount,
      paymentType: paymentType,
      source: source,
      note: note,
      receipt: receipt,
      syncStatus: 'pending',
    );
    state = AsyncData([income, ...current]);
    unawaited(_syncThenRefresh(storeId));
    return income;
  }

  /// See `OtherExpensesNotifier.edit` — same pending-vs-synced split, same
  /// reason for the `edit` name over `update`.
  Future<OtherIncome> edit(
    OtherIncome existing, {
    required DateTime date,
    required String categoryId,
    required String description,
    required double amount,
    required PaymentType paymentType,
    String source = '',
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
      source: source,
      note: note,
      receipt: receipt,
      clearReceipt: clearReceipt,
    );

    if (storeId == null) {
      _replaceInState(updated);
      return updated;
    }

    final db = ref.read(appDatabaseProvider);
    final outboxRow = await (db.select(db.otherIncomeEntries)
          ..where((row) => row.incomeId.equals(existing.id)))
        .getSingleOrNull();

    if (outboxRow != null && outboxRow.syncStatus != 'synced') {
      final newLocalPath = await _persistReceiptLocally(receipt);
      await (db.update(db.otherIncomeEntries)
            ..where((row) => row.id.equals(outboxRow.id)))
          .write(OtherIncomeEntriesCompanion(
            category: Value(categoryId),
            amount: Value(Decimal.parse(amount.toStringAsFixed(2))),
            description: Value(description),
            source: Value(source.isEmpty ? null : source),
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
    await ref.read(financeApiServiceProvider).updateIncome(
      businessId: _businessId,
      incomeId: serverId,
      category: categoryId,
      amount: Decimal.parse(amount.toStringAsFixed(2)),
      description: description,
      paymentMethod: paymentMethodToBackend(paymentType),
      source: source,
      note: note,
      occurredAt: date,
    );
    await refresh();
    return updated;
  }

  Future<void> delete(String id) async {
    final storeId = ref.read(currentStoreIdProvider);
    final current = state.valueOrNull ?? const <OtherIncome>[];

    if (storeId == null) {
      state = AsyncData(current.where((i) => i.id != id).toList());
      return;
    }

    final db = ref.read(appDatabaseProvider);
    final outboxRow = await (db.select(db.otherIncomeEntries)
          ..where((row) => row.incomeId.equals(id)))
        .getSingleOrNull();

    if (outboxRow != null && outboxRow.syncStatus != 'synced') {
      await (db.delete(db.otherIncomeEntries)..where((row) => row.id.equals(outboxRow.id))).go();
      state = AsyncData(current.where((i) => i.id != id).toList());
      return;
    }

    String? serverId = outboxRow?.serverId;
    for (final income in current) {
      if (income.id == id) serverId ??= income.serverId;
    }
    if (serverId == null) {
      throw FinanceOfflineMutationException(
        'This entry has not finished syncing yet — try again once it does.',
      );
    }
    await ref.read(financeApiServiceProvider).deleteIncome(
      businessId: _businessId,
      incomeId: serverId,
    );
    await refresh();
  }

  Future<void> _syncThenRefresh(String storeId) async {
    await ref.read(financeSyncServiceProvider).syncNow();
    await ref.read(financeLedgerSyncServiceProvider).syncIncomes(storeId: storeId);
    state = AsyncData(await _loadFromCache(storeId));
  }

  void _replaceInState(OtherIncome income) {
    final current = state.valueOrNull ?? const <OtherIncome>[];
    state = AsyncData([
      for (final i in current) if (i.id == income.id) income else i,
    ]);
  }

  String get _businessId {
    final id = ref.read(currentBusinessIdProvider);
    if (id == null) throw StateError('No active business context');
    return id;
  }

  String get _actorUserId => ref.read(sessionStaffProvider)?.id ?? '';

  String _nextMockId(List<OtherIncome> current) {
    var highest = 0;
    for (final income in current) {
      final n = int.tryParse(income.id.split('-').last);
      if (n != null && n > highest) highest = n;
    }
    return 'inc-${(highest + 1).toString().padLeft(2, '0')}';
  }

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

final otherIncomesProvider =
    AsyncNotifierProvider<OtherIncomesNotifier, List<OtherIncome>>(
  OtherIncomesNotifier.new,
);

/// The list, unwrapped — mirrors `otherExpensesListProvider`.
final otherIncomesListProvider = Provider<List<OtherIncome>>(
  (ref) => ref.watch(otherIncomesProvider).valueOrNull ?? const [],
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
  final incomes = ref.watch(otherIncomesListProvider);
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
