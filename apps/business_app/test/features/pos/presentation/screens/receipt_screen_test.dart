import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink_business/features/pos/presentation/screens/receipt_screen.dart';
import 'package:foodlink_business/shared/fakes/fake_data_service.dart';

void main() {
  testWidgets('displays line items and totals for a completed sale', (
    tester,
  ) async {
    final sale = FakeSale(
      id: 'sale_1',
      receiptNumber: 'REC-1',
      status: FakeSaleStatus.completed,
      paymentMethod: FakePaymentMethod.cash,
      lines: const [
        FakeSaleLine(
          itemId: 'item_1',
          itemName: 'Ugali',
          quantity: 2,
          unitPriceSenti: 200000,
          subtotalSenti: 400000,
        ),
      ],
      subtotalSenti: 400000,
      discountSenti: 0,
      taxSenti: 72000,
      totalSenti: 472000,
      tenderedSenti: 472000,
      staffName: 'Store Admin',
      customerName: 'Walk-in',
      notes: null,
      isTimeSuspect: false,
      createdAt: DateTime(2026, 1, 1, 10, 30),
      closedAt: DateTime(2026, 1, 1, 10, 30),
      createdAtOffsetMs: 0,
      closedAtOffsetMs: 0,
    );

    await tester.pumpWidget(MaterialApp(home: ReceiptScreen(sale: sale)));

    expect(find.text('Ugali'), findsOneWidget);
    expect(find.text('TZS 4,720'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
  });
}
