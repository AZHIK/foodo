import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/order_totals.dart';
import '../models/payment.dart';
import 'settings_provider.dart';

/// Owns the open order.
///
/// Every mutation produces a new [Cart]; totals are computed by the model, so
/// this class only decides *what* is in the order, never what it costs.
class CartNotifier extends Notifier<Cart> {
  @override
  Cart build() {
    // `read`, not `watch`: the ticket is opened at whatever rate the business
    // profile carries, and keeps it. Watching would rebuild — and so clear —
    // an open cart the moment someone edited the tax rate in Settings, which
    // is the last thing a cashier mid-order needs.
    return Cart(taxRate: ref.read(taxRateProvider));
  }

  /// Adds [quantity] of [item], merging into the existing line if present.
  void add(MenuItem item, {int quantity = 1}) {
    if (!item.isAvailable || quantity <= 0) return;

    final index = state.items.indexWhere((line) => line.item.id == item.id);
    if (index == -1) {
      state = state.copyWith(
        items: [...state.items, CartItem(item: item, quantity: quantity)],
      );
      return;
    }

    final existing = state.items[index];
    _replaceAt(index, existing.copyWith(quantity: existing.quantity + quantity));
  }

  /// Decrements by one, removing the line when it hits zero.
  void decrement(String itemId) {
    final index = state.items.indexWhere((line) => line.item.id == itemId);
    if (index == -1) return;

    final existing = state.items[index];
    if (existing.quantity <= 1) {
      remove(itemId);
    } else {
      _replaceAt(index, existing.copyWith(quantity: existing.quantity - 1));
    }
  }

  /// Sets an absolute quantity. A [quantity] of zero or less removes the line.
  void setQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      remove(itemId);
      return;
    }
    final index = state.items.indexWhere((line) => line.item.id == itemId);
    if (index == -1) return;
    _replaceAt(index, state.items[index].copyWith(quantity: quantity));
  }

  void remove(String itemId) {
    state = state.copyWith(
      items: state.items.where((line) => line.item.id != itemId).toList(),
    );
  }

  void setNote(String itemId, String? note) {
    final index = state.items.indexWhere((line) => line.item.id == itemId);
    if (index == -1) return;
    _replaceAt(index, state.items[index].copyWith(note: note));
  }

  void applyDiscount(double rate) {
    state = state.copyWith(discountRate: rate.clamp(0.0, 1.0));
  }

  // -------------------------------------------------------------------------
  // Payment
  //
  // The ticket being paid for is the same ticket that was built, so payment
  // state lives here rather than in a parallel "order being paid" provider
  // that would have to be kept in step with this one.
  // -------------------------------------------------------------------------

  /// Switches tender.
  ///
  /// Any cash keyed in is dropped: a 50 counted out for cash means nothing
  /// once the customer changes their mind and hands over a card.
  void selectPaymentMethod(PaymentType method) {
    if (method == state.payment.method) return;
    state = state.copyWith(
      payment: state.payment.copyWith(method: method, clearTendered: true),
    );
  }

  /// Sets the cash handed over. Null (or a negative) clears the entry, which
  /// is what an empty keypad display means.
  void setAmountTendered(double? amount) {
    state = state.copyWith(
      payment: amount == null || amount <= 0
          ? state.payment.copyWith(clearTendered: true)
          : state.payment.copyWith(amountTendered: amount),
    );
  }

  /// Adds a note or coin to the tender — the quick-amount chips.
  void addTender(double amount) =>
      setAmountTendered((state.payment.amountTendered ?? 0) + amount);

  /// Customer paid to the cent; no change to count out.
  void tenderExact() => setAmountTendered(state.totals.total);

  /// Records that payment settled, against the sale [orderId] the ledger just
  /// created.
  ///
  /// Deliberately does *not* clear the cart: the receipt screen is the next
  /// step and it reads these same lines. Clearing is the "New sale" button's
  /// job, at the end of the flow.
  void markPaid({required String orderId, DateTime? at}) {
    if (state.isEmpty || state.isPaid) return;
    state = state.copyWith(
      payment: state.payment.copyWith(
        orderId: orderId,
        settledAt: at ?? DateTime.now(),
      ),
    );
  }

  /// Abandons an in-progress payment, keeping the lines — backing out of the
  /// payment screen should not cost the cashier the order they just rang up.
  void resetPayment() => state = state.copyWith(payment: const PaymentDetails());

  /// Clears the order but keeps the store's tax rate.
  void clear() => state = Cart(taxRate: state.taxRate);

  void _replaceAt(int index, CartItem line) {
    final items = [...state.items];
    items[index] = line;
    state = state.copyWith(items: items);
  }
}

final cartProvider = NotifierProvider<CartNotifier, Cart>(CartNotifier.new);

/// Item count for the badge on the cart button / bottom bar.
///
/// A separate provider so the badge does not rebuild on price-only changes.
final cartItemCountProvider = Provider<int>(
  (ref) => ref.watch(cartProvider.select((cart) => cart.itemCount)),
);

/// Quantity of a single menu item, so a [MenuItemCard] rebuilds only when its
/// own line changes rather than on every cart mutation.
final cartQuantityProvider = Provider.family<int, String>(
  (ref, itemId) => ref.watch(cartProvider.select((c) => c.quantityOf(itemId))),
);

/// Subtotal, tax and total for the open order — the single place every screen
/// in the checkout flow asks what this ticket costs.
///
/// The POS panel, the payment screen and the receipt all read this rather than
/// each doing the arithmetic, so there is no way for the number on the keypad
/// to differ from the number on the printout.
final orderTotalsProvider = Provider<OrderTotals>(
  (ref) => ref.watch(cartProvider.select((cart) => cart.totals)),
);

/// Tender, amount handed over and settlement state for the open order.
final paymentDetailsProvider = Provider<PaymentDetails>(
  (ref) => ref.watch(cartProvider.select((cart) => cart.payment)),
);

/// Change owed right now, or null when the tender cannot produce change.
///
/// Recomputed as the keypad is typed into, which is what makes the change-due
/// row live rather than something the cashier has to work out.
final changeDueProvider = Provider<double?>(
  (ref) => ref.watch(paymentDetailsProvider).changeFor(ref.watch(orderTotalsProvider)),
);

/// Whether "Confirm payment" is live: something to charge for, not already
/// charged, and enough tendered to cover it.
final canConfirmPaymentProvider = Provider<bool>((ref) {
  final payment = ref.watch(paymentDetailsProvider);
  final hasItems = ref.watch(cartItemCountProvider) > 0;
  return hasItems && !payment.isPaid && payment.covers(ref.watch(orderTotalsProvider));
});
