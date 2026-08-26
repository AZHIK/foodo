import 'dart:math';

import '../models/order.dart';
import 'mock_menu.dart';

/// Generates a plausible sales history so the Sales screen has something to
/// sort, filter and summarise.
///
/// Seeded so the data is stable across hot reloads — a moving table is very
/// hard to evaluate a layout against.
abstract final class MockOrders {
  static const _servers = ['Ava', 'Marco', 'Priya', 'Dan', 'Yuki', 'Sofia'];
  static const _taxRate = 0.0825;

  static List<Order> generate({int count = 60, DateTime? now}) {
    final rand = Random(20260812);
    final reference = now ?? DateTime.now();
    final menu = MockMenu.items.where((i) => i.isAvailable).toList();

    final orders = <Order>[];
    for (var i = 0; i < count; i++) {
      // Today carries a little more than an average day — it is a partial day,
      // but the default view still needs meaningful numbers — and the rest of
      // the week is spread evenly behind it.
      //
      // Weighted this way rather than dropping a third of all trade onto
      // today: a seven-day trend built from that reads as a business that did
      // nothing all week and then took £1,600 in an afternoon, which is a
      // fixture artefact rather than anything a restaurant looks like.
      final daysAgo = switch (i) {
        _ when i < count * 0.14 => 0,
        _ when i < count * 0.52 => 1 + rand.nextInt(6),
        _ when i < count * 0.80 => 7 + rand.nextInt(21),
        _ => 28 + rand.nextInt(40),
      };
      final placedAt = DateTime(
        reference.year,
        reference.month,
        reference.day - daysAgo,
        10 + rand.nextInt(12),
        rand.nextInt(60),
        rand.nextInt(60),
      );

      final lineCount = 1 + rand.nextInt(5);
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
            quantity: 1 + rand.nextInt(3),
          ),
        );
      }

      final roll = rand.nextDouble();
      final status = switch (roll) {
        < 0.07 => OrderStatus.refunded,
        < 0.12 => OrderStatus.voided,
        < 0.16 => OrderStatus.pending,
        _ => OrderStatus.paid,
      };

      // Most covers are seated; the rest split between counter and delivery.
      final typeRoll = rand.nextDouble();
      final orderType = typeRoll < 0.62
          ? OrderType.dineIn
          : typeRoll < 0.87
          ? OrderType.takeaway
          : OrderType.delivery;

      // Orders from prior days are completed; today's orders spread across stages.
      final fulfillmentStatus = daysAgo > 0
          ? FulfillmentStatus.completed
          : switch (rand.nextDouble()) {
              < 0.1 => FulfillmentStatus.new_,
              < 0.25 => FulfillmentStatus.preparing,
              < 0.65 => FulfillmentStatus.ready,
              < 0.85 => FulfillmentStatus.outForDelivery,
              _ => FulfillmentStatus.completed,
            };

      orders.add(
        Order(
          id: 'ORD-${(1042 + i).toString().padLeft(4, '0')}',
          lines: lines,
          placedAt: placedAt,
          paymentType: _weightedPayment(rand),
          status: status,
          taxRate: _taxRate,
          orderType: orderType,
          fulfillmentStatus: fulfillmentStatus,
          discountRate: rand.nextDouble() < 0.12 ? 0.10 : 0,
          tableLabel: orderType.usesTable
              ? 'Table ${1 + rand.nextInt(24)}'
              : null,
          serverName: _servers[rand.nextInt(_servers.length)],
        ),
      );
    }

    orders.sort((a, b) => b.placedAt.compareTo(a.placedAt));
    return orders;
  }

  /// Card-heavy mix, the way a real restaurant's takings look.
  static PaymentType _weightedPayment(Random rand) {
    final roll = rand.nextDouble();
    if (roll < 0.58) return PaymentType.card;
    if (roll < 0.80) return PaymentType.mobile;
    if (roll < 0.95) return PaymentType.cash;
    return PaymentType.giftCard;
  }
}
