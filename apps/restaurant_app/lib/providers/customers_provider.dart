import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_customers.dart';
import '../database/app_database.dart';
import '../models/customer.dart';
import '../models/table_query.dart';
import '../sync/customer_entry_mapper.dart';
import 'customer_api_provider.dart';
import 'database_providers.dart';
import 'permissions_provider.dart';
import 'session_provider.dart';
import 'table_query_provider.dart';

/// Sort/filter field keys for the customers table.
abstract final class CustomerSort {
  static const name = 'name';
  static const phone = 'phone';
  static const lastOrder = 'lastOrder';
  static const totalSpent = 'totalSpent';
}

/// Thrown when editing/deleting an already-synced customer with no
/// connection. Mirrors `FinanceOfflineMutationException` — there is no
/// second outbox for mutations of already-synced rows, so a silent local
/// edit that never reaches the server would be worse than a clear refusal.
class CustomerOfflineMutationException implements Exception {
  final String message;
  CustomerOfflineMutationException(this.message);
  @override
  String toString() => message;
}

/// Source of customers, backed by POS Service once a business context
/// exists.
///
/// Same stale-while-revalidate contract as `OtherExpensesNotifier`, with
/// one structural difference to watch for: this keys off
/// [currentBusinessIdProvider], not `currentStoreIdProvider` — customers
/// are business-scoped, shared across a business's stores, not
/// store-scoped like expenses/income.
class CustomersNotifier extends AsyncNotifier<List<Customer>> {
  @override
  Future<List<Customer>> build() async {
    final businessId = ref.watch(currentBusinessIdProvider);
    if (businessId == null) return List.of(MockCustomers.list);

    var disposed = false;
    ref.onDispose(() => disposed = true);
    unawaited(_refreshFromApi(businessId, isDisposed: () => disposed));

    return _loadFromCache(businessId);
  }

  Future<void> _refreshFromApi(
    String businessId, {
    required bool Function() isDisposed,
  }) async {
    try {
      await ref.read(customerSyncServiceProvider).syncNow();
      await ref.read(customerLedgerSyncServiceProvider).syncCustomers();
      if (!isDisposed()) {
        state = AsyncData(await _loadFromCache(businessId));
      }
    } catch (_) {
      // Offline, no permission, or a transient failure — the cached read
      // from `build()` already reflects the last known-good state.
    }
  }

  Future<List<Customer>> _loadFromCache(String businessId) async {
    final db = ref.read(appDatabaseProvider);

    final cached = await (db.select(db.cachedCustomers)
          ..where((row) =>
              row.businessId.equals(businessId) & row.isDeleted.equals(false)))
        .get();
    final cachedIds = cached.map((row) => row.id).toSet();

    final outbox = await (db.select(db.customerEntries)
          ..where((row) => row.businessId.equals(businessId)))
        .get();

    final rows = [
      for (final row in cached) customerFromCachedRow(row),
      for (final row in outbox)
        if (!cachedIds.contains(row.customerId)) customerFromOutboxRow(row),
    ];
    rows.sort((a, b) => a.name.compareTo(b.name));
    return rows;
  }

  /// Re-runs sync and waits for it — for a manual refresh action. A no-op
  /// with no business context (demo mode has nothing to pull).
  Future<void> refresh() async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null) return;
    state = const AsyncLoading<List<Customer>>().copyWithPrevious(state);
    await ref.read(customerSyncServiceProvider).syncNow();
    await ref.read(customerLedgerSyncServiceProvider).syncCustomers();
    state = AsyncData(await _loadFromCache(businessId));
  }

  /// Creates a new customer.
  Future<Customer> create({
    required String name,
    required String phone,
    String? email,
    String? addressLine1,
  }) async {
    final businessId = ref.read(currentBusinessIdProvider);
    final current = state.valueOrNull ?? const <Customer>[];

    if (businessId == null) {
      final customer = Customer(
        id: MockCustomers.nextId(current),
        name: name,
        phone: phone,
        email: email,
        addressLine1: addressLine1,
        createdAt: DateTime.now(),
        totalOrders: 0,
        totalSpent: 0,
      );
      state = AsyncData([customer, ...current]);
      return customer;
    }

    final joinedAt = DateTime.now();
    final customerId = await ref.read(customerEntryWriterProvider).writeCustomer(
      businessId: businessId,
      actorUserId: _actorUserId,
      name: name,
      phone: phone,
      email: email,
      addressLine1: addressLine1,
      joinedAt: joinedAt,
    );

    final customer = Customer(
      id: customerId,
      name: name,
      phone: phone,
      email: email,
      addressLine1: addressLine1,
      createdAt: joinedAt,
      totalOrders: 0,
      totalSpent: 0,
      syncStatus: 'pending',
    );
    state = AsyncData([customer, ...current]);
    unawaited(_syncThenRefresh(businessId));
    return customer;
  }

  /// Edits [existing]. A still-unsynced outbox row is updated in place and
  /// re-queued; an already-synced row is PATCHed directly, which requires
  /// connectivity (throws [CustomerOfflineMutationException] otherwise).
  /// Demo mode edits in-memory only.
  ///
  /// Named `edit` rather than `update` — `AsyncNotifier` already declares a
  /// built-in `update(...)` helper method, which this would otherwise
  /// silently and incompatibly override.
  Future<Customer> edit(
    Customer existing, {
    required String name,
    required String phone,
    String? email,
    String? addressLine1,
  }) async {
    final businessId = ref.read(currentBusinessIdProvider);
    final updated = existing.copyWith(
      name: name,
      phone: phone,
      email: email,
      clearEmail: email == null,
      addressLine1: addressLine1,
      clearAddressLine1: addressLine1 == null,
    );

    if (businessId == null) {
      _replaceInState(updated);
      return updated;
    }

    final db = ref.read(appDatabaseProvider);
    final outboxRow = await (db.select(db.customerEntries)
          ..where((row) => row.customerId.equals(existing.id)))
        .getSingleOrNull();

    if (outboxRow != null && outboxRow.syncStatus != 'synced') {
      await (db.update(db.customerEntries)
            ..where((row) => row.id.equals(outboxRow.id)))
          .write(CustomerEntriesCompanion(
            name: Value(name),
            phone: Value(phone),
            email: Value(email),
            addressLine1: Value(addressLine1),
            syncStatus: const Value('pending'),
          ));
      unawaited(_syncThenRefresh(businessId));
      final pendingUpdate = updated.copyWith(syncStatus: 'pending');
      _replaceInState(pendingUpdate);
      return pendingUpdate;
    }

    if (existing.serverId == null) {
      throw CustomerOfflineMutationException(
        'This customer has not finished syncing yet — try again once it does.',
      );
    }
    await ref.read(customerApiServiceProvider).updateCustomer(
      businessId: businessId,
      customerId: existing.serverId!,
      name: name,
      phone: phone,
      email: email,
      addressLine1: addressLine1,
    );
    await refresh();
    return updated;
  }

  /// Deletes the customer [id]. See [edit] for the pending-vs-synced split
  /// and the offline-mutation refusal.
  Future<void> delete(String id) async {
    final businessId = ref.read(currentBusinessIdProvider);
    final current = state.valueOrNull ?? const <Customer>[];

    if (businessId == null) {
      state = AsyncData(current.where((c) => c.id != id).toList());
      return;
    }

    final db = ref.read(appDatabaseProvider);
    final outboxRow = await (db.select(db.customerEntries)
          ..where((row) => row.customerId.equals(id)))
        .getSingleOrNull();

    if (outboxRow != null && outboxRow.syncStatus != 'synced') {
      await (db.delete(db.customerEntries)..where((row) => row.id.equals(outboxRow.id))).go();
      state = AsyncData(current.where((c) => c.id != id).toList());
      return;
    }

    String? serverId;
    for (final customer in current) {
      if (customer.id == id) serverId = customer.serverId;
    }
    if (serverId == null) {
      throw CustomerOfflineMutationException(
        'This customer has not finished syncing yet — try again once it does.',
      );
    }
    await ref.read(customerApiServiceProvider).deleteCustomer(
      businessId: businessId,
      customerId: serverId,
    );
    await refresh();
  }

  Future<void> _syncThenRefresh(String businessId) async {
    await ref.read(customerSyncServiceProvider).syncNow();
    await ref.read(customerLedgerSyncServiceProvider).syncCustomers();
    state = AsyncData(await _loadFromCache(businessId));
  }

  void _replaceInState(Customer customer) {
    final current = state.valueOrNull ?? const <Customer>[];
    state = AsyncData([
      for (final c in current) if (c.id == customer.id) customer else c,
    ]);
  }

  String get _actorUserId => ref.read(sessionStaffProvider)?.id ?? '';
}

/// The full, unfiltered customer list.
final customersProvider =
    AsyncNotifierProvider<CustomersNotifier, List<Customer>>(CustomersNotifier.new);

/// The list, unwrapped — mirrors `otherExpensesListProvider`.
final customersListProvider = Provider<List<Customer>>(
  (ref) => ref.watch(customersProvider).valueOrNull ?? const [],
);

/// Live search text from the customers list search field.
final customerSearchProvider = StateProvider<String>((ref) => '');

/// Query state (page, sort, etc) for the customers table.
final customersQueryProvider = NotifierProvider<TableQueryNotifier, TableQuery>(
  TableQueryNotifier.new,
);

/// Customers after search is applied.
final filteredCustomersProvider = Provider<List<Customer>>((ref) {
  final customers = ref.watch(customersListProvider);
  final query = ref.watch(customerSearchProvider).trim().toLowerCase();

  if (query.isEmpty) return customers;

  return customers.where((c) {
    return c.name.toLowerCase().contains(query) ||
        c.phone.toLowerCase().contains(query) ||
        (c.email?.toLowerCase().contains(query) ?? false);
  }).toList();
});

/// Sorted and paginated slice of filtered customers.
final customersSliceProvider = Provider<PageSlice<Customer>>((ref) {
  final customers = ref.watch(filteredCustomersProvider);
  final query = ref.watch(customersQueryProvider);

  // Sort
  var sorted = [...customers];
  sorted.sort((a, b) => switch (query.sortField) {
    CustomerSort.phone => a.phone.compareTo(b.phone),
    CustomerSort.lastOrder => (b.lastOrderAt ?? DateTime(1970))
        .compareTo(a.lastOrderAt ?? DateTime(1970)),
    CustomerSort.totalSpent => b.totalSpent.compareTo(a.totalSpent),
    _ => a.name.compareTo(b.name),
  });

  if (!query.ascending) sorted = sorted.reversed.toList();

  return PageSlice.of(sorted, query);
});

/// Summary stats for all customers.
@immutable
class CustomerSummary {
  const CustomerSummary({
    required this.totalCustomers,
    required this.totalLifetimeSpend,
  });

  final int totalCustomers;
  final double totalLifetimeSpend;

  double get averageOrderValue =>
      totalCustomers == 0 ? 0 : totalLifetimeSpend / totalCustomers;
}

final customerSummaryProvider = Provider<CustomerSummary>((ref) {
  final customers = ref.watch(customersListProvider);
  double totalSpend = 0;
  for (final c in customers) {
    totalSpend += c.totalSpent;
  }
  return CustomerSummary(
    totalCustomers: customers.length,
    totalLifetimeSpend: totalSpend,
  );
});

/// Lookup by id.
final customerByIdProvider = Provider.family<Customer?, String>((ref, id) {
  for (final customer in ref.watch(customersListProvider)) {
    if (customer.id == id) return customer;
  }
  return null;
});
