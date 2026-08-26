import 'package:flutter/material.dart';

import 'cart.dart';
import 'order_totals.dart';
import 'payment.dart';

enum PaymentType {
  cash('Cash', Icons.payments_outlined),
  card('Card', Icons.credit_card_rounded),
  qris('QRIS', Icons.qr_code_2_rounded),
  mobile('Mobile Pay', Icons.contactless_rounded),
  giftCard('Gift Card', Icons.card_giftcard_rounded);

  const PaymentType(this.label, this.icon);
  final String label;
  final IconData icon;

  /// The tenders a terminal offers at the counter, in the order they appear on
  /// the payment screen. The rest of the enum still exists because historical
  /// sales were taken on them.
  static const counterTenders = [cash, card, qris];

  /// Card and QRIS settle through a terminal we only mock here: no amount is
  /// keyed in, the payment is simply approved or not.
  bool get isTerminal => this == card || this == qris || this == mobile;
}

enum OrderStatus {
  paid('Paid'),
  refunded('Refunded'),

  /// Cancelled before payment settled — distinct from a refund, which returns
  /// money that was actually taken.
  voided('Voided'),
  pending('Pending');

  const OrderStatus(this.label);
  final String label;

  /// Voided and refunded tickets are both excluded from takings.
  bool get countsAsRevenue => this == OrderStatus.paid;
}

/// Fulfillment stage of an order (kitchen workflow), independent of payment status.
enum FulfillmentStatus {
  new_('New', Icons.inbox_rounded),
  preparing('Preparing', Icons.schedule_rounded),
  ready('Ready', Icons.check_circle_rounded),
  outForDelivery('Out for Delivery', Icons.two_wheeler_rounded),
  completed('Completed', Icons.done_all_rounded);

  const FulfillmentStatus(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// How the order leaves the counter. Drives the table-number field on the POS
/// order panel and is recorded on the finished sale.
enum OrderType {
  dineIn('Dine-in', Icons.restaurant_rounded),
  takeaway('Takeaway', Icons.takeout_dining_rounded),
  delivery('Delivery', Icons.delivery_dining_rounded);

  const OrderType(this.label, this.icon);
  final String label;
  final IconData icon;

  /// Only dine-in orders are seated, so only they take a table number.
  bool get usesTable => this == OrderType.dineIn;
}

/// A denormalised snapshot of a menu item at the time of sale.
///
/// Sales history must not change when the menu is edited, so the name and
/// price are copied rather than referenced.
@immutable
class OrderLine {
  const OrderLine({
    required this.itemId,
    required this.name,
    required this.emoji,
    required this.unitPrice,
    required this.quantity,
    this.note,
  });

  final String itemId;
  final String name;
  final String emoji;
  final double unitPrice;
  final int quantity;
  final String? note;

  double get lineTotal => unitPrice * quantity;
}

/// A completed sale.
@immutable
class Order {
  const Order({
    required this.id,
    required this.lines,
    required this.placedAt,
    required this.paymentType,
    required this.status,
    required this.taxRate,
    this.orderType = OrderType.dineIn,
    this.discountRate = 0,
    this.fulfillmentStatus = FulfillmentStatus.new_,
    this.tableLabel,
    this.serverName = 'House',
    this.amountTendered,
    this.customerId,
    this.courierId,
  });

  final String id;
  final List<OrderLine> lines;
  final DateTime placedAt;
  final PaymentType paymentType;
  final OrderStatus status;
  final double taxRate;
  final OrderType orderType;
  final double discountRate;
  final FulfillmentStatus fulfillmentStatus;

  /// e.g. "Table 12" or null for counter/takeaway orders.
  final String? tableLabel;
  final String serverName;

  /// Cash handed over, kept so a reprinted receipt still shows the change
  /// given. Null for card, QRIS and every other terminal tender.
  final double? amountTendered;

  /// Associated customer id, if the order was placed by a registered customer.
  final String? customerId;

  /// Assigned courier id, for delivery orders.
  final String? courierId;

  /// The numeric part of the ticket id, for composing a receipt number under
  /// whatever prefix Store Settings is configured with.
  ///
  /// The order id and the receipt number are deliberately different strings
  /// for the same sale: the ledger keys on "ORD-0042" forever, while the paper
  /// the customer takes away carries the venue's own numbering ("INV-0042").
  String get receiptSuffix => id.split('-').last;

  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);

  double get subtotal => lines.fold(0.0, (sum, line) => sum + line.lineTotal);

  /// The same arithmetic the open ticket used, so a sale never re-adds to a
  /// different number than the receipt it was printed from.
  OrderTotals get totals => OrderTotals.from(
    subtotal: subtotal,
    taxRate: taxRate,
    discountRate: discountRate,
  );

  /// How this sale was settled, in the shape the shared payment widgets take.
  PaymentDetails get payment => PaymentDetails(
    method: paymentType,
    amountTendered: amountTendered,
    orderId: id,
    settledAt: placedAt,
  );

  double get discount => totals.discount;

  double get tax => totals.tax;

  double get total => totals.total;

  /// Refunded and voided tickets are excluded from revenue totals.
  double get netRevenue => status.countsAsRevenue ? total : 0;

  /// Whether this order was placed recently (within the last 15 minutes).
  bool isRecent(DateTime now) =>
      now.difference(placedAt).inMinutes < 15;

  Order copyWith({
    List<OrderLine>? lines,
    PaymentType? paymentType,
    OrderStatus? status,
    OrderType? orderType,
    FulfillmentStatus? fulfillmentStatus,
    String? tableLabel,
    String? serverName,
    double? amountTendered,
    String? customerId,
    String? courierId,
  }) {
    return Order(
      id: id,
      lines: lines ?? this.lines,
      placedAt: placedAt,
      paymentType: paymentType ?? this.paymentType,
      status: status ?? this.status,
      taxRate: taxRate,
      orderType: orderType ?? this.orderType,
      fulfillmentStatus: fulfillmentStatus ?? this.fulfillmentStatus,
      discountRate: discountRate,
      tableLabel: tableLabel ?? this.tableLabel,
      serverName: serverName ?? this.serverName,
      amountTendered: amountTendered ?? this.amountTendered,
      customerId: customerId ?? this.customerId,
      courierId: courierId ?? this.courierId,
    );
  }

  /// Builds a completed sale from the open [cart].
  ///
  /// The tender defaults to whatever the cart was paid with, so the payment
  /// screen does not have to restate what it already recorded.
  factory Order.fromCart({
    required String id,
    required Cart cart,
    required DateTime placedAt,
    PaymentType? paymentType,
    double? amountTendered,
    OrderType orderType = OrderType.dineIn,
    String? tableLabel,
    String serverName = 'House',
    OrderStatus status = OrderStatus.paid,
    String? customerId,
    String? courierId,
  }) {
    return Order(
      id: id,
      placedAt: placedAt,
      paymentType: paymentType ?? cart.payment.method,
      status: status,
      taxRate: cart.taxRate,
      orderType: orderType,
      discountRate: cart.discountRate,
      tableLabel: tableLabel,
      serverName: serverName,
      amountTendered: amountTendered ?? cart.payment.amountTendered,
      customerId: customerId,
      courierId: courierId,
      lines: [
        for (final line in cart.items)
          OrderLine(
            itemId: line.item.id,
            name: line.item.name,
            emoji: line.item.emoji,
            unitPrice: line.item.price,
            quantity: line.quantity,
            note: line.note,
          ),
      ],
    );
  }
}
