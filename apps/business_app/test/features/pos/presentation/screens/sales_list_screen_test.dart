import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink_business/features/pos/presentation/screens/sales_list_screen.dart';
import 'package:foodlink_business/shared/fakes/fake_data_service.dart';
import 'package:foodlink_business/shared/widgets/data_table/app_data_table.dart';

Widget _buildApp(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: SalesListScreen()),
  );
}

ProviderContainer _container() {
  return ProviderContainer(
    overrides: [
      fakeSalesProvider.overrideWith((ref) {
        final notifier = FakeSalesNotifier(FakeDataService());
        notifier.loadSales(_sales);
        return notifier;
      }),
    ],
  );
}

final _sales = [
  FakeSale(
    id: 'sale_1',
    receiptNumber: 'REC-1',
    status: FakeSaleStatus.completed,
    paymentMethod: FakePaymentMethod.cash,
    lines: const [],
    subtotalSenti: 100000,
    discountSenti: 0,
    taxSenti: 18000,
    totalSenti: 118000,
    tenderedSenti: 118000,
    staffName: 'Store Admin',
    customerName: 'Walk-in',
    notes: null,
    isTimeSuspect: true,
    createdAt: DateTime.now(),
    closedAt: DateTime.now(),
    createdAtOffsetMs: 0,
    closedAtOffsetMs: 0,
  ),
  FakeSale(
    id: 'sale_2',
    receiptNumber: 'REC-2',
    status: FakeSaleStatus.voided,
    paymentMethod: FakePaymentMethod.card,
    lines: const [],
    subtotalSenti: 200000,
    discountSenti: 0,
    taxSenti: 36000,
    totalSenti: 236000,
    tenderedSenti: 0,
    staffName: 'Store Admin',
    customerName: 'Walk-in',
    notes: null,
    isTimeSuspect: false,
    createdAt: DateTime(2026, 1, 1),
    closedAt: DateTime(2026, 1, 1),
    createdAtOffsetMs: 0,
    closedAtOffsetMs: 0,
  ),
];

void main() {
  testWidgets('renders fake sales in AppDataTable', (tester) async {
    final container = _container();
    addTearDown(container.dispose);
    await tester.pumpWidget(_buildApp(container));
    await tester.pumpAndSettle();

    expect(find.byType(AppDataTable<FakeSale>), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Voided'), findsOneWidget);
  });

  testWidgets('time suspect sales show distinct badge and stats are correct', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    await tester.pumpWidget(_buildApp(container));
    await tester.pumpAndSettle();

    expect(find.text('Time suspect'), findsOneWidget);
    expect(find.text('Today Sales'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    // "TZS 1,180" legitimately renders twice: once as today's revenue stat,
    // once in sale_1's own table row (it's the only completed sale today).
    expect(find.text('TZS 1,180'), findsNWidgets(2));
  });
}
