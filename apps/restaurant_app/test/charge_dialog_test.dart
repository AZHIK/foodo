import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/main.dart';
import 'package:restaurant_pos/models/order.dart';
import 'package:restaurant_pos/providers/cart_provider.dart';
import 'package:restaurant_pos/providers/orders_provider.dart';
import 'package:restaurant_pos/providers/settings_provider.dart';
import 'package:restaurant_pos/router/app_router.dart';
import 'package:restaurant_pos/utils/formatters.dart';
import 'package:restaurant_pos/widgets/pos/charge_dialog.dart';
import 'package:restaurant_pos/widgets/pos/menu_item_card.dart';
import 'package:restaurant_pos/widgets/selectable_option_card.dart';

void main() {
  /// Pumps the POS screen at [size] with one item already rung up, and opens
  /// the take-payment dialog.
  Future<ProviderContainer> openDialog(WidgetTester tester, Size size) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = size * tester.view.devicePixelRatio;
    tester.view.devicePixelRatio = tester.view.devicePixelRatio;

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RestaurantPosApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The app lands on the dashboard now, so walk to the till first.
    container.read(goRouterProvider).go(AppRoute.posPath);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(MenuItemCard).first);
    await tester.pumpAndSettle();

    // Mobile keeps the ticket behind a sheet; desktop and tablet show it.
    if (find.text('View cart').evaluate().isNotEmpty) {
      await tester.tap(find.text('View cart'));
      await tester.pumpAndSettle();
    }

    // The narrowed tablet panel drops the amount from the label, so match the
    // verb rather than the formatted total.
    await tester.tap(find.textContaining('Charge').last);
    await tester.pumpAndSettle();

    expect(find.byType(ChargeDialog), findsOneWidget);
    return container;
  }

  /// The tender cards, excluding the order-type cards on the panel behind.
  Finder tenderCards() => find.descendant(
    of: find.byType(ChargeDialog),
    matching: find.byType(SelectableOptionCard),
  );

  /// The dialog's only filled button — "Charge $x.xx", whose label carries the
  /// live total and so cannot be matched by exact text.
  Finder chargeButton() => find.descendant(
    of: find.byType(ChargeDialog),
    matching: find.byType(FilledButton),
  );

  Finder tenderField() => find.descendant(
    of: find.byType(ChargeDialog),
    matching: find.byType(TextField),
  );

  testWidgets('desktop lays the tenders out three per row', (tester) async {
    await openDialog(tester, const Size(1440, 900));

    final cards = tenderCards();
    expect(cards, findsNWidgets(PaymentType.values.length));

    final rects = [
      for (var i = 0; i < PaymentType.values.length; i++)
        tester.getRect(cards.at(i)),
    ];

    // Three across, then the remainder wraps onto a second row.
    expect(rects[1].top, rects[0].top);
    expect(rects[2].top, rects[0].top);
    expect(rects[3].top, greaterThan(rects[0].top));

    // Equal widths — a tender is not more prominent for having a longer name.
    expect(rects[1].width, closeTo(rects[0].width, 1));
    expect(rects[2].width, closeTo(rects[0].width, 1));
  });

  testWidgets('the dialog is wider on desktop than on a phone', (tester) async {
    await openDialog(tester, const Size(1440, 900));
    final wide = tester.getSize(find.byType(AlertDialog)).width;

    await openDialog(tester, const Size(390, 844));
    final narrow = tester.getSize(find.byType(AlertDialog)).width;

    expect(wide, greaterThan(narrow));
    expect(wide, greaterThan(500));
  });

  testWidgets('tenders reflow two per row on a phone', (tester) async {
    await openDialog(tester, const Size(390, 844));

    final cards = tenderCards();
    final rects = [
      for (var i = 0; i < 3; i++) tester.getRect(cards.at(i)),
    ];

    expect(rects[1].top, rects[0].top);
    expect(rects[2].top, greaterThan(rects[0].top));
    // Still a comfortable touch target once narrowed.
    expect(rects[0].height, greaterThanOrEqualTo(44));
  });

  testWidgets('cash change is calculated as the amount is typed', (
    tester,
  ) async {
    final container = await openDialog(tester, const Size(1440, 900));
    final total = container.read(orderTotalsProvider).total;

    // Cash is the default tender, so the entry is already showing.
    expect(find.text('Change due'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);

    // Underpaying reports the shortfall and holds the charge button shut.
    await tester.enterText(tenderField(), '1.00');
    await tester.pumpAndSettle();
    expect(find.text('Still owing'), findsOneWidget);
    expect(tester.widget<FilledButton>(chargeButton()).onPressed, isNull);

    await tester.enterText(tenderField(), '100');
    await tester.pumpAndSettle();

    expect(find.text('Change due'), findsOneWidget);
    expect(container.read(changeDueProvider), closeTo(100 - total, 0.0001));
    expect(tester.widget<FilledButton>(chargeButton()).onPressed, isNotNull);
  });

  testWidgets('the Exact chip settles the ticket with no change', (
    tester,
  ) async {
    final container = await openDialog(tester, const Size(1440, 900));

    await tester.tap(find.text('Exact'));
    await tester.pumpAndSettle();

    expect(container.read(changeDueProvider), 0);
    expect(container.read(canConfirmPaymentProvider), isTrue);
  });

  // The quick amounts are a fixed three-across grid everywhere, so the note a
  // cashier reaches for sits in the same place on every screen.
  for (final size in const [Size(360, 640), Size(768, 1024), Size(1440, 900)]) {
    testWidgets('quick amounts are three per row at ${size.width.toInt()}px', (
      tester,
    ) async {
      final container = await openDialog(tester, size);
      final amounts = container.read(cashQuickAmountsProvider);

      final chips = [
        for (final amount in amounts)
          tester.getRect(find.text('+${Fmt.money(amount)}')),
        tester.getRect(find.text('Exact')),
      ];

      // First three share a row; the fourth starts the next one.
      expect(chips[1].top, chips[0].top);
      expect(chips[2].top, chips[0].top);
      expect(chips[3].top, greaterThan(chips[0].top));

      // Columns are equal and evenly spaced, not sized to their labels.
      final columns = [
        for (var i = 0; i < 3; i++)
          tester.getRect(
            find.ancestor(
              of: find.text('+${Fmt.money(amounts[i])}'),
              matching: find.byType(Material),
            ).first,
          ),
      ];
      expect(columns[1].width, closeTo(columns[0].width, 1));
      expect(columns[2].width, closeTo(columns[0].width, 1));
      expect(columns[0].height, greaterThanOrEqualTo(44));
    });
  }

  testWidgets('a quick-amount chip adds to what is already tendered', (
    tester,
  ) async {
    final container = await openDialog(tester, const Size(1440, 900));

    await tester.tap(find.text('+\$20.00'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+\$5.00'));
    await tester.pumpAndSettle();

    expect(container.read(paymentDetailsProvider).amountTendered, 25);
    // The chips write through to the field the cashier is looking at.
    expect(find.text('25.00'), findsOneWidget);
  });

  testWidgets('a card tender asks for no amount and charges straight away', (
    tester,
  ) async {
    final container = await openDialog(tester, const Size(1440, 900));

    await tester.tap(find.text('QRIS'));
    await tester.pumpAndSettle();

    expect(find.text('Change due'), findsNothing);
    expect(tester.widget<FilledButton>(chargeButton()).onPressed, isNotNull);

    await tester.tap(chargeButton());
    await tester.pumpAndSettle();

    final order = container.read(ordersProvider).first;
    expect(order.paymentType, PaymentType.qris);
    expect(order.amountTendered, isNull);
    // Ticket reset for the next customer.
    expect(container.read(cartProvider).isEmpty, isTrue);
  });

  testWidgets('charging cash records the tender on the sale', (tester) async {
    final container = await openDialog(tester, const Size(1440, 900));

    await tester.enterText(tenderField(), '100');
    await tester.pumpAndSettle();
    await tester.tap(chargeButton());
    await tester.pumpAndSettle();

    final order = container.read(ordersProvider).first;
    expect(order.paymentType, PaymentType.cash);
    expect(order.amountTendered, 100);
    expect(container.read(cartProvider).isEmpty, isTrue);
  });

  testWidgets('cancelling leaves no tender behind on the ticket', (
    tester,
  ) async {
    final container = await openDialog(tester, const Size(1440, 900));

    await tester.enterText(tenderField(), '100');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(container.read(paymentDetailsProvider).amountTendered, isNull);
    // The order itself survives — cancelling payment is not cancelling lunch.
    expect(container.read(cartProvider).isNotEmpty, isTrue);
  });

  // One test per size rather than a loop: a loop that re-pumps the app into
  // the same element tree inherits the previous size's open routes, and a
  // failure names no size when it does go wrong.
  for (final size in const [
    Size(360, 640),
    Size(400, 800),
    Size(768, 1024),
    Size(1024, 768),
    Size(1440, 900),
    Size(1920, 1080),
  ]) {
    testWidgets('no overflow at ${size.width.toInt()}px', (tester) async {
      await openDialog(tester, size);
      expect(tester.takeException(), isNull, reason: 'dialog opened at $size');

      // The cash entry is the dialog's tallest state.
      expect(tenderField(), findsOneWidget);
      await tester.enterText(tenderField(), '100');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'cash entry at $size');

      expect(find.text('Change due'), findsOneWidget);
    });
  }
}
