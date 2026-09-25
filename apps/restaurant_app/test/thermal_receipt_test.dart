import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos/models/order.dart';
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
  group('thermal receipt', () {
    test('carries store, order + receipt numbers, totals and payment', () {
      final text = renderThermalText(
        buildThermalReceipt(
          order: _sampleOrder(),
          storeName: 'Mama Ntilie Kitchen',
          receiptNumber: 'INV-0042',
          phone: '+255 700 000 000',
          addressLines: const ['Sam Nujoma Rd, Dar es Salaam'],
        ),
      );

      expect(text, contains('Mama Ntilie Kitchen'));
      expect(text, contains('+255 700 000 000'));
      expect(text, contains('Order No: ORD-0042'));
      expect(text, contains('Receipt : INV-0042'));
      expect(text, contains('Pilau Beef x2'));
      expect(text, contains('TOTAL'));
      expect(text, contains('Paid by Cash'));
      expect(text, contains('Tendered'));
      expect(text, contains('Change'));
      expect(text, contains('Thank you, welcome again!'));
      expect(text, contains('{QR:'));
    });

    test('every text line fits the paper width', () {
      for (final width in [ThermalReceipt.lineWidth, ThermalReceipt.narrowLineWidth]) {
        final lines = buildThermalReceipt(
          order: _sampleOrder(),
          storeName: 'A Very Long Store Name That Must Wrap Nicely',
          receiptNumber: 'INV-0042',
          lineWidth: width,
        );
        final text = renderThermalText(lines, lineWidth: width);
        for (final line in text.split('\n')) {
          if (line.isEmpty || line.startsWith('{QR:')) continue;
          expect(line.length, lessThanOrEqualTo(width));
        }
      }
    });

    test('QR payload holds all receipt data except the welcome note', () {
      final lines = buildThermalReceipt(
        order: _sampleOrder(),
        storeName: 'Mama Ntilie Kitchen',
        receiptNumber: 'INV-0042',
        phone: '+255 700 000 000',
      );
      final qr = lines
          .where((l) => l.kind == ThermalLineKind.qr)
          .map((l) => l.text)
          .single;
      final payload = jsonDecode(qr) as Map<String, dynamic>;

      expect(payload['store']['name'], 'Mama Ntilie Kitchen');
      expect(payload['store']['phone'], '+255 700 000 000');
      expect((payload['order'] as Map)['orderNo'], 'ORD-0042');
      expect((payload['order'] as Map)['receiptNo'], 'INV-0042');
      expect((payload['lines'] as List), hasLength(2));
      expect((payload['totals'] as Map)['total'], _sampleOrder().total);
      expect((payload['payment'] as Map)['method'], 'cash');
      expect(qr, isNot(contains('welcome')));
    });

    test('skips empty optional blocks without breaking layout', () {
      final takeaway = Order(
        id: 'ORD-0043',
        placedAt: DateTime(2026, 8, 6, 18, 5),
        paymentType: PaymentType.card,
        status: OrderStatus.paid,
        taxRate: 0.0825,
        orderType: OrderType.takeaway,
        serverName: 'House',
        lines: const [
          OrderLine(
            itemId: '1',
            name: 'Samosa',
            emoji: '🥟',
            unitPrice: 1500,
            quantity: 3,
          ),
        ],
      );
      final text = renderThermalText(
        buildThermalReceipt(
          order: takeaway,
          storeName: 'Kiosk',
          receiptNumber: 'INV-0043',
        ),
      );
      expect(text, isNot(contains('Table')));
      expect(text, isNot(contains('Tendered')));
      expect(text, contains('Order No: ORD-0043'));
      expect(text, contains('Paid by Card'));
    });
  });
}
