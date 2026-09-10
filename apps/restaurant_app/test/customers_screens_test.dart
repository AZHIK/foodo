/// Smoke tests for the Customers list/detail screens and `CustomersNotifier`
/// in demo mode (no business context — see `newTestContainer()`).
///
/// Mirrors the shape of `finance_screens_test.dart`: a plain `MaterialApp`
/// mount (no full router/permission-gate — those are exercised in
/// `charge_dialog_test.dart` for the checkout picker, and the gated screen
/// wrappers themselves have no logic of their own beyond what
/// `PermissionGatedScreen` already covers) verifying the demo-mode
/// regression guard, plus direct provider-level checks of
/// `create`/`edit`/`delete` now that they're `AsyncNotifier` methods.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/data/mock_customers.dart';
import 'package:restaurant_pos/providers/customers_provider.dart';
import 'package:restaurant_pos/screens/customers/customers_screen.dart';
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
  group('CustomersScreen — demo mode', () {
    testWidgets('renders the mock rows with no business context', (tester) async {
      final container = newTestContainer();
      await pumpScreen(tester, container, const CustomersScreen());

      expect(find.text('Customers'), findsWidgets);
      // At least one seeded mock name shows up in the table.
      expect(find.text(MockCustomers.list.first.name), findsWidgets);
    });

    test('create/edit/delete work against in-memory state', () async {
      final container = newTestContainer();
      // AsyncNotifier.build() always resolves via a microtask, even when
      // its body has no real `await` — wait for the initial mock-data load
      // before asserting counts, or `before` reads as an empty AsyncLoading.
      final before = (await container.read(customersProvider.future)).length;
      final notifier = container.read(customersProvider.notifier);

      final created = await notifier.create(
        name: 'New Walk-in',
        phone: '+1-555-0199',
        email: 'walkin@example.com',
      );
      expect(container.read(customersListProvider).length, before + 1);
      expect(created.totalOrders, 0);
      expect(created.totalSpent, 0);

      final edited = await notifier.edit(
        created,
        name: 'New Walk-in (VIP)',
        phone: created.phone,
        email: created.email,
      );
      expect(edited.name, 'New Walk-in (VIP)');
      expect(
        container.read(customersListProvider).firstWhere((c) => c.id == created.id).name,
        'New Walk-in (VIP)',
      );

      await notifier.delete(created.id);
      expect(
        container.read(customersListProvider).any((c) => c.id == created.id),
        isFalse,
      );
    });

    test('customerByIdProvider looks up a seeded mock customer', () async {
      final container = newTestContainer();
      await container.read(customersProvider.future);

      final first = MockCustomers.list.first;
      final found = container.read(customerByIdProvider(first.id));
      expect(found?.name, first.name);
      expect(container.read(customerByIdProvider('no-such-id')), isNull);
    });
  });
}
