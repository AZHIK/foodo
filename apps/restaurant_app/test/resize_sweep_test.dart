import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/main.dart';
import 'package:restaurant_pos/providers/cart_provider.dart';
import 'package:restaurant_pos/router/app_router.dart';
import 'package:restaurant_pos/widgets/pos/menu_item_card.dart';

/// Every route the sweep drags through. Detail routes use ids from the mock
/// data, so they render a real screen rather than the not-found state — which
/// would pass the sweep without ever laying the screen out.
const _sweptRoutes = <String>[
  '/pos',
  '/sales',
  '/inventory',
  '/inventory/inv-01',
  '/staff',
  '/staff/roles',
  '/staff/stf-01',
  '/dashboard',
  '/settings',
  '/settings/business-profile',
  '/settings/store-settings',
  '/settings/store-management',
  '/settings/app-preferences',
  '/insights',
];

/// Resizes a *live* app rather than pumping a fresh one per size, which is
/// what a user dragging a window edge actually does.
void main() {
  // ignore: unused_element
  Future<void> resizeTo(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size * tester.view.devicePixelRatio;
    await tester.pumpAndSettle();
  }

  testWidgets('dragging a window edge never throws', (tester) async {
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RestaurantPosApp(),
      ),
    );
    await tester.pumpAndSettle();

    for (final route in _sweptRoutes) {
      container.read(goRouterProvider).go(route);
      await tester.pumpAndSettle();

      // Shrink continuously, then grow back, the way a drag does.
      for (var width = 1600.0; width >= 240; width -= 40) {
        await resizeTo(tester, Size(width, 800));
        expect(
          tester.takeException(),
          isNull,
          reason: '$route broke while shrinking through ${width}px',
        );
      }
      for (var width = 240.0; width <= 1600; width += 40) {
        await resizeTo(tester, Size(width, 800));
        expect(
          tester.takeException(),
          isNull,
          reason: '$route broke while growing through ${width}px',
        );
      }
    }
  });

  testWidgets('crossing a breakpoint with the cart sheet open', (tester) async {
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    tester.view.physicalSize =
        const Size(390, 844) * tester.view.devicePixelRatio;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RestaurantPosApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The app lands on the dashboard, so walk to the till before ringing up.
    container.read(goRouterProvider).go(AppRoute.posPath);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(MenuItemCard).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('View cart'));
    await tester.pumpAndSettle();

    // Phone -> tablet -> desktop -> back, with the modal still mounted.
    for (final size in [
      const Size(768, 1024),
      const Size(1440, 900),
      const Size(390, 844),
    ]) {
      await resizeTo(tester, size);
      expect(tester.takeException(), isNull, reason: 'resized to $size');
    }

    expect(container.read(cartProvider).itemCount, 1);
  });

  testWidgets('crossing a breakpoint with the nav drawer open', (tester) async {
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    tester.view.physicalSize =
        const Size(768, 1024) * tester.view.devicePixelRatio;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RestaurantPosApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationDrawer), findsOneWidget);

    for (final size in [
      const Size(1440, 900),
      const Size(390, 844),
      const Size(768, 1024),
    ]) {
      await resizeTo(tester, size);
      expect(tester.takeException(), isNull, reason: 'resized to $size');
    }
  });

  testWidgets('shrinking height never throws', (tester) async {
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RestaurantPosApp(),
      ),
    );
    await tester.pumpAndSettle();

    for (final route in _sweptRoutes) {
      container.read(goRouterProvider).go(route);
      await tester.pumpAndSettle();

      for (var height = 900.0; height >= 200; height -= 40) {
        await resizeTo(tester, Size(1280, height));
        expect(
          tester.takeException(),
          isNull,
          reason: '$route broke at ${height}px tall',
        );
      }
    }
  });
}
