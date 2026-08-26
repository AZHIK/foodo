import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_menu.dart';
import '../data/mock_orders.dart';
import '../models/cart.dart';
import '../models/order.dart';
import '../models/order_totals.dart';
import '../models/table_query.dart';
import 'table_query_provider.dart';

/// Sortable column keys. Constants rather than raw strings at the call sites,
/// so the column config and the sort switch cannot drift apart.
abstract final class SalesSort {
  static const orderId = 'orderId';
  static const date = 'date';
  static const items = 'items';
  static const total = 'total';
  static const payment = 'payment';
  static const status = 'status';
  static const fulfillment = 'fulfillment';
}

/// Date windows offered by the header selector and the filter panel.
enum SalesDateRange {
  today('Today'),
  week('This week'),
  month('This month'),
  all('All time'),
  custom('Custom');

  const SalesDateRange(this.label);
  final String label;
}

// ---------------------------------------------------------------------------
// Raw data
// ---------------------------------------------------------------------------

/// Source of completed sales. Seeded with mock history; new orders placed on
/// the POS screen are prepended.
class OrdersNotifier extends Notifier<List<Order>> {
  @override
  List<Order> build() => MockOrders.generate();

  /// Converts the open cart into a sale and returns it, so the caller can
  /// navigate straight to its detail route.
  ///
  /// [paymentType] overrides the tender recorded on the cart, for the quick
  /// charge dialog that takes payment without visiting the payment screen.
  Order placeOrder({
    required Cart cart,
    PaymentType? paymentType,
    OrderType orderType = OrderType.dineIn,
    String? tableLabel,
    String serverName = 'House',
  }) {
    final order = Order.fromCart(
      id: nextOrderId(state),
      cart: cart,
      paymentType: paymentType,
      placedAt: DateTime.now(),
      orderType: orderType,
      tableLabel: tableLabel,
      serverName: serverName,
    );
    state = [order, ...state];
    return order;
  }

  void refund(String orderId) => _setStatus(orderId, OrderStatus.refunded);

  void voidOrder(String orderId) => _setStatus(orderId, OrderStatus.voided);

  void markPaid(String orderId) => _setStatus(orderId, OrderStatus.paid);

  void setFulfillmentStatus(String orderId, FulfillmentStatus status) {
    state = [
      for (final order in state)
        if (order.id == orderId)
          order.copyWith(fulfillmentStatus: status)
        else
          order,
    ];
  }

  void setOrderCourier(String orderId, String courierId) {
    state = [
      for (final order in state)
        if (order.id == orderId)
          order.copyWith(courierId: courierId)
        else
          order,
    ];
  }

  /// Checks for new orders via the refresh seam. Currently simulates incoming
  /// orders in mock mode; a real backend would replace this with a WebSocket
  /// subscription or polling mechanism.
  Future<void> checkForNewOrders() async {
    _maybeSimulateIncomingOrder();
  }

  /// In mock mode, randomly synthesizes a new order to simulate an incoming
  /// ticket. A real backend would push/pull these instead.
  void _maybeSimulateIncomingOrder() {
    final rand = Random();

    // 20% chance on a refresh to simulate a new order arriving.
    // Not 100% so a user who taps refresh twice sees the list stay still,
    // matching real-world behavior where taps don't always land on new orders.
    if (rand.nextDouble() > 0.20) return;

    final menu = MockMenu.items.where((i) => i.isAvailable).toList();
    if (menu.isEmpty) return;

    final lineCount = 1 + rand.nextInt(3);
    final picked = <String>{};
    final lines = <OrderLine>[];
    for (var l = 0; l < lineCount; l++) {
      final item = menu[rand.nextInt(menu.length)];
      if (!picked.add(item.id)) continue;
      lines.add(
        OrderLine(
          itemId: item.id,
          name: item.name,
          emoji: item.emoji,
          unitPrice: item.price,
          quantity: 1 + rand.nextInt(2),
        ),
      );
    }

    final newOrder = Order(
      id: nextOrderId(state),
      lines: lines,
      placedAt: DateTime.now(),
      paymentType: _weightedPayment(rand),
      status: OrderStatus.paid,
      taxRate: 0.0825,
      orderType: [OrderType.dineIn, OrderType.takeaway, OrderType.delivery]
          [rand.nextInt(3)],
      fulfillmentStatus: FulfillmentStatus.new_,
      discountRate: 0,
      serverName: const ['Ava', 'Marco', 'Priya', 'Dan', 'Yuki', 'Sofia']
          [rand.nextInt(6)],
    );

    state = [newOrder, ...state];
  }

  static PaymentType _weightedPayment(Random rand) {
    final roll = rand.nextDouble();
    if (roll < 0.58) return PaymentType.card;
    if (roll < 0.80) return PaymentType.mobile;
    if (roll < 0.95) return PaymentType.cash;
    return PaymentType.giftCard;
  }

  void _setStatus(String orderId, OrderStatus status) {
    state = [
      for (final order in state)
        if (order.id == orderId) order.copyWith(status: status) else order,
    ];
  }
}

final ordersProvider = NotifierProvider<OrdersNotifier, List<Order>>(
  OrdersNotifier.new,
);

/// Continues the ORD-#### sequence from the highest existing id.
///
/// Top-level so the POS panel can preview the next ticket number without
/// re-deriving the rule and risking a mismatch with the sale it creates.
String nextOrderId(List<Order> orders) {
  var highest = 0;
  for (final order in orders) {
    final n = int.tryParse(order.id.split('-').last);
    if (n != null && n > highest) highest = n;
  }
  return 'ORD-${(highest + 1).toString().padLeft(4, '0')}';
}

// ---------------------------------------------------------------------------
// Search / sort / pagination
// ---------------------------------------------------------------------------

final salesQueryProvider = NotifierProvider<TableQueryNotifier, TableQuery>(
  () => TableQueryNotifier(
    // Newest first is what a manager wants on opening the ledger.
    const TableQuery(
      sortField: SalesSort.date,
      ascending: false,
      pageSize: 8,
    ),
  ),
);

// ---------------------------------------------------------------------------
// Filters
// ---------------------------------------------------------------------------

/// The Sales filter state: a date window plus payment and status multi-selects.
///
/// An empty set means "no constraint", so "nothing ticked" and "everything
/// ticked" behave the same for the user.
@immutable
class SalesFilters {
  const SalesFilters({
    this.range = SalesDateRange.today,
    this.customRange,
    this.payments = const {},
    this.statuses = const {},
  });

  final SalesDateRange range;

  /// Only meaningful when [range] is [SalesDateRange.custom].
  final DateTimeRange? customRange;

  final Set<PaymentType> payments;
  final Set<OrderStatus> statuses;

  /// The date window has its own always-visible control in the page header,
  /// so it is deliberately not counted here — the badge reports only what the
  /// Filter panel hides.
  int get activeCount => payments.length + statuses.length;

  /// Resolves [range] against [now]. Null means "no date constraint".
  DateTimeRange? window(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    return switch (range) {
      SalesDateRange.today => DateTimeRange(
        start: today,
        end: today.add(const Duration(days: 1)),
      ),
      // Calendar week starting Monday, not a rolling seven days — "this week"
      // means the week you are in.
      SalesDateRange.week => DateTimeRange(
        start: today.subtract(Duration(days: today.weekday - 1)),
        end: today.add(const Duration(days: 1)),
      ),
      SalesDateRange.month => DateTimeRange(
        start: DateTime(now.year, now.month),
        end: today.add(const Duration(days: 1)),
      ),
      SalesDateRange.all => null,
      SalesDateRange.custom => customRange == null
          ? null
          : DateTimeRange(
              start: customRange!.start,
              // The picker returns a start-of-day end date; include that day.
              end: DateTime(
                customRange!.end.year,
                customRange!.end.month,
                customRange!.end.day,
              ).add(const Duration(days: 1)),
            ),
    };
  }

  bool matches(Order order, DateTime now) {
    if (payments.isNotEmpty && !payments.contains(order.paymentType)) {
      return false;
    }
    if (statuses.isNotEmpty && !statuses.contains(order.status)) return false;

    final window = this.window(now);
    if (window == null) return true;
    return !order.placedAt.isBefore(window.start) &&
        order.placedAt.isBefore(window.end);
  }

  SalesFilters copyWith({
    SalesDateRange? range,
    DateTimeRange? customRange,
    Set<PaymentType>? payments,
    Set<OrderStatus>? statuses,
  }) {
    return SalesFilters(
      range: range ?? this.range,
      customRange: customRange ?? this.customRange,
      payments: payments ?? this.payments,
      statuses: statuses ?? this.statuses,
    );
  }
}

class SalesFiltersNotifier extends Notifier<SalesFilters> {
  @override
  SalesFilters build() => const SalesFilters();

  void setRange(SalesDateRange range) {
    state = state.copyWith(range: range);
    _resetPage();
  }

  void setCustomRange(DateTimeRange range) {
    state = state.copyWith(range: SalesDateRange.custom, customRange: range);
    _resetPage();
  }

  void togglePayment(PaymentType payment) {
    final next = Set<PaymentType>.of(state.payments);
    next.contains(payment) ? next.remove(payment) : next.add(payment);
    state = state.copyWith(payments: next);
    _resetPage();
  }

  void toggleStatus(OrderStatus status) {
    final next = Set<OrderStatus>.of(state.statuses);
    next.contains(status) ? next.remove(status) : next.add(status);
    state = state.copyWith(statuses: next);
    _resetPage();
  }

  /// Clears the panel's filters but keeps the date window, which the user set
  /// through a separate, still-visible control.
  void clear() {
    state = SalesFilters(range: state.range, customRange: state.customRange);
    _resetPage();
  }

  void _resetPage() => ref.read(salesQueryProvider.notifier).resetPage();
}

final salesFiltersProvider =
    NotifierProvider<SalesFiltersNotifier, SalesFilters>(
      SalesFiltersNotifier.new,
    );

// ---------------------------------------------------------------------------
// Derived views
// ---------------------------------------------------------------------------

/// Search + filters + sort in one place, so no filtering logic lives in the
/// widget tree and the exporters can reuse exactly what the table shows.
final filteredOrdersProvider = Provider<List<Order>>((ref) {
  final orders = ref.watch(ordersProvider);
  final query = ref.watch(salesQueryProvider);
  final filters = ref.watch(salesFiltersProvider);
  final search = query.search.trim().toLowerCase();
  final now = DateTime.now();

  final rows = orders.where((order) {
    if (!filters.matches(order, now)) return false;
    if (search.isEmpty) return true;
    return order.id.toLowerCase().contains(search) ||
        order.serverName.toLowerCase().contains(search) ||
        (order.tableLabel?.toLowerCase().contains(search) ?? false) ||
        order.paymentType.label.toLowerCase().contains(search) ||
        order.lines.any((line) => line.name.toLowerCase().contains(search));
  }).toList();

  final direction = query.ascending ? 1 : -1;
  rows.sort((a, b) {
    final cmp = switch (query.sortField) {
      SalesSort.orderId => a.id.compareTo(b.id),
      SalesSort.items => a.itemCount.compareTo(b.itemCount),
      SalesSort.total => a.total.compareTo(b.total),
      SalesSort.payment => a.paymentType.label.compareTo(b.paymentType.label),
      SalesSort.status => a.status.label.compareTo(b.status.label),
      SalesSort.fulfillment => a.fulfillmentStatus.index.compareTo(b.fulfillmentStatus.index),
      _ => a.placedAt.compareTo(b.placedAt),
    };
    // Stable tiebreak keeps rows from shuffling between equal values.
    return cmp != 0 ? cmp * direction : a.id.compareTo(b.id);
  });

  return rows;
});

final salesSliceProvider = Provider<PageSlice<Order>>(
  (ref) => PageSlice.of(
    ref.watch(filteredOrdersProvider),
    ref.watch(salesQueryProvider),
  ),
);

final orderByIdProvider = Provider.family<Order?, String>((ref, id) {
  for (final order in ref.watch(ordersProvider)) {
    if (order.id == id) return order;
  }
  return null;
});

/// Totals for a *completed* sale — the sale-detail counterpart to
/// `orderTotalsProvider`, which serves the open ticket. Both hand back the
/// same [OrderTotals] type, so the payment breakdown widget cannot tell (or
/// care) which end of the flow it is rendering.
final orderTotalsByIdProvider = Provider.family<OrderTotals, String>(
  (ref, id) => ref.watch(orderByIdProvider(id))?.totals ?? OrderTotals.zero,
);

/// Headline numbers for the sales summary strip.
@immutable
class SalesSummary {
  const SalesSummary({
    required this.revenue,
    required this.orderCount,
    required this.itemCount,
    required this.refundedCount,
  });

  final double revenue;
  final int orderCount;
  final int itemCount;
  final int refundedCount;

  double get averageOrderValue => orderCount == 0 ? 0 : revenue / orderCount;
}

/// Summarises exactly what the table is showing, so filtering to "Refunded"
/// changes the cards too — the alternative leaves three numbers on screen that
/// quietly describe a different set of rows.
final salesSummaryProvider = Provider<SalesSummary>((ref) {
  var revenue = 0.0;
  var orderCount = 0;
  var itemCount = 0;
  var refunded = 0;

  for (final order in ref.watch(filteredOrdersProvider)) {
    orderCount++;
    itemCount += order.itemCount;
    revenue += order.netRevenue;
    if (order.status == OrderStatus.refunded) refunded++;
  }

  return SalesSummary(
    revenue: revenue,
    orderCount: orderCount,
    itemCount: itemCount,
    refundedCount: refunded,
  );
});
