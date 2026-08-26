import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/main.dart';
import 'package:restaurant_pos/models/order.dart';
import 'package:restaurant_pos/providers/orders_provider.dart';
import 'package:restaurant_pos/router/app_router.dart';
import 'package:restaurant_pos/widgets/data_page/data_column_spec.dart';
import 'package:restaurant_pos/widgets/data_page/data_row_card.dart';
import 'package:restaurant_pos/widgets/data_page/summary_metric_card.dart';

const _widths = <double>[360, 400, 768, 1024, 1440, 1920];

Future<ProviderContainer> pumpSales(WidgetTester tester, Size size) async {
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

  container.read(goRouterProvider).go('/sales');
  await tester.pumpAndSettle();
  return container;
}

/// The page is one ListView, so the table and its footer are not built until
/// scrolled into view.
Future<void> scrollDown(WidgetTester tester, [double by = 500]) async {
  await tester.drag(find.byType(ListView), Offset(0, -by));
  await tester.pumpAndSettle();
}

void main() {
  group('Sales filters', () {
    ProviderContainer container() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c;
    }

    test('date windows widen from today to all time', () {
      final c = container();
      final notifier = c.read(salesFiltersProvider.notifier);

      notifier.setRange(SalesDateRange.today);
      final today = c.read(filteredOrdersProvider).length;

      notifier.setRange(SalesDateRange.week);
      final week = c.read(filteredOrdersProvider).length;

      notifier.setRange(SalesDateRange.month);
      final month = c.read(filteredOrdersProvider).length;

      notifier.setRange(SalesDateRange.all);
      final all = c.read(filteredOrdersProvider).length;

      expect(today, greaterThan(0));
      expect(week, greaterThanOrEqualTo(today));
      expect(month, greaterThanOrEqualTo(week));
      expect(all, greaterThan(month));
    });

    test('a custom range includes both end days', () {
      final c = container();
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day - 3);

      c.read(salesFiltersProvider.notifier).setCustomRange(
        DateTimeRange(start: start, end: DateTime(now.year, now.month, now.day)),
      );

      final rows = c.read(filteredOrdersProvider);
      expect(rows, isNotEmpty);
      expect(rows.every((o) => !o.placedAt.isBefore(start)), isTrue);
      // Orders placed later today must still be inside the window.
      expect(rows.any((o) => o.placedAt.day == now.day), isTrue);
    });

    test('payment and status multi-selects compose', () {
      final c = container();
      final notifier = c.read(salesFiltersProvider.notifier);
      notifier.setRange(SalesDateRange.all);
      notifier.togglePayment(PaymentType.card);
      notifier.toggleStatus(OrderStatus.paid);

      final rows = c.read(filteredOrdersProvider);
      expect(rows, isNotEmpty);
      expect(
        rows.every(
          (o) =>
              o.paymentType == PaymentType.card &&
              o.status == OrderStatus.paid,
        ),
        isTrue,
      );
      expect(c.read(salesFiltersProvider).activeCount, 2);
    });

    test('clearing keeps the date window the user chose', () {
      final c = container();
      final notifier = c.read(salesFiltersProvider.notifier);
      notifier.setRange(SalesDateRange.month);
      notifier.togglePayment(PaymentType.cash);

      notifier.clear();

      expect(c.read(salesFiltersProvider).range, SalesDateRange.month);
      expect(c.read(salesFiltersProvider).activeCount, 0);
    });

    test('changing a filter returns to page one', () {
      final c = container();
      c.read(salesQueryProvider.notifier).setPage(2);
      c.read(salesFiltersProvider.notifier).toggleStatus(OrderStatus.paid);
      expect(c.read(salesQueryProvider).page, 0);
    });

    test('summary describes exactly what the table shows', () {
      final c = container();
      c.read(salesFiltersProvider.notifier).setRange(SalesDateRange.all);

      final rows = c.read(filteredOrdersProvider);
      final summary = c.read(salesSummaryProvider);

      expect(summary.orderCount, rows.length);
      expect(
        summary.revenue,
        closeTo(rows.fold(0.0, (sum, o) => sum + o.netRevenue), 0.001),
      );

      // Refunded and voided tickets contribute nothing to takings.
      c.read(salesFiltersProvider.notifier).toggleStatus(OrderStatus.refunded);
      expect(c.read(salesSummaryProvider).revenue, 0);
    });

    test('sorting by total then flipping direction', () {
      final c = container();
      c.read(salesFiltersProvider.notifier).setRange(SalesDateRange.all);
      c.read(salesQueryProvider.notifier).setSort(
        SalesSort.total,
        ascending: true,
      );

      final up = c.read(filteredOrdersProvider).map((o) => o.total).toList();
      expect(up.first, lessThanOrEqualTo(up.last));

      c.read(salesQueryProvider.notifier).toggleSort(SalesSort.total);
      final down = c.read(filteredOrdersProvider).map((o) => o.total).toList();
      expect(down.first, greaterThanOrEqualTo(down.last));
    });

    test('search matches id, server, payment and line items', () {
      final c = container();
      c.read(salesFiltersProvider.notifier).setRange(SalesDateRange.all);
      final target = c.read(ordersProvider).first;

      c.read(salesQueryProvider.notifier).setSearch(target.id);
      expect(c.read(filteredOrdersProvider).single.id, target.id);

      c.read(salesQueryProvider.notifier).setSearch('gift');
      final byPayment = c.read(filteredOrdersProvider);
      expect(byPayment, isNotEmpty);
      expect(
        byPayment.every((o) => o.paymentType == PaymentType.giftCard),
        isTrue,
      );
    });
  });

  group('Sales screen', () {
    testWidgets('no overflow at any target width', (tester) async {
      for (final width in _widths) {
        await pumpSales(tester, Size(width, 900));
        expect(
          tester.takeException(),
          isNull,
          reason: 'render error at ${width}px',
        );
        expect(find.byType(SummaryMetricCard), findsNWidgets(3));
      }
    });

    testWidgets('mobile degrades the table to cards', (tester) async {
      await pumpSales(tester, const Size(390, 844));
      await scrollDown(tester);

      expect(find.byType(DataRowCard<Order>), findsWidgets);
    });

    testWidgets('desktop shows the table with all columns', (tester) async {
      await pumpSales(tester, const Size(1440, 900));

      expect(find.byType(DataRowCard<Order>), findsNothing);
      expect(find.text('ORDER'), findsOneWidget);
      expect(find.text('DATE & TIME'), findsOneWidget);
      expect(find.text('ITEMS'), findsOneWidget);
      expect(find.text('TOTAL'), findsOneWidget);
      expect(find.text('PAYMENT'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
    });

    testWidgets('narrow tables drop columns rather than scrolling', (
      tester,
    ) async {
      await pumpSales(tester, const Size(700, 900));
      expect(find.text('ORDER'), findsOneWidget);
      expect(find.text('PAYMENT'), findsNothing);
    });

    testWidgets('the period selector changes the range', (tester) async {
      final container = await pumpSales(tester, const Size(1440, 900));
      expect(find.text('Today'), findsWidgets);

      await tester.tap(find.byTooltip('Change period'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('This month'));
      await tester.tap(find.text('This month'));
      await tester.pumpAndSettle();

      expect(container.read(salesFiltersProvider).range, SalesDateRange.month);
      expect(tester.takeException(), isNull);
    });

    testWidgets('filter panel applies a status filter', (tester) async {
      final container = await pumpSales(tester, const Size(1440, 900));

      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Refunded'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await tester.pumpAndSettle();

      final rows = container.read(filteredOrdersProvider);
      expect(rows.every((o) => o.status == OrderStatus.refunded), isTrue);
      expect(container.read(salesFiltersProvider).activeCount, 1);
    });

    testWidgets('tapping a row opens the order detail route', (tester) async {
      final container = await pumpSales(tester, const Size(1440, 900));
      final first = container.read(salesSliceProvider).items.first;

      await tester.tap(find.text(first.id));
      await tester.pumpAndSettle();

      expect(find.text('Print receipt'), findsOneWidget);
      expect(find.text('PAYMENT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a mobile card opens the same detail route', (tester) async {
      final container = await pumpSales(tester, const Size(390, 844));
      await scrollDown(tester);
      final first = container.read(salesSliceProvider).items.first;

      await tester.tap(find.byType(DataRowCard<Order>).first);
      await tester.pumpAndSettle();

      expect(find.text(first.id), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('row action refunds after confirmation', (tester) async {
      final container = await pumpSales(tester, const Size(1440, 900));
      container.read(salesFiltersProvider.notifier).toggleStatus(
        OrderStatus.paid,
      );
      await tester.pumpAndSettle();
      final target = container.read(salesSliceProvider).items.first;

      await tester.tap(find.byTooltip('Row actions').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Refund order'));
      await tester.pumpAndSettle();

      expect(find.text('Refund ${target.id}?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Refund'));
      await tester.pumpAndSettle();

      expect(
        container.read(orderByIdProvider(target.id))!.status,
        OrderStatus.refunded,
      );
    });

    testWidgets('refund is disabled for an already-refunded order', (
      tester,
    ) async {
      final container = await pumpSales(tester, const Size(1440, 900));
      container.read(salesFiltersProvider.notifier)
        ..setRange(SalesDateRange.all)
        ..toggleStatus(OrderStatus.refunded);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Row actions').first);
      await tester.pumpAndSettle();

      final item = tester.widget<PopupMenuItem<DataRowAction<Order>>>(
        find
            .ancestor(
              of: find.text('Refund order'),
              matching: find.byType(PopupMenuItem<DataRowAction<Order>>),
            )
            .first,
      );
      expect(item.enabled, isFalse);
    });

    testWidgets('header sort and pagination work together', (tester) async {
      final container = await pumpSales(tester, const Size(1440, 900));
      container.read(salesFiltersProvider.notifier).setRange(
        SalesDateRange.all,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('TOTAL'));
      await tester.pumpAndSettle();
      expect(container.read(salesQueryProvider).sortField, SalesSort.total);

      await scrollDown(tester);
      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();

      expect(container.read(salesQueryProvider).page, 1);
      expect(container.read(salesSliceProvider).firstRow, 9);
    });
  });
}
