import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/models/dashboard_chart_data.dart';
import 'package:restaurant_pos/theme/app_theme.dart';
import 'package:restaurant_pos/theme/dashboard_colors.dart';
import 'package:restaurant_pos/widgets/dashboard/category_donut_chart.dart';
import 'package:restaurant_pos/widgets/dashboard/revenue_trend_chart.dart';

/// Renders the two dashboard charts in isolation, so their design can be
/// reviewed as an image rather than read as code.
///
/// Run with `flutter test --update-goldens test/dashboard_charts_golden_test.dart`
/// to regenerate `test/goldens/*.png`.
void main() {
  setUpAll(() async {
    // Without this the golden renders in the test font, where every glyph is
    // an identical box — useless for judging a design.
    final loader = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await loader.load();
  });

  final revenue = <RevenuePoint>[
    RevenuePoint(day: DateTime(2026, 8, 7), amount: 1840.50),
    RevenuePoint(day: DateTime(2026, 8, 8), amount: 2310.00),
    RevenuePoint(day: DateTime(2026, 8, 9), amount: 1960.75),
    RevenuePoint(day: DateTime(2026, 8, 10), amount: 2580.20),
    RevenuePoint(day: DateTime(2026, 8, 11), amount: 2240.00),
    RevenuePoint(day: DateTime(2026, 8, 12), amount: 3120.40),
    RevenuePoint(day: DateTime(2026, 8, 13), amount: 3480.90),
  ];

  // Colour indices are explicit: a slice paints from its own index, not its
  // position in this list, so omitting them would render five teal slices.
  const categories = <CategorySlice>[
    CategorySlice(label: 'Mains', value: 4820, colorIndex: 0),
    CategorySlice(label: 'Drinks', value: 2960, colorIndex: 1),
    CategorySlice(label: 'Starters', value: 1740, colorIndex: 2),
    CategorySlice(label: 'Desserts', value: 1180, colorIndex: 3),
    CategorySlice(label: 'Sides', value: 640, colorIndex: 4),
  ];

  Widget harness({
    required Brightness brightness,
    required Widget child,
    required double width,
  }) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    );
  }

  /// The card chrome the charts will sit in on the real dashboard, so the
  /// golden shows them in their intended context.
  Widget card({required String title, required Widget child}) {
    return Builder(
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: DashboardStyle.cardPadding,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: DashboardStyle.radius,
          boxShadow: DashboardStyle.shadow(Theme.of(context).brightness),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Future<void> pumpAt(
    WidgetTester tester,
    Widget app,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app);
    // Charts animate in; settle so the golden captures the finished state.
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  testWidgets('revenue trend — light', (tester) async {
    await pumpAt(
      tester,
      harness(
        brightness: Brightness.light,
        width: 720,
        child: card(
          title: 'Revenue, last 7 days',
          child: RevenueTrendChart(points: revenue),
        ),
      ),
      const Size(760, 400),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/revenue_trend_light.png'),
    );
  });

  testWidgets('revenue trend — dark', (tester) async {
    await pumpAt(
      tester,
      harness(
        brightness: Brightness.dark,
        width: 720,
        child: card(
          title: 'Revenue, last 7 days',
          child: RevenueTrendChart(points: revenue),
        ),
      ),
      const Size(760, 400),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/revenue_trend_dark.png'),
    );
  });

  testWidgets('category donut — light', (tester) async {
    await pumpAt(
      tester,
      harness(
        brightness: Brightness.light,
        width: 400,
        child: card(
          title: 'Sales by category',
          child: const CategoryDonutChart(slices: categories),
        ),
      ),
      const Size(440, 560),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/category_donut_light.png'),
    );
  });

  testWidgets('category donut — dark', (tester) async {
    await pumpAt(
      tester,
      harness(
        brightness: Brightness.dark,
        width: 400,
        child: card(
          title: 'Sales by category',
          child: const CategoryDonutChart(slices: categories),
        ),
      ),
      const Size(440, 560),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/category_donut_dark.png'),
    );
  });

  testWidgets('narrow column — both charts at 360px', (tester) async {
    await pumpAt(
      tester,
      harness(
        brightness: Brightness.light,
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            card(
              title: 'Revenue, last 7 days',
              child: RevenueTrendChart(
                points: revenue,
                height: DashboardStyle.chartHeightMobile,
              ),
            ),
            card(
              title: 'Sales by category',
              child: const CategoryDonutChart(
                slices: categories,
                height: DashboardStyle.chartHeightMobile,
              ),
            ),
          ],
        ),
      ),
      const Size(360, 820),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/charts_mobile_360.png'),
    );
  });
}
