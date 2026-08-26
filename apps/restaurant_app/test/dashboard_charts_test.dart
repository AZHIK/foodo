import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/models/dashboard_chart_data.dart';
import 'package:restaurant_pos/theme/app_theme.dart';
import 'package:restaurant_pos/widgets/dashboard/category_donut_chart.dart';
import 'package:restaurant_pos/widgets/dashboard/revenue_trend_chart.dart';

const _widths = <double>[360, 400, 768, 1024, 1440, 1920];

final _revenue = <RevenuePoint>[
  for (var i = 0; i < 7; i++)
    RevenuePoint(
      day: DateTime(2026, 8, 7 + i),
      amount: 1800 + i * 240 + (i.isEven ? 320 : 0),
    ),
];

const _categories = <CategorySlice>[
  CategorySlice(label: 'Mains', value: 4820, colorIndex: 0),
  CategorySlice(label: 'Drinks', value: 2960, colorIndex: 1),
  CategorySlice(label: 'Starters', value: 1740, colorIndex: 2),
  CategorySlice(label: 'Desserts', value: 1180, colorIndex: 3),
  CategorySlice(label: 'Sides', value: 640, colorIndex: 4),
];

Future<void> pumpChart(
  WidgetTester tester,
  Widget chart,
  double width, {
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = Size(width, 900) * tester.view.devicePixelRatio;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
      home: Scaffold(
        // Padding stands in for the card the chart will really sit in, so the
        // available width matches the production case.
        body: Padding(padding: const EdgeInsets.all(20), child: chart),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('RevenueTrendChart', () {
    testWidgets('no overflow at any target width', (tester) async {
      for (final width in _widths) {
        await pumpChart(tester, RevenueTrendChart(points: _revenue), width);
        expect(
          tester.takeException(),
          isNull,
          reason: 'revenue chart broke at ${width}px',
        );
        expect(find.byType(LineChart), findsOneWidget);
      }
    });

    testWidgets('drops the Y axis on a narrow card', (tester) async {
      // Wide: the money gutter is worth its width.
      await pumpChart(tester, RevenueTrendChart(points: _revenue), 900);
      expect(find.textContaining(r'$'), findsWidgets);

      // Narrow: gridlines carry the scale instead.
      await pumpChart(tester, RevenueTrendChart(points: _revenue), 320);
      expect(find.textContaining(r'$'), findsNothing);
    });

    testWidgets('axis labels are compact — never clipped cents', (
      tester,
    ) async {
      await pumpChart(tester, RevenueTrendChart(points: _revenue), 900);

      // "$5,500.00" is what a full money format would render into a 46px
      // gutter, and it clips. The axis uses magnitudes instead.
      expect(find.textContaining('.00'), findsNothing);
      expect(find.textContaining('k'), findsWidgets);
    });

    testWidgets('an empty series says so rather than drawing an empty grid', (
      tester,
    ) async {
      await pumpChart(tester, const RevenueTrendChart(points: []), 900);
      expect(find.text('No sales in this period'), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });
  });

  group('CategoryDonutChart', () {
    testWidgets('no overflow at any target width', (tester) async {
      for (final width in _widths) {
        await pumpChart(
          tester,
          const CategoryDonutChart(slices: _categories),
          width,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'donut broke at ${width}px',
        );
        expect(find.byType(PieChart), findsOneWidget);
      }
    });

    testWidgets('no overflow in dark mode either', (tester) async {
      for (final width in _widths) {
        await pumpChart(
          tester,
          const CategoryDonutChart(slices: _categories),
          width,
          brightness: Brightness.dark,
        );
        expect(tester.takeException(), isNull, reason: 'dark $width');
      }
    });

    testWidgets('the custom legend names every category once', (tester) async {
      await pumpChart(
        tester,
        const CategoryDonutChart(slices: _categories),
        900,
      );

      for (final slice in _categories) {
        expect(find.text(slice.label), findsOneWidget);
      }
    });

    testWidgets('legend percentages are derived from the same total', (
      tester,
    ) async {
      await pumpChart(
        tester,
        const CategoryDonutChart(slices: _categories),
        900,
      );

      // 4820 / 11340 = 42.5% → 43%.
      expect(find.text('43%'), findsWidgets);
      // The smallest slice still gets a legend row even though it is too thin
      // to carry a label inside the ring.
      expect(find.text('6%'), findsOneWidget);
    });

    testWidgets('an empty breakdown cannot divide by zero', (tester) async {
      await pumpChart(tester, const CategoryDonutChart(slices: []), 900);

      expect(find.text('No sales to break down yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
