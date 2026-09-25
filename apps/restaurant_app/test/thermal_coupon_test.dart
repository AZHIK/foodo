import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos/models/order.dart';
import 'package:restaurant_pos/printing/thermal_coupon.dart';
import 'package:restaurant_pos/printing/thermal_receipt.dart';

Order _sampleOrder() {
  return Order(
    id: 'ORD-0042',
    placedAt: DateTime(2026, 8, 6, 14, 15),
    paymentType: PaymentType.cash,
    status: OrderStatus.paid,
    taxRate: 0.0825,
    orderType: OrderType.dineIn,
    discountRate: 0.10,
    tableLabel: 'Table 12',
    serverName: 'Ava',
    amountTendered: 15000,
    lines: const [
      OrderLine(
        itemId: '1',
        name: 'Pilau Beef',
        emoji: '🍚',
        unitPrice: 4800,
        quantity: 2,
      ),
      OrderLine(
        itemId: '2',
        name: 'Chips Mayai',
        emoji: '🍟',
        unitPrice: 4000,
        quantity: 1,
      ),
    ],
  );
}

void main() {
  group('thermal coupon', () {
    test('shows store proof, a big order number, and the items', () {
      final lines = buildThermalCoupon(
        order: _sampleOrder(),
        storeName: 'Mama Ntilie Kitchen',
        phone: '+255 700 000 000',
        addressLines: const ['Sam Nujoma Rd, Dar es Salaam'],
      );
      final text = renderThermalText(lines);

      expect(text, contains('Mama Ntilie Kitchen'));
      expect(text, contains('+255 700 000 000'));
      expect(text, contains('ORD-0042'));
      expect(text, contains('2x Pilau Beef'));
      expect(text, contains('1x Chips Mayai'));
      expect(text, contains('Table 12'));

      // The items — not the order number — are the paper's largest rows.
      final big = lines.where((l) => l.big).map((l) => l.text).toList();
      expect(big, contains('2x Pilau Beef'));
      expect(big, contains('1x Chips Mayai'));
      expect(
        lines.where((l) => l.text == 'ORD-0042').single.big,
        isFalse,
      );
    });

    test('carries no prices, totals or payment', () {
      final text = renderThermalText(
        buildThermalCoupon(
          order: _sampleOrder(),
          storeName: 'Mama Ntilie Kitchen',
        ),
      );

      expect(text, isNot(contains('TOTAL')));
      expect(text, isNot(contains('Subtotal')));
      expect(text, isNot(contains('Paid by')));
      expect(text, isNot(contains('Tendered')));
      expect(text, isNot(contains('TSh')));
      expect(text, isNot(contains('{QR:')));
    });

    test('every text line fits the paper width', () {
      for (final width in [
        ThermalReceipt.lineWidth,
        ThermalReceipt.narrowLineWidth,
      ]) {
        final lines = buildThermalCoupon(
          order: _sampleOrder(),
          storeName: 'A Very Long Store Name That Must Wrap Nicely',
          lineWidth: width,
        );
        final text = renderThermalText(lines, lineWidth: width);
        for (final line in text.split('\n')) {
          if (line.isEmpty) continue;
          expect(line.length, lessThanOrEqualTo(width));
        }
      }
    });
  });
}
