import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/dashboard_metrics_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../theme/dashboard_colors.dart';
import '../../widgets/dashboard/insight_highlights.dart';
import '../../widgets/dashboard/low_stock_alert_banner.dart';
import 'dashboard_widgets.dart';

/// The dashboard as a phone experience, not a shrunk desktop page.
///
/// Mobile-first decisions:
/// * one scrolling column with clear section rhythm (greeting → actions →
///   KPIs → assistant picks → trends → lists), so the thumb never hunts;
/// * quick-action tiles for the four things a shift starts with;
/// * 2-up KPI grid with net profit as a full-width gradient hero;
/// * insights as a horizontal snap carousel instead of three stacked cards
///   that would bury the charts a screen down;
/// * pull-to-refresh, the gesture phone users expect on a glanceable screen.
class DashboardMobileScreen extends ConsumerWidget {
  const DashboardMobileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardMetricsProvider);
    final activity = ref.watch(dashboardActivityProvider);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: colors.primary,
          onRefresh: () => refreshDashboard(ref),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.lg,
                  Insets.md,
                  Insets.lg,
                  Insets.xxl,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const DashboardGreetingHeader(),
                    const SizedBox(height: Insets.lg),
                    const _QuickActions(),
                    if (metrics.hasLowStock) ...[
                      const SizedBox(height: Insets.lg),
                      LowStockAlertBanner(
                        items: metrics.lowStockItems,
                        onTap: () => openDashboardLowStock(context, ref),
                      ),
                    ],
                    const SizedBox(height: Insets.xl),
                    const DashboardSectionHeader(title: 'Today at a glance'),
                    const SizedBox(height: Insets.md),
                    _MobileKpiGrid(metrics: metrics),
                    const SizedBox(height: Insets.xl),
                    const InsightHighlights(),
                    const SizedBox(height: Insets.xl),
                    const DashboardSectionHeader(title: 'Trends'),
                    const SizedBox(height: Insets.md),
                    DashboardChartsRow(metrics: metrics),
                    const SizedBox(height: Insets.xl),
                    DashboardSectionHeader(
                      title: 'Top & recent',
                      actionLabel: 'Sales',
                      onAction: () =>
                          context.goNamed(AppRoute.salesName),
                    ),
                    const SizedBox(height: Insets.md),
                    DashboardSecondaryRow(
                      metrics: metrics,
                      activity: activity
                          .take(dashboardListLimit + 1)
                          .toList(),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Four thumb-sized shortcuts for how a shift actually starts.
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final palette = DashboardPalette.of(context);

    final actions = [
      _Action(
        label: 'New sale',
        icon: Icons.point_of_sale_rounded,
        family: palette.revenue,
        onTap: () => context.goNamed(AppRoute.posName),
      ),
      _Action(
        label: 'Stock',
        icon: Icons.inventory_2_outlined,
        family: palette.orders,
        onTap: () => context.goNamed(AppRoute.groceriesName),
      ),
      _Action(
        label: 'Insights',
        icon: Icons.auto_awesome_outlined,
        family: palette.value,
        onTap: () => context.goNamed(AppRoute.insightsName),
      ),
      _Action(
        label: 'Staff',
        icon: Icons.groups_outlined,
        family: palette.staff,
        onTap: () => context.goNamed(AppRoute.staffName),
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: Insets.sm),
          Expanded(child: _QuickTile(action: actions[i], colors: colors)),
        ],
      ],
    );
  }
}

class _Action {
  const _Action({
    required this.label,
    required this.icon,
    required this.family,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final DashboardColor family;
  final VoidCallback onTap;
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.action, required this.colors});

  final _Action action;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.semantic.hairline),
      ),
      child: InkWell(
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: Insets.md,
            horizontal: Insets.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: action.family.tint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: action.family.accent.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  action.icon,
                  size: 20,
                  color: action.family.accent,
                ),
              ),
              const SizedBox(height: Insets.sm),
              Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The five KPIs as a 2-up grid with net profit full-width beneath.
///
/// Four across is a desktop density; one stacked column buries the charts a
/// full screen down. Two columns fit a phone's width with readable cards,
/// and profit — the number an owner checks before anything else — gets the
/// gradient hero row to itself instead of rattling around as the odd fifth.
class _MobileKpiGrid extends StatelessWidget {
  const _MobileKpiGrid({required this.metrics});

  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final cards = buildDashboardKpiCards(context, metrics, profitHero: true);

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
