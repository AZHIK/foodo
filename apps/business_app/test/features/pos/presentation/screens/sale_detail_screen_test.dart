import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink_business/features/pos/presentation/screens/sale_detail_screen.dart';
import 'package:foodlink_business/shared/fakes/fake_data_service.dart';

Widget _buildApp({
  required ProviderContainer container,
  required String saleId,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(home: SaleDetailScreen(saleId: saleId)),
  );
}

ProviderContainer _container(List<FakeSale> sales) {
  return ProviderContainer(
    overrides: [
      fakeSalesProvider.overrideWith((ref) {
        final notifier = FakeSalesNotifier(FakeDataService());
        notifier.loadSales(sales);
        return notifier;
      }),
    ],
  );
}

FakeSale _sale(FakeSaleStatus status) {
  return FakeSale(
    id: 'sale_1',
    receiptNumber: 'REC-1',
    status: status,
    paymentMethod: FakePaymentMethod.cash,
    lines: const [
      FakeSaleLine(
        itemId: 'item_1',
        itemName: 'Ugali',
        quantity: 1,
        unitPriceSenti: 200000,
        subtotalSenti: 200000,
      ),
    ],
    subtotalSenti: 200000,
    discountSenti: 0,
    taxSenti: 36000,
    totalSenti: 236000,
    tenderedSenti: 236000,
    staffName: 'Store Admin',
    customerName: 'Walk-in',
    notes: null,
    isTimeSuspect: false,
    createdAt: DateTime(2026, 1, 1),
    closedAt: DateTime(2026, 1, 1),
    createdAtOffsetMs: 0,
    closedAtOffsetMs: 0,
  );
}

void main() {
  testWidgets('void/refund actions only available on completed sales', (
    tester,
  ) async {
    final completedContainer = _container([_sale(FakeSaleStatus.completed)]);
    addTearDown(completedContainer.dispose);
    await tester.pumpWidget(
      _buildApp(container: completedContainer, saleId: 'sale_1'),
    );
    await tester.pumpAndSettle();

    final voidButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Void'),
    );
    expect(voidButton.onPressed, isNotNull);

    final voidedContainer = _container([_sale(FakeSaleStatus.voided)]);
    addTearDown(voidedContainer.dispose);
    await tester.pumpWidget(
      _buildApp(container: voidedContainer, saleId: 'sale_1'),
    );
    await tester.pumpAndSettle();

    final disabledVoidButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Void'),
    );
    expect(disabledVoidButton.onPressed, isNull);
  });

  testWidgets('confirmation dialog requires a reason before voiding', (
    tester,
  ) async {
    final container = _container([_sale(FakeSaleStatus.completed)]);
    addTearDown(container.dispose);
    await tester.pumpWidget(_buildApp(container: container, saleId: 'sale_1'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Void'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Void').last);
    await tester.pumpAndSettle();
    expect(find.text('Reason is required'), findsOneWidget);
    expect(
      container.read(fakeSalesProvider).single.status,
      FakeSaleStatus.completed,
    );

    await tester.enterText(find.byType(TextFormField), 'Wrong order');
    await tester.tap(find.text('Void').last);
    await tester.pumpAndSettle();
    expect(
      container.read(fakeSalesProvider).single.status,
      FakeSaleStatus.voided,
    );
  });
}
