import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/dashboard_metrics_provider.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/dashboard/insight_highlights.dart';
import '../../widgets/dashboard/low_stock_alert_banner.dart';
import 'dashboard_widgets.dart';

/// The dashboard as a phone experience, not a shrunk desktop page.
///
/// Differences from the desktop view are deliberate, not just narrower:
/// * every section is present — insights, charts, top items and activity all
///   scroll in one column instead of two of them being hidden;
/// * the five KPIs sit in a 2x2 grid with net profit as a full-width hero,
///   so no metric is dropped to save space;
/// * pull-to-refresh recomputes the numbers, the gesture phone users expect
///   on any glanceable screen.
class DashboardMobileScreen extends ConsumerWidget {
  const DashboardMobileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardMetricsProvider);
    final activity = ref.watch(dashboardActivityProvider);
    const spacing = Insets.lg;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => refreshDashboard(ref),
          child: ListView(
            // Always scrollable so the pull gesture works even when the
            // content fits without scrolling.
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              Insets.md,
              Insets.lg,
              Insets.xxl,
            ),
            children: [
              const DashboardGreetingHeader(),
              if (metrics.hasLowStock) ...[
                const SizedBox(height: Insets.md),
                LowStockAlertBanner(
                  items: metrics.lowStockItems,
                  onTap: () => openDashboardLowStock(context, ref),
                ),
              ],
              const SizedBox(height: spacing),
              _MobileKpiGrid(metrics: metrics),
              const SizedBox(height: spacing),
              // Under the KPIs rather than above them: the numbers are what
              // the owner came for, and the assistant's reading of those
              // numbers is what they look at next.
              const InsightHighlights(),
              const SizedBox(height: spacing),
              DashboardChartsRow(metrics: metrics),
              const SizedBox(height: spacing),
              DashboardSecondaryRow(
                metrics: metrics,
                activity: activity.take(dashboardListLimit + 1).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The five KPIs as a 2x2 grid with net profit full-width beneath.
///
/// Four across is a desktop density; one stacked column buries the charts a
/// full screen down. Two columns fit a phone's width with readable cards,
/// and profit — the number an owner checks before anything else — gets the
/// full row to itself instead of rattling around as the odd fifth card.
class _MobileKpiGrid extends StatelessWidget {
  const _MobileKpiGrid({required this.metrics});

  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final cards = buildDashboardKpiCards(context, metrics);

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = Insets.sm;
        final half = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards.take(4))
              SizedBox(width: half, child: card),
            SizedBox(width: constraints.maxWidth, child: cards[4]),
          ],
        );
      },
    );
  }
}
