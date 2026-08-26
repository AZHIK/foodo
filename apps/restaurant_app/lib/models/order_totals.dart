import 'package:flutter/foundation.dart';

/// Subtotal → discount → tax → total for one order.
///
/// The app's only implementation of that arithmetic. [Cart] and [Order] each
/// build one of these rather than carrying their own copy of the rules, so an
/// open ticket, the payment screen, the printed receipt and the sale in the
/// ledger can never quietly disagree about what the customer owed.
@immutable
class OrderTotals {
  const OrderTotals._({
    required this.subtotal,
    required this.discountRate,
    required this.discount,
    required this.taxRate,
    required this.tax,
    required this.total,
  });

  /// Discount comes off before tax: tax is owed on what the customer actually
  /// pays, not on the pre-discount menu price.
  factory OrderTotals.from({
    required double subtotal,
    required double taxRate,
    double discountRate = 0,
  }) {
    final discount = subtotal * discountRate;
    final taxable = subtotal - discount;
    final tax = taxable * taxRate;

    return OrderTotals._(
      subtotal: subtotal,
      discountRate: discountRate,
      discount: discount,
      taxRate: taxRate,
      tax: tax,
      total: taxable + tax,
    );
  }

  static const zero = OrderTotals._(
    subtotal: 0,
    discountRate: 0,
    discount: 0,
    taxRate: 0,
    tax: 0,
    total: 0,
  );

  final double subtotal;
  final double discountRate;
  final double discount;
  final double taxRate;
  final double tax;
  final double total;

  bool get hasDiscount => discountRate > 0 && discount > 0;

  /// Half a cent — below anything that can be tendered or displayed.
  ///
  /// Cash keyed in as exactly the total must count as covered even though the
  /// tax multiplication leaves the double a hair above the round number the
  /// cashier read off the screen.
  static const _epsilon = 0.005;

  /// Whether [tendered] settles this order.
  bool covers(double tendered) => tendered >= total - _epsilon;

  /// Change owed for [tendered]. Never negative, and never a sub-cent crumb.
  double changeFrom(double tendered) {
    final change = tendered - total;
    return change <= _epsilon ? 0 : change;
  }

  // Value equality so `select`-ing totals out of the cart can actually dedupe:
  // a fresh instance is built on every read, so identity would report a change
  // on every unrelated cart rebuild.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderTotals &&
          other.subtotal == subtotal &&
          other.discountRate == discountRate &&
          other.taxRate == taxRate;

  @override
  int get hashCode => Object.hash(subtotal, discountRate, taxRate);
}
