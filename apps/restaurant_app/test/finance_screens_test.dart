/// Smoke tests for the Other Expenses / Other Incomes screens and their
/// notifiers in demo mode (no store context — see `newTestContainer()`).
///
/// Mirrors the shape of `inventory_groceries_screen_test.dart`: a plain
/// `MaterialApp` mount (no full router/permission-gate — those are exercised
/// separately) verifying the demo-mode regression guard, plus direct
/// provider-level checks of `create`/`edit`/`delete` now that they're
/// AsyncNotifier methods instead of the old synchronous `upsert`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/data/mock_finance.dart';
import 'package:restaurant_pos/models/order.dart';
import 'package:restaurant_pos/providers/other_expenses_provider.dart';
import 'package:restaurant_pos/providers/other_incomes_provider.dart';
import 'package:restaurant_pos/screens/finance/other_expenses_screen.dart';
import 'package:restaurant_pos/screens/finance/other_incomes_screen.dart';
import 'package:restaurant_pos/theme/app_theme.dart';

import 'test_helpers/test_container.dart';

Future<void> pumpScreen(WidgetTester tester, ProviderContainer container, Widget screen) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.light(), home: Scaffold(body: screen)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('OtherExpensesScreen — demo mode', () {
    testWidgets('renders the mock rows with no store context', (tester) async {
      final container = newTestContainer();
      await pumpScreen(tester, container, const OtherExpensesScreen());

      expect(find.text('Other expenses'), findsWidgets);
      // At least one seeded mock description shows up in the table.
      expect(find.text(MockFinance.expenses.first.description), findsWidgets);
    });

    test('create/edit/delete work against in-memory state', () async {
      final container = newTestContainer();
      // AsyncNotifier.build() always resolves via a microtask, even when
      // its body has no real `await` — wait for the initial mock-data load
      // before asserting counts, or `before` reads as an empty AsyncLoading.
      final before = (await container.read(otherExpensesProvider.future)).length;
      final notifier = container.read(otherExpensesProvider.notifier);

      final created = await notifier.create(
        date: DateTime(2026, 1, 1),
        categoryId: 'supplies',
        description: 'Napkins',
        amount: 12.5,
        paymentType: PaymentType.cash,
      );
      expect(container.read(otherExpensesListProvider).length, before + 1);
      expect(created.syncStatus, 'synced'); // demo mode: no outbox involved

      final edited = await notifier.edit(
        created,
        date: created.date,
        categoryId: created.categoryId,
        description: 'Napkins (bulk)',
        amount: 20.0,
        paymentType: created.paymentType,
      );
      expect(edited.description, 'Napkins (bulk)');
      expect(
        container.read(otherExpensesListProvider).firstWhere((e) => e.id == created.id).amount,
        20.0,
      );

      await notifier.delete(created.id);
      expect(
        container.read(otherExpensesListProvider).any((e) => e.id == created.id),
        isFalse,
      );
    });
  });

  group('OtherIncomesScreen — demo mode', () {
    testWidgets('renders the mock rows with no store context', (tester) async {
      final container = newTestContainer();
      await pumpScreen(tester, container, const OtherIncomesScreen());

      expect(find.text('Other incomes'), findsWidgets);
      expect(find.text(MockFinance.incomes.first.description), findsWidgets);
    });

    test('create/edit/delete work against in-memory state', () async {
      final container = newTestContainer();
      final before = (await container.read(otherIncomesProvider.future)).length;
      final notifier = container.read(otherIncomesProvider.notifier);

      final created = await notifier.create(
        date: DateTime(2026, 1, 1),
        categoryId: 'catering',
        description: 'Office lunch',
        amount: 80.0,
        paymentType: PaymentType.card,
        source: 'Acme Corp',
      );
      expect(container.read(otherIncomesListProvider).length, before + 1);

      await notifier.delete(created.id);
      expect(
        container.read(otherIncomesListProvider).any((i) => i.id == created.id),
        isFalse,
      );
    });
  });
}
