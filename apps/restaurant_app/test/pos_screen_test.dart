import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/main.dart';
import 'package:restaurant_pos/providers/cart_provider.dart';
import 'package:restaurant_pos/router/app_router.dart';
import 'package:restaurant_pos/widgets/pos/cart_bottom_sheet.dart';
import 'package:restaurant_pos/widgets/pos/menu_item_card.dart';
import 'package:restaurant_pos/widgets/pos/order_summary_panel.dart';

/// Every width the brief calls out, plus the two breakpoint edges themselves.
const _widths = <double>[360, 400, 599, 600, 768, 1023, 1024, 1280, 1440, 1920];

Future<ProviderContainer> pumpPos(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
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

  // The app now lands on the dashboard, so a POS test has to walk to the till
  // rather than assume it is already there.
  container.read(goRouterProvider).go(AppRoute.posPath);
  await tester.pumpAndSettle();
  return container;
}

int columnsOf(WidgetTester tester) {
  final grid = tester.widget<GridView>(find.byType(GridView));
  final delegate =
      grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
  return delegate.crossAxisCount;
}

void main() {
  group('POS layout', () {
    testWidgets('no overflow at any target width', (tester) async {
      for (final width in _widths) {
        await pumpPos(tester, Size(width, 800));
        expect(
          tester.takeException(),
          isNull,
          reason: 'render error at ${width}px',
        );
        expect(find.byType(GridView), findsOneWidget, reason: '${width}px');
      }
    });

    testWidgets('no overflow at a short landscape phone', (tester) async {
      // The cruellest case: sticky cart bar and grid on 360px of height.
      await pumpPos(tester, const Size(740, 360));
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow on a short desktop terminal', (tester) async {
      // A 320px-tall window still has to fit the ticket panel's header,
      // lines and checkout footer.
      await pumpPos(tester, const Size(1280, 320));
      expect(tester.takeException(), isNull);
      expect(find.byType(OrderSummaryPanel), findsOneWidget);
    });

    testWidgets('the keyboard never covers checkout', (tester) async {
      const keyboard = 320.0;
      final container = await pumpPos(tester, const Size(390, 844));

      await tester.tap(find.byType(MenuItemCard).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('View cart'));
      await tester.pumpAndSettle();

      // Raise the keyboard behind the open sheet.
      tester.view.viewInsets = FakeViewPadding(
        bottom: keyboard * tester.view.devicePixelRatio,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final charge = tester.getRect(find.textContaining('Charge \$'));
      expect(
        charge.bottom,
        lessThanOrEqualTo(844 - keyboard),
        reason: 'the Charge button sits behind the keyboard',
      );
      expect(container.read(cartProvider).itemCount, 1);
    });

    testWidgets('mobile hides the panel and shows the sticky bar', (
      tester,
    ) async {
      await pumpPos(tester, const Size(390, 844));

      expect(find.byType(OrderSummaryPanel), findsNothing);
      expect(find.byType(CartSummaryBar), findsOneWidget);
      expect(columnsOf(tester), 2);
    });

    testWidgets('tablet keeps a narrowed panel beside the grid', (
      tester,
    ) async {
      await pumpPos(tester, const Size(768, 1024));

      expect(find.byType(OrderSummaryPanel), findsOneWidget);
      expect(find.byType(CartSummaryBar), findsNothing);
      expect(
        tester.widget<OrderSummaryPanel>(find.byType(OrderSummaryPanel)).width,
        inInclusiveRange(200, 220),
      );
      expect(columnsOf(tester), 3);
    });

    testWidgets('desktop widens the panel', (tester) async {
      await pumpPos(tester, const Size(1440, 900));

      expect(
        tester.widget<OrderSummaryPanel>(find.byType(OrderSummaryPanel)).width,
        320,
      );
    });

    testWidgets('desktop is a four-up grid at every width', (tester) async {
      for (final width in [1024.0, 1280.0, 1366.0, 1440.0, 1680.0, 1920.0]) {
        await pumpPos(tester, Size(width, 900));
        expect(columnsOf(tester), 4, reason: '${width}px');
        expect(tester.takeException(), isNull, reason: '${width}px');
      }
    });

    // Widening a window must never cost you a column *within* one layout.
    // Across a breakpoint it can: at 1024 the rail and the wider ticket panel
    // appear together and buy that space back from the grid, which is the
    // trade the desktop layout is meant to make.
    testWidgets('columns never shrink as a layout widens', (tester) async {
      for (final widths in [
        <double>[360, 400, 480, 599],
        <double>[600, 700, 768, 900, 1023],
        <double>[1024, 1280, 1440, 1680, 1920],
      ]) {
        var previous = 0;
        for (final width in widths) {
          await pumpPos(tester, Size(width, 900));
          final columns = columnsOf(tester);
          expect(
            columns,
            greaterThanOrEqualTo(previous),
            reason: '${width}px narrowed the grid to $columns columns',
          );
          previous = columns;
        }
      }
    });
  });

  group('POS interaction', () {
    testWidgets('tapping a card adds it to the open order', (tester) async {
      final container = await pumpPos(tester, const Size(1440, 900));

      await tester.tap(find.byType(MenuItemCard).first);
      await tester.pumpAndSettle();

      expect(container.read(cartProvider).itemCount, 1);
      // The line, its total and the ticket total all land in the panel.
      expect(find.textContaining('Charge \$'), findsOneWidget);
    });

    testWidgets('stepper raises and clears the line', (tester) async {
      final container = await pumpPos(tester, const Size(1440, 900));

      await tester.tap(find.byType(MenuItemCard).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_rounded).first);
      await tester.pumpAndSettle();
      expect(container.read(cartProvider).itemCount, 2);

      await tester.tap(find.byIcon(Icons.remove_rounded).first);
      await tester.pumpAndSettle();
      expect(container.read(cartProvider).itemCount, 1);

      // At one, the minus becomes an explicit delete.
      await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
      await tester.pumpAndSettle();
      expect(container.read(cartProvider).isEmpty, isTrue);
    });

    testWidgets('mobile cart sheet opens with the same ticket', (tester) async {
      final container = await pumpPos(tester, const Size(390, 844));

      await tester.tap(find.byType(MenuItemCard).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('View cart'));
      await tester.pumpAndSettle();

      expect(find.byType(CartBottomSheet), findsOneWidget);
      expect(find.byType(CartLinesSliver), findsOneWidget);
      expect(container.read(cartProvider).itemCount, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('search narrows the grid and offers a reset', (tester) async {
      await pumpPos(tester, const Size(1440, 900));

      final before = tester.widgetList(find.byType(MenuItemCard)).length;
      await tester.enterText(find.byType(TextField).first, 'zzzznothing');
      await tester.pumpAndSettle();

      expect(find.byType(MenuItemCard), findsNothing);
      expect(find.text('No matches'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(tester.widgetList(find.byType(MenuItemCard)).length, before);
    });
  });
}
