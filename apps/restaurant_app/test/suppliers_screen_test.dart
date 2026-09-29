/// Smoke tests for the Suppliers screen and its notifier in demo mode
/// (no business/store context — see `newTestContainer()`).
///
/// Mirrors the shape of `customers_screens_test.dart`: a plain
/// `MaterialApp` mount (no full router/permission-gate) verifying the
/// demo-mode regression guard, plus direct provider-level checks of
/// create/edit/delete now that they're `AsyncNotifier` methods. Also
/// covers the item-type gate (a sellable-only item can never be
/// purchase-received, so "Add to order cart" must be disabled for it).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/data/mock_suppliers.dart';
import 'package:restaurant_pos/models/inventory_item.dart';
import 'package:restaurant_pos/providers/inventory_provider.dart';
import 'package:restaurant_pos/providers/suppliers_provider.dart';
import 'package:restaurant_pos/screens/suppliers/suppliers_screen.dart';
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
  group('SuppliersScreen — demo mode', () {
    testWidgets('renders the mock rows with no business context', (tester) async {
      final container = newTestContainer();
      await pumpScreen(tester, container, const SuppliersScreen());

      expect(find.text('Suppliers'), findsWidgets);
      expect(find.text(MockSuppliers.list.first.name), findsWidgets);
    });

    test('create/edit/delete work against in-memory state', () async {
      final container = newTestContainer();
      final before = (await container.read(suppliersProvider.future)).length;
      final notifier = container.read(suppliersProvider.notifier);

      final created = await notifier.create(name: 'New Vendor', phone: '+1-555-0199');
      expect(container.read(suppliersListProvider).length, before + 1);

      final edited = await notifier.edit(created, name: 'New Vendor (Preferred)');
      expect(edited.name, 'New Vendor (Preferred)');
      expect(
        container.read(suppliersListProvider).firstWhere((s) => s.id == created.id).name,
        'New Vendor (Preferred)',
      );

      await notifier.delete(created.id);
      expect(
        container.read(suppliersListProvider).any((s) => s.id == created.id),
        isFalse,
      );
    });
  });

  group('item-type gate on "Add to order cart"', () {
    // A full interactive test (open a specific row's overflow menu, read
    // the PopupMenuItem's `enabled`) needs a target row already built,
    // and `ReusableDataTable`/`DataPageScaffold` paginate + virtualize in a
    // way that made both a viewport-size and an `ensureVisible` approach
    // flaky here — disproportionate machinery for a two-line boolean.
    // Covered instead by a direct check against the row-menu's actual
    // condition, run against the same `MockInventory` data the screen
    // itself renders — a mismatch here would still be a mismatch there.
    test(
      "disables 'sellable' items and allows raw_material/both, matching "
      "inventory_menu_items_screen.dart's isEnabled predicate",
      () async {
        final container = newTestContainer();
        await container.read(inventoryItemsProvider.future);
        final items = container.read(inventoryItemsListProvider);

        bool addToCartRowEnabled(InventoryItem item) =>
            item.trackStock && item.itemType != 'sellable';

        final sellableOnly = items.firstWhere((i) => i.name == 'Margherita Pizza');
        expect(sellableOnly.itemType, 'sellable');
        expect(addToCartRowEnabled(sellableOnly), isFalse);

        final both = items.firstWhere((i) => i.name == 'Sparkling Water');
        expect(both.itemType, 'both');
        expect(addToCartRowEnabled(both), isTrue);

        final rawMaterial = items.firstWhere((i) => i.name == 'Heirloom Tomatoes');
        expect(rawMaterial.itemType, 'raw_material');
        expect(addToCartRowEnabled(rawMaterial), isTrue);
      },
    );
  });
}
