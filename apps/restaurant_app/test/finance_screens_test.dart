/// Smoke tests for the Other Expenses / Other Incomes screens and their
/// notifiers with no store context (see `newTestContainer()`).
///
/// With no context the lists are empty and mutations are refused — the
/// screens render their empty state instead of sample data.
///
/// Mirrors the shape of `inventory_groceries_screen_test.dart`: a plain
/// `MaterialApp` mount (no full router/permission-gate — those are exercised
/// separately).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
  group('OtherExpensesScreen — no store context', () {
    testWidgets('renders with an empty list', (tester) async {
      final container = newTestContainer();
      await pumpScreen(tester, container, const OtherExpensesScreen());

      expect(find.text('Other expenses'), findsWidgets);
      expect(container.read(otherExpensesListProvider), isEmpty);
    });

    test('mutations require a store context', () async {
      final container = newTestContainer();
      // AsyncNotifier.build() always resolves via a microtask, even when
      // its body has no real `await` — wait for the initial empty load
      // before asserting, or the read below sees an AsyncLoading.
      await container.read(otherExpensesProvider.future);
      final notifier = container.read(otherExpensesProvider.notifier);

      await expectLater(
        notifier.create(
          date: DateTime(2026, 1, 1),
          categoryId: 'supplies',
          description: 'Napkins',
          amount: 12.5,
          paymentType: PaymentType.cash,
        ),
        throwsStateError,
      );
      await expectLater(notifier.delete('no-such-id'), throwsStateError);
    });
  });

  group('OtherIncomesScreen — no store context', () {
    testWidgets('renders with an empty list', (tester) async {
      final container = newTestContainer();
      await pumpScreen(tester, container, const OtherIncomesScreen());

      expect(find.text('Other incomes'), findsWidgets);
      expect(container.read(otherIncomesListProvider), isEmpty);
    });

    test('mutations require a store context', () async {
      final container = newTestContainer();
      await container.read(otherIncomesProvider.future);
      final notifier = container.read(otherIncomesProvider.notifier);

      await expectLater(
        notifier.create(
          date: DateTime(2026, 1, 1),
          categoryId: 'catering',
          description: 'Office lunch',
          amount: 80.0,
          paymentType: PaymentType.card,
          source: 'Acme Corp',
        ),
        throwsStateError,
      );
      await expectLater(notifier.delete('no-such-id'), throwsStateError);
    });
  });
}
