import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/dashboard_metrics_provider.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/dashboard/insight_highlights.dart';
import '../../widgets/dashboard/low_stock_alert_banner.dart';
import 'dashboard_widgets.dart';

/// The dashboard as a desktop and tablet experience.
///
/// Tablet (600–1024px) renders here too: the KPI row, charts row and
/// secondary row each reflow through their own [LayoutBuilder] thresholds,
/// so mid widths pair and stack panels without needing a third layout.
class DashboardDesktopScreen extends ConsumerWidget {
  const DashboardDesktopScreen({super.key});

  /// Four KPI cards across needs this much; below it they pair up two-by-two.
  static const double _fourAcross = 900;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardMetricsProvider);
    final activity = ref.watch(dashboardActivityProvider);
    final pad = Insets.page(context.formFactor);
    const spacing = Insets.lg;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => refreshDashboard(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(pad, Insets.lg, pad, pad),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: Breakpoints.maxContentWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const DashboardGreetingHeader(),
                      if (metrics.hasLowStock) ...[
                        const SizedBox(height: spacing),
                        LowStockAlertBanner(
                          items: metrics.lowStockItems,
                          onTap: () => openDashboardLowStock(context, ref),
                        ),
                      ],
                      const SizedBox(height: Insets.xl),
                      _DesktopKpiRow(metrics: metrics),
                      const SizedBox(height: spacing),
                      // Under the KPIs rather than above them: the numbers are
                      // what the owner came for, and the assistant's reading of
                      // those numbers is what they look at next.
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
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopKpiRow extends StatelessWidget {
  const _DesktopKpiRow({required this.metrics});

  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final cards = buildDashboardKpiCards(context, metrics);

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = Insets.md;
        final columns = constraints.maxWidth >=
                DashboardDesktopScreen._fourAcross
            ? 3
            : 2;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }
}
