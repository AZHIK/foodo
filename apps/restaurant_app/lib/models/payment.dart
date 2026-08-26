import 'package:flutter/foundation.dart';

import 'order.dart';
import 'order_totals.dart';

/// How the order in hand is being paid for.
///
/// Carried on the [Cart] rather than in a provider of its own, so the payment
/// screen, the receipt that follows it and the sale it becomes are all reading
/// one object — there is no second "the order being paid" state to keep in
/// step with the first.
@immutable
class PaymentDetails {
  const PaymentDetails({
    this.method = PaymentType.cash,
    this.amountTendered,
    this.orderId,
    this.settledAt,
  });

  final PaymentType method;

  /// Cash handed over. Null for every other tender, and for cash until the
  /// cashier has keyed something in.
  final double? amountTendered;

  /// Id of the sale this payment created. Null until [settledAt] is set, and
  /// held here because the ledger's "next id" moves on the moment the sale
  /// lands — the receipt has to remember which number was actually its own.
  final String? orderId;

  /// When the cashier confirmed payment. Null while the order is still open:
  /// this field *is* what "paid" means.
  final DateTime? settledAt;

  bool get isPaid => settledAt != null;

  bool get isCash => method == PaymentType.cash;

  /// Change owed against [totals], or null when this tender cannot produce any
  /// — a card sale, or cash with nothing keyed in yet.
  double? changeFor(OrderTotals totals) => isCash && amountTendered != null
      ? totals.changeFrom(amountTendered!)
      : null;

  /// Whether the tender is sufficient to settle [totals].
  ///
  /// Only cash can fall short here. Card and QRIS are settled by the terminal,
  /// which either approves the full amount or does not approve at all.
  bool covers(OrderTotals totals) =>
      !isCash || (amountTendered != null && totals.covers(amountTendered!));

  /// [clearTendered] exists because null is a meaningful value for
  /// [amountTendered] — passing null alone cannot distinguish "wipe it" from
  /// "leave it alone".
  PaymentDetails copyWith({
    PaymentType? method,
    double? amountTendered,
    String? orderId,
    DateTime? settledAt,
    bool clearTendered = false,
  }) {
    return PaymentDetails(
      method: method ?? this.method,
      amountTendered: clearTendered
          ? null
          : (amountTendered ?? this.amountTendered),
      orderId: orderId ?? this.orderId,
      settledAt: settledAt ?? this.settledAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentDetails &&
          other.method == method &&
          other.amountTendered == amountTendered &&
          other.orderId == orderId &&
          other.settledAt == settledAt;

  @override
  int get hashCode => Object.hash(method, amountTendered, orderId, settledAt);
}
