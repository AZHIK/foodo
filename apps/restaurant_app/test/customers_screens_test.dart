/// Smoke tests for the Customers list/detail screens and `CustomersNotifier`
/// with no business context (see `newTestContainer()`).
///
/// With no context the list is empty and mutations are refused — the screens
/// render their empty state instead of sample data.
///
/// Mirrors the shape of `finance_screens_test.dart`: a plain `MaterialApp`
/// mount (no full router/permission-gate — those are exercised in
/// `charge_dialog_test.dart` for the checkout picker, and the gated screen
/// wrappers themselves have no logic of their own beyond what
/// `PermissionGatedScreen` already covers).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
  group('CustomersScreen — no business context', () {
    testWidgets('renders with an empty list', (tester) async {
      final container = newTestContainer();
      await pumpScreen(tester, container, const CustomersScreen());

      expect(find.text('Customers'), findsWidgets);
      expect(container.read(customersListProvider), isEmpty);
    });

    test('mutations require a business context', () async {
      final container = newTestContainer();
      // AsyncNotifier.build() always resolves via a microtask, even when
      // its body has no real `await` — wait for the initial empty load
      // before asserting, or the read below sees an AsyncLoading.
      await container.read(customersProvider.future);
      final notifier = container.read(customersProvider.notifier);

      await expectLater(
        notifier.create(name: 'New Walk-in', phone: '+1-555-0199'),
        throwsStateError,
      );
      await expectLater(
        notifier.delete('no-such-id'),
        throwsStateError,
      );
    });

    test('customerByIdProvider returns null for unknown ids', () async {
      final container = newTestContainer();
      await container.read(customersProvider.future);

      expect(container.read(customerByIdProvider('no-such-id')), isNull);
    });
  });
}
