import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/data/mock_menu.dart';
import 'package:restaurant_pos/models/order.dart';
import 'package:restaurant_pos/models/order_totals.dart';
import 'package:restaurant_pos/providers/cart_provider.dart';
import 'package:restaurant_pos/providers/orders_provider.dart';

/// The checkout flow's shared state: one totals calculation, one payment
/// record, read by the payment screen, the receipt and sale detail alike.
void main() {
  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  /// Puts a known ticket in the cart and returns its container.
  ProviderContainer withOrder() {
    final container = makeContainer();
    final cart = container.read(cartProvider.notifier);
    // Two items so the subtotal is not just one price echoed back.
    cart.add(MockMenu.items.firstWhere((i) => i.isAvailable), quantity: 2);
    cart.add(MockMenu.items.lastWhere((i) => i.isAvailable));
    return container;
  }

  group('OrderTotals', () {
    test('discount is applied before tax', () {
      final totals = OrderTotals.from(
        subtotal: 100,
        taxRate: 0.10,
        discountRate: 0.20,
      );

      expect(totals.discount, 20);
      expect(totals.tax, closeTo(8, 0.0001));
      expect(totals.total, closeTo(88, 0.0001));
    });

    test('a tender of exactly the total counts as covered', () {
      // 33.33 * 1.0825 is the kind of number that lands a hair off a round
      // figure once it has been through a double.
      final totals = OrderTotals.from(subtotal: 33.33, taxRate: 0.0825);

      expect(totals.covers(totals.total), isTrue);
      expect(totals.changeFrom(totals.total), 0);
      expect(totals.covers(totals.total - 0.01), isFalse);
    });

    test('change is never negative', () {
      final totals = OrderTotals.from(subtotal: 50, taxRate: 0);
      // Underpaid: the row reads zero, not a negative "change owed".
      expect(totals.changeFrom(20), 0);
      expect(totals.changeFrom(60), 10);
    });
  });

  group('cart payment state', () {
    test('orderTotalsProvider agrees with the cart it reads', () {
      final container = withOrder();

      expect(
        container.read(orderTotalsProvider).total,
        container.read(cartProvider).total,
      );
    });

    test('confirm stays disabled until the cash covers the total', () {
      final container = withOrder();
      final cart = container.read(cartProvider.notifier);
      final total = container.read(orderTotalsProvider).total;

      cart.selectPaymentMethod(PaymentType.cash);
      expect(container.read(canConfirmPaymentProvider), isFalse);

      cart.setAmountTendered(total - 1);
      expect(container.read(canConfirmPaymentProvider), isFalse);
      expect(container.read(changeDueProvider), 0);

      cart.addTender(20);
      expect(container.read(canConfirmPaymentProvider), isTrue);
      expect(container.read(changeDueProvider), closeTo(19, 0.0001));
    });

    test('exact tender leaves no change', () {
      final container = withOrder();
      final cart = container.read(cartProvider.notifier);

      cart.selectPaymentMethod(PaymentType.cash);
      cart.tenderExact();

      expect(container.read(canConfirmPaymentProvider), isTrue);
      expect(container.read(changeDueProvider), 0);
    });

    test('a card tender needs no amount, and reports no change', () {
      final container = withOrder();
      final cart = container.read(cartProvider.notifier);

      cart.selectPaymentMethod(PaymentType.qris);

      expect(container.read(canConfirmPaymentProvider), isTrue);
      expect(container.read(changeDueProvider), isNull);
    });

    test('switching tender drops cash that was already keyed in', () {
      final container = withOrder();
      final cart = container.read(cartProvider.notifier);

      cart.selectPaymentMethod(PaymentType.cash);
      cart.setAmountTendered(100);
      cart.selectPaymentMethod(PaymentType.card);

      expect(container.read(paymentDetailsProvider).amountTendered, isNull);
    });

    test('marking paid keeps the lines for the receipt', () {
      final container = withOrder();
      final cart = container.read(cartProvider.notifier);
      final itemCount = container.read(cartItemCountProvider);

      cart.selectPaymentMethod(PaymentType.cash);
      cart.tenderExact();
      cart.markPaid(orderId: 'ORD-9001');

      final payment = container.read(paymentDetailsProvider);
      expect(payment.isPaid, isTrue);
      expect(payment.orderId, 'ORD-9001');
      // The receipt screen renders these same lines — clearing is the "New
      // sale" button's job, not payment's.
      expect(container.read(cartItemCountProvider), itemCount);
    });

    test('an empty cart cannot be marked paid', () {
      final container = makeContainer();
      container.read(cartProvider.notifier).markPaid(orderId: 'ORD-9001');

      expect(container.read(paymentDetailsProvider).isPaid, isFalse);
    });

    test('clearing resets the payment along with the lines', () {
      final container = withOrder();
      final cart = container.read(cartProvider.notifier);

      cart.selectPaymentMethod(PaymentType.cash);
      cart.tenderExact();
      cart.markPaid(orderId: 'ORD-9001');
      cart.clear();

      final payment = container.read(paymentDetailsProvider);
      expect(payment.isPaid, isFalse);
      expect(payment.amountTendered, isNull);
      expect(container.read(cartProvider).isEmpty, isTrue);
    });

    test('backing out of payment keeps the order', () {
      final container = withOrder();
      final cart = container.read(cartProvider.notifier);

      cart.selectPaymentMethod(PaymentType.cash);
      cart.setAmountTendered(100);
      cart.resetPayment();

      expect(container.read(cartProvider).isNotEmpty, isTrue);
      expect(container.read(paymentDetailsProvider).amountTendered, isNull);
    });
  });

  group('the sale a payment produces', () {
    test('carries the tender and its totals into the ledger', () {
      final container = withOrder();
      final cart = container.read(cartProvider.notifier);
      cart.selectPaymentMethod(PaymentType.cash);
      cart.setAmountTendered(200);

      final open = container.read(cartProvider);
      final order = container
          .read(ordersProvider.notifier)
          .placeOrder(cart: open, tableLabel: 'Table 4');

      expect(order.paymentType, PaymentType.cash);
      expect(order.amountTendered, 200);
      // Sale detail reads this; it must be the number the receipt showed.
      expect(order.totals.total, closeTo(open.totals.total, 0.0001));
      expect(order.payment.changeFor(order.totals), closeTo(200 - open.total, 0.0001));
    });

    test('refunding preserves the tender recorded on the sale', () {
      final container = withOrder();
      final cart = container.read(cartProvider.notifier);
      cart.selectPaymentMethod(PaymentType.cash);
      cart.setAmountTendered(200);

      final orders = container.read(ordersProvider.notifier);
      final order = orders.placeOrder(cart: container.read(cartProvider));
      orders.refund(order.id);

      final refunded = container.read(orderByIdProvider(order.id))!;
      expect(refunded.status, OrderStatus.refunded);
      expect(refunded.amountTendered, 200);
      expect(
        container.read(orderTotalsByIdProvider(order.id)).total,
        closeTo(order.total, 0.0001),
      );
    });
  });
}
