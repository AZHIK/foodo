import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_customers.dart';
import '../models/customer.dart';
import '../models/table_query.dart';
import 'table_query_provider.dart';

/// Sort/filter field keys for the customers table.
abstract final class CustomerSort {
  static const name = 'name';
  static const phone = 'phone';
  static const lastOrder = 'lastOrder';
  static const totalSpent = 'totalSpent';
}

/// The source of truth for customers.
class CustomersNotifier extends Notifier<List<Customer>> {
  @override
  List<Customer> build() => MockCustomers.list;

  void upsert(Customer customer) {
    final index = state.indexWhere((c) => c.id == customer.id);
    if (index == -1) {
      state = [customer, ...state];
      return;
    }
    final next = [...state];
    next[index] = customer;
    state = next;
  }

  void delete(String id) => state = state.where((c) => c.id != id).toList();

  String nextId() => MockCustomers.nextId(state);
}

/// The full, unfiltered customer list.
final customersProvider =
    NotifierProvider<CustomersNotifier, List<Customer>>(CustomersNotifier.new);

/// Live search text from the customers list search field.
final customerSearchProvider = StateProvider<String>((ref) => '');

/// Query state (page, sort, etc) for the customers table.
final customersQueryProvider = NotifierProvider<TableQueryNotifier, TableQuery>(
  TableQueryNotifier.new,
);

/// Customers after search is applied.
final filteredCustomersProvider = Provider<List<Customer>>((ref) {
  final customers = ref.watch(customersProvider);
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
  final customers = ref.watch(customersProvider);
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
  for (final customer in ref.watch(customersProvider)) {
    if (customer.id == id) return customer;
  }
  return null;
});
