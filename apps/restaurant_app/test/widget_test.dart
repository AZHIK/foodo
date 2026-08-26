import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/models/cart.dart';
import 'package:restaurant_pos/models/menu_item.dart';
import 'package:restaurant_pos/providers/cart_provider.dart';
import 'package:restaurant_pos/providers/menu_providers.dart';
import 'package:restaurant_pos/main.dart';

const _burger = MenuItem(
  id: 'test-1',
  name: 'Test Burger',
  description: 'For tests',
  price: 10.00,
  categoryId: 'mains',
  emoji: '🍔',
);

void main() {
  group('Cart totals', () {
    test('subtotal, tax and total compose correctly', () {
      const cart = Cart(
        items: [CartItem(item: _burger, quantity: 3)],
        taxRate: 0.10,
      );

      expect(cart.itemCount, 3);
      expect(cart.subtotal, 30.00);
      expect(cart.tax, closeTo(3.00, 0.001));
      expect(cart.total, closeTo(33.00, 0.001));
    });

    test('discount applies before tax', () {
      const cart = Cart(
        items: [CartItem(item: _burger, quantity: 2)],
        taxRate: 0.10,
        discountRate: 0.50,
      );

      expect(cart.subtotal, 20.00);
      expect(cart.discount, 10.00);
      expect(cart.tax, closeTo(1.00, 0.001));
      expect(cart.total, closeTo(11.00, 0.001));
    });
  });

  group('CartNotifier', () {
    test('adding the same item merges into one line', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(cartProvider.notifier)
        ..add(_burger)
        ..add(_burger, quantity: 2);

      final cart = container.read(cartProvider);
      expect(cart.items, hasLength(1));
      expect(cart.quantityOf(_burger.id), 3);
    });

    test('decrementing to zero removes the line', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier)..add(_burger);
      notifier.decrement(_burger.id);

      expect(container.read(cartProvider).isEmpty, isTrue);
    });

    test('unavailable items are rejected', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(cartProvider.notifier)
          .add(_burger.copyWith(isAvailable: false));

      expect(container.read(cartProvider).isEmpty, isTrue);
    });
  });

  group('Menu filtering', () {
    test('search matches name and description', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(searchQueryProvider.notifier).state = 'risotto';
      final results = container.read(filteredMenuItemsProvider);

      expect(results, isNotEmpty);
      expect(
        results.every(
          (i) =>
              i.name.toLowerCase().contains('risotto') ||
              i.description.toLowerCase().contains('risotto'),
        ),
        isTrue,
      );
    });

    test('category filter narrows to one category', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedCategoryProvider.notifier).state = 'drinks';
      final results = container.read(filteredMenuItemsProvider);

      expect(results, isNotEmpty);
      expect(results.every((i) => i.categoryId == 'drinks'), isTrue);
    });
  });

  group('Shell navigation adapts to width', () {
    /// Drives the app at a fixed logical window size.
    Future<void> pumpAt(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size * tester.view.devicePixelRatio;
      tester.view.devicePixelRatio = tester.view.devicePixelRatio;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const ProviderScope(child: RestaurantPosApp()));
      await tester.pumpAndSettle();
    }

    testWidgets('phone width shows the bottom navigation bar', (tester) async {
      await pumpAt(tester, const Size(390, 844));

      expect(find.text('POS'), findsWidgets);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('tablet width hides nav behind a drawer', (tester) async {
      await pumpAt(tester, const Size(834, 1112));

      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(NavigationDrawer), findsNothing, reason: 'closed');
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold).first).drawer,
        isNotNull,
      );
    });

    testWidgets('desktop width shows the navigation rail', (tester) async {
      await pumpAt(tester, const Size(1440, 900));

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('no overflow at common breakpoints', (tester) async {
      for (final width in [360.0, 400.0, 768.0, 1024.0, 1440.0, 1920.0]) {
        await pumpAt(tester, Size(width, 800));
        expect(
          tester.takeException(),
          isNull,
          reason: 'overflow or error at ${width}px',
        );
      }
    });
  });
}
