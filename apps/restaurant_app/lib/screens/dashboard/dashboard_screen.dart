import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/activity_entry.dart';
import '../../models/inventory_item.dart';
import '../../providers/dashboard_metrics_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/staff_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../theme/dashboard_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/activity_timeline_tile.dart';
import '../../widgets/dashboard/category_donut_chart.dart';
import '../../widgets/dashboard/colorful_metric_card.dart';
import '../../widgets/dashboard/insight_highlights.dart';
import '../../widgets/dashboard/low_stock_alert_banner.dart';
import '../../widgets/dashboard/ranked_list_tile.dart';
import '../../widgets/dashboard/revenue_trend_chart.dart';
import '../../widgets/nav_shell_scope.dart';

/// The landing screen.
///
/// Deliberately the warmest surface in the app: tinted KPI cards, real charts
/// and a soft-shadowed card treatment, rather than the dense neutral tables
/// that suit Inventory, Sales and Staff. It is the first thing anyone sees at
/// the start of a shift, and it is read at a glance rather than worked in.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  /// How many rows the two secondary lists show.
  static const int _listLimit = 5;

  /// Below this the charts row stops working as 65/35 and stacks.
  static const double _chartsSideBySideMin = 900;

  /// Below this the two secondary panels stack.
  static const double _secondarySideBySideMin = 820;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardMetricsProvider);
    final activity = ref.watch(dashboardActivityProvider);
    final pad = Insets.page(context.formFactor);
    final isMobile = context.isMobile;
    final spacing = isMobile ? Insets.md : Insets.lg;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            pad,
            isMobile ? Insets.md : Insets.lg,
            pad,
            isMobile ? Insets.sm : pad,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Breakpoints.maxContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _GreetingHeader(),
                    if (metrics.hasLowStock) ...[
                      SizedBox(height: spacing),
                      LowStockAlertBanner(
                        items: metrics.lowStockItems,
                        onTap: () => _openLowStock(context, ref),
                      ),
                    ],
                    SizedBox(height: isMobile ? Insets.lg : Insets.xl),
                    _KpiRow(metrics: metrics),
                    SizedBox(height: spacing),
                    // Under the KPIs rather than above them: the numbers are
                    // what the owner came for, and the assistant's reading of
                    // those numbers is what they look at next.
                    if (!isMobile) ...[
                      const InsightHighlights(),
                      SizedBox(height: spacing),
                    ],
                    _ChartsRow(metrics: metrics),
                    if (!isMobile) ...[
                      SizedBox(height: spacing),
                      _SecondaryRow(
                        metrics: metrics,
                        activity: activity.take(_listLimit + 1).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sends the user to Inventory with the low-stock filter already applied, so
  /// the list they land on is the one the banner was describing.
  void _openLowStock(BuildContext context, WidgetRef ref) {
    final filters = ref.read(inventoryFiltersProvider.notifier)..clear();
    filters
      ..toggleStatus(StockStatus.lowStock)
      ..toggleStatus(StockStatus.outOfStock);

    context.goNamed(AppRoute.inventoryName);
  }
}

// ---------------------------------------------------------------------------
// Greeting
// ---------------------------------------------------------------------------

class _GreetingHeader extends ConsumerWidget {
  const _GreetingHeader();

  /// Below this the header's action drops its label to an icon.
  static const double _labelledActionMin = 420;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final storeName = ref.watch(storeNameProvider);

    final hour = DateTime.now().hour;
    final greeting = switch (hour) {
      < 12 => 'Good morning',
      < 18 => 'Good afternoon',
      _ => 'Good evening',
    };
    final firstName = user?.name.split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const NavMenuButton(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    firstName == null ? greeting : '$greeting, $firstName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 14,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: Insets.xs + 1),
                      // One rich line rather than two Texts in a Row: the date is
                      // long enough to overflow a 360px phone, and only a single
                      // text run can ellipsise across both styles instead of the
                      // second one pushing past the edge.
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: storeName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: ' · ${Fmt.longDate(DateTime.now())}',
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: Insets.lg),
            MediaQuery.sizeOf(context).width < _labelledActionMin
                ? SizedBox(
                    height: 40,
                    width: 40,
                    child: Tooltip(
                      message: 'Open till',
                      child: Material(
                        color: colors.primary,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 20,
                          onPressed: () => context.goNamed(AppRoute.posName),
                          icon: const Icon(Icons.point_of_sale_rounded),
                          color: colors.onPrimary,
                        ),
                      ),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: () => context.goNamed(AppRoute.posName),
                    icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                    label: const Text('Open till'),
                  ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// KPI row
// ---------------------------------------------------------------------------

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.metrics});

  final DashboardMetrics metrics;

  /// Four across needs this much; below it the cards pair up two-by-two.
  static const double _fourAcross = 900;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final isMobile = context.isMobile;

    // Show only 3 key metrics on mobile, all 5 on desktop
    final allCards = <Widget>[
      ColorfulMetricCard(
        label: "Today's sales",
        value: Fmt.moneyCompact(metrics.sales.current),
        icon: Icons.payments_outlined,
        family: palette.revenue,
        change: metrics.sales.change,
        caption: 'vs ${Fmt.moneyCompact(metrics.sales.previous)} yesterday',
      ),
      ColorfulMetricCard(
        label: 'Orders today',
        value: '${metrics.orders.current.round()}',
        icon: Icons.receipt_long_outlined,
        family: palette.orders,
        change: metrics.orders.change,
        caption: '${metrics.orders.previous.round()} yesterday',
      ),
      ColorfulMetricCard(
        label: 'Avg order value',
        value: Fmt.money(metrics.averageOrderValue.current),
        icon: Icons.local_offer_outlined,
        family: palette.value,
        change: metrics.averageOrderValue.change,
        caption: 'per ticket',
      ),
      ColorfulMetricCard(
        label: 'Staff on shift',
        value: '${metrics.staffOnShift}',
        icon: Icons.groups_outlined,
        family: palette.staff,
        // No period-on-period comparison exists for a headcount, so the card
        // carries a ratio instead of a fabricated percentage.
        caption: 'of ${metrics.staffTotal} active',
      ),
      ColorfulMetricCard(
        label: 'Net profit today',
        value: Fmt.moneyCompact(metrics.netProfit.current),
        icon: Icons.account_balance_wallet_outlined,
        family: palette.revenue,
        change: metrics.netProfit.change,
        caption: 'vs ${Fmt.moneyCompact(metrics.netProfit.previous)} yesterday',
      ),
    ];

    final cards = isMobile ? allCards.take(3).toList() : allCards;

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = isMobile ? 8.0 : Insets.md;
        // 1 column on mobile, 2 on tablet, 3 on desktop
        final columns = isMobile
            ? 1
            : constraints.maxWidth >= _fourAcross ? 3 : 2;
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

// ---------------------------------------------------------------------------
// Charts
// ---------------------------------------------------------------------------

class _ChartsRow extends StatelessWidget {
  const _ChartsRow({required this.metrics});

  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide =
            constraints.maxWidth >= DashboardScreen._chartsSideBySideMin;
        final chartHeight = context.isMobile
            ? DashboardStyle.chartHeightMobile
            : DashboardStyle.chartHeightDesktop;

        final revenue = _DashboardCard(
          title: 'Revenue',
          subtitle: 'Last 7 days',
          child: RevenueTrendChart(
            points: metrics.revenueSeries,
            height: chartHeight,
          ),
        );

        final donut = _DashboardCard(
          title: 'Sales by category',
          subtitle: 'Last 7 days',
          child: CategoryDonutChart(
            slices: metrics.categoryBreakdown,
            height: chartHeight,
          ),
        );

        if (!sideBySide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [revenue, const SizedBox(height: Insets.lg), donut],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 65 / 35, the split the trend needs to stay readable across a
            // week while the donut keeps a circle big enough to label.
            Expanded(flex: 65, child: revenue),
            const SizedBox(width: Insets.lg),
            Expanded(flex: 35, child: donut),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Secondary row
// ---------------------------------------------------------------------------

class _SecondaryRow extends StatelessWidget {
  const _SecondaryRow({required this.metrics, required this.activity});

  final DashboardMetrics metrics;
  final List<ActivityEntry> activity;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide =
            constraints.maxWidth >= DashboardScreen._secondarySideBySideMin;

        final top = _DashboardCard(
          title: 'Top selling items',
          subtitle: 'Last 7 days',
          child: _TopItemsList(items: metrics.topItems),
        );

        final feed = _DashboardCard(
          title: 'Recent activity',
          child: ActivityTimeline(entries: activity),
        );

        if (!sideBySide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [top, const SizedBox(height: Insets.lg), feed],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: top),
            const SizedBox(width: Insets.lg),
            Expanded(child: feed),
          ],
        );
      },
    );
  }
}

class _TopItemsList extends StatelessWidget {
  const _TopItemsList({required this.items});

  final List<TopItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Insets.lg),
        child: Text(
          'No sales in the last 7 days.',
          style: context.text.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      );
    }

    final shown = items.take(DashboardScreen._listLimit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < shown.length; i++)
          RankedListTile(
            rank: i + 1,
            title: shown[i].name,
            leadingEmoji: shown[i].emoji,
            subtitle: Fmt.money(shown[i].revenue),
            trailing: '${shown[i].units} sold',
            colorIndex: shown[i].colorIndex,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Card shell
// ---------------------------------------------------------------------------

/// The dashboard's panel: rounded, softly shadowed, no hairline border.
///
/// Distinct from [DetailPanel] on purpose — the detail screens use a bordered
/// surface that sits quietly behind dense content, where this one is meant to
/// lift off the page.
class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: DashboardStyle.cardPadding,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: DashboardStyle.radius,
        boxShadow: DashboardStyle.shadow(Theme.of(context).brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (subtitle case final sub?) ...[
                const SizedBox(width: Insets.sm),
                Flexible(
                  child: Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: Insets.lg),
          child,
        ],
      ),
    );
  }
}
