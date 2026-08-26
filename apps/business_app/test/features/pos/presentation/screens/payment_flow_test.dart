import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink_business/features/pos/presentation/screens/payment_screen.dart';
import 'package:foodlink_business/shared/fakes/fake_data_service.dart';

void main() {
  testWidgets('selecting a payment method completes a fake sale', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        fakeSalesProvider.overrideWith((ref) {
          final notifier = FakeSalesNotifier(FakeDataService());
          notifier.loadSales(const []);
          return notifier;
        }),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: PaymentScreen(
            lines: [
              PaymentLineDraft(
                itemId: 'item_1',
                itemName: 'Ugali',
                quantity: 1,
                unitPriceSenti: 200000,
              ),
            ],
            subtotalSenti: 200000,
            saleDiscountSenti: 0,
            taxSenti: 36000,
            totalSenti: 236000,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    final sales = container.read(fakeSalesProvider);
    expect(sales, hasLength(1));
    expect(sales.single.paymentMethod, FakePaymentMethod.cash);
    expect(sales.single.totalSenti, 236000);
  });
}
