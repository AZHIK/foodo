import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import 'orders_provider.dart';
import 'settings_provider.dart';

/// Ticket-level state for the order currently being built — everything about
/// the open order that is *not* its line items.
///
/// Kept out of [cartProvider] on purpose: switching from dine-in to takeaway
/// must not rebuild every menu card, and clearing the cart must not silently
/// reset which table the server is standing at.

/// Dine-in / takeaway / delivery, selected in the order panel header.
///
/// Starts at whatever Store Settings names as the default. Watched rather than
/// read, so changing the default re-seeds the current selection too — a venue
/// that switches to takeaway-only wants the till to follow immediately, and the
/// server can still override it per ticket.
final orderTypeProvider = StateProvider<OrderType>(
  (ref) => ref.watch(defaultOrderTypeProvider),
);

/// Table number for dine-in orders; `null` for counter, takeaway and delivery.
final tableNumberProvider = StateProvider<int?>((ref) => 12);

/// Customer this ticket will be attributed to; `null` means walk-in.
///
/// Ticket-level state, exactly like [tableNumberProvider] — it must survive
/// a cart rebuild, and clearing the cart must not silently drop who the
/// server was ringing this up for. Reset to `null` by `chargeOpenOrder`
/// (in `charge_dialog.dart`) after a *successful* charge — a new ticket
/// must not inherit the previous customer — but deliberately preserved
/// when the charge dialog is dismissed: that's a mis-tap, not an
/// intentional change of mind.
final selectedCustomerIdProvider = StateProvider<String?>((ref) => null);

/// Human label for the current ticket, e.g. "Table 12" — the form the [Order]
/// model stores. Null unless the order type is actually seated.
final tableLabelProvider = Provider<String?>((ref) {
  if (!ref.watch(orderTypeProvider).usesTable) return null;
  final table = ref.watch(tableNumberProvider);
  return table == null ? null : 'Table $table';
});

/// The id the next placed order will receive, shown in the panel header before
/// the sale exists. Derived from the sales ledger so the preview and the
/// eventual order never disagree.
final nextOrderIdProvider = Provider<String>(
  (ref) => nextOrderId(ref.watch(ordersListProvider)),
);
