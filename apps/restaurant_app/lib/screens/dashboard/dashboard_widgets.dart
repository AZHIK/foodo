import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/activity_entry.dart';
import '../../models/inventory_item.dart';
import '../../constants/app_limits.dart';
import '../../constants/app_strings.dart';
import '../../providers/ai_insights_provider.dart';
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
import '../../widgets/dashboard/ranked_list_tile.dart';
import '../../widgets/dashboard/revenue_trend_chart.dart';
import '../../widgets/nav_shell_scope.dart';

/// Shared building blocks for the dashboard's mobile and desktop views.
///
/// The two views compose these pieces differently — the mobile view stacks
/// everything with phone-sized spacing and a 2x2 KPI grid, the desktop view
/// uses multi-column rows — but neither redefines what a greeting, a KPI
/// card or a chart row *is*. A change to the card treatment lands in both.
class DashboardWidgets {
  const DashboardWidgets._();
}

/// How many rows the two secondary lists show.
const int dashboardListLimit = 5;

/// Sends the user to Groceries with the low-stock filter already applied,
/// so the list they land on is the one the banner was describing. Always
/// Groceries, never Menu Items — a low-stock alert is about raw materials
/// and stock counts, which is exactly what that view's filters cover.
void openDashboardLowStock(BuildContext context, WidgetRef ref) {
  final filters = ref.read(inventoryFiltersProvider.notifier)..clear();
  filters
    ..toggleStatus(StockStatus.lowStock)
    ..toggleStatus(StockStatus.outOfStock);

  context.goNamed(AppRoute.groceriesName);
}

/// Re-reads everything the dashboard shows. Used by pull-to-refresh on both
/// views — the providers derive from the same orders, inventory and staff
/// state the rest of the app reads, so invalidation just recomputes.
Future<void> refreshDashboard(WidgetRef ref) async {
  ref
    ..invalidate(dashboardMetricsProvider)
    ..invalidate(dashboardActivityProvider)
    ..invalidate(aiInsightsProvider);
}

/// All five KPI cards in a fixed order: sales, orders, average order value,
/// staff on shift, net profit.
///
/// Built once and shared so the mobile and desktop views can never disagree
/// about what a KPI says — they only differ in how the cards are arranged.
List<Widget> buildDashboardKpiCards(
  BuildContext context,
  DashboardMetrics metrics, {
  bool profitHero = false,
}) {
  final palette = DashboardPalette.of(context);
  return [
     ColorfulMetricCard(
       label: AppStrings.todaySales,
       value: Fmt.moneyCompact(metrics.sales.current),
       icon: Icons.payments_outlined,
       family: palette.revenue,
       change: metrics.sales.change,
       caption: AppStrings.vsYesterday(
         Fmt.moneyCompact(metrics.sales.previous),
       ),
       deepGradient: true,
     ),
     ColorfulMetricCard(
       label: AppStrings.ordersToday,
       value: '${metrics.orders.current.round()}',
       icon: Icons.receipt_long_outlined,
       family: palette.orders,
       change: metrics.orders.change,
       caption: AppStrings.yesterdayCount(
         '${metrics.orders.previous.round()}',
       ),
       deepGradient: true,
     ),
     ColorfulMetricCard(
       label: AppStrings.avgOrderValue,
       value: Fmt.money(metrics.averageOrderValue.current),
       icon: Icons.local_offer_outlined,
       family: palette.value,
       change: metrics.averageOrderValue.change,
       caption: AppStrings.perTicket,
       deepGradient: true,
     ),
     ColorfulMetricCard(
       label: AppStrings.staffOnShift,
       value: '${metrics.staffOnShift}',
       icon: Icons.groups_outlined,
       family: palette.staff,
       // No period-on-period comparison exists for a headcount, so the card
       // carries a ratio instead of a fabricated percentage.
       caption: AppStrings.ofActive('${metrics.staffTotal}'),
       deepGradient: true,
     ),
    ColorfulMetricCard(
      label: AppStrings.netProfitToday,
      value: Fmt.moneyCompact(metrics.netProfit.current),
      icon: Icons.account_balance_wallet_outlined,
      family: palette.revenue,
      change: metrics.netProfit.change,
      caption: AppStrings.vsYesterday(
        Fmt.moneyCompact(metrics.netProfit.previous),
      ),
      hero: profitHero,
    ),
  ];
}

// ---------------------------------------------------------------------------
// Greeting
// ---------------------------------------------------------------------------

class DashboardGreetingHeader extends ConsumerWidget {
  const DashboardGreetingHeader({super.key});

  /// Below this the header's action drops its label to an icon.
  static const double _labelledActionMin = 420;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = context.isMobile;
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final storeName = ref.watch(storeNameProvider);

    final hour = DateTime.now().hour;
    final greeting = switch (hour) {
      < 12 => AppStrings.goodMorning,
      < 18 => AppStrings.goodAfternoon,
      _ => AppStrings.goodEvening,
    };
    final firstName = user?.name.split(' ').first;
    final initial = (firstName ?? storeName).trim().isEmpty
        ? '•'
        : (firstName ?? storeName).trim()[0].toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const NavMenuButton(),
            // Avatar — plain circle on mobile, gradient ring on desktop.
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: isMobile
                    ? colors.surfaceContainerLowest
                    : null,
                shape: BoxShape.circle,
                gradient: isMobile ? null : LinearGradient(
                  colors: [colors.primary, colors.tertiary],
                ),
                border: isMobile
                    ? Border.all(color: context.semantic.hairline)
                    : null,
              ),
              padding: isMobile ? const EdgeInsets.all(2) : const EdgeInsets.all(2),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initial,
                  style: context.text.titleMedium?.copyWith(
                    color: isMobile ? colors.onSurface : colors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    firstName == null
                        ? greeting
                        : AppStrings.greetingFor(greeting, firstName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  // Store + date as a single pill chip: compact on a 360px
                  // phone, and it stops the date pushing past the edge.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Insets.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(Radii.pill),
                        border: Border.all(color: context.semantic.hairline),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            size: 12,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '$storeName · ${Fmt.longDate(DateTime.now())}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.labelSmall?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Insets.md),
            MediaQuery.sizeOf(context).width < _labelledActionMin
                 ? SizedBox(
                     height: 48,
                     width: 48,
                     child: Tooltip(
                       message: AppStrings.openTill,
                       child: Material(
                         color: isMobile
                             ? colors.surfaceContainerLowest
                             : null,
                         clipBehavior: Clip.antiAlias,
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(16),
                           side: isMobile
                               ? BorderSide(color: context.semantic.hairline)
                               : BorderSide.none,
                         ),
                         child: Ink(
                           decoration: BoxDecoration(
                             gradient: isMobile
                                 ? null
                                 : LinearGradient(
                                     colors: [colors.primary, colors.tertiary],
                                   ),
                             borderRadius: BorderRadius.circular(16),
                           ),
                           child: IconButton(
                             padding: EdgeInsets.zero,
                             iconSize: 22,
                             onPressed: () => context.goNamed(AppRoute.posName),
                             icon: const Icon(Icons.point_of_sale_rounded),
                             color: isMobile ? colors.onSurface : colors.onPrimary,
                           ),
                         ),
                       ),
                     ),
                   )
                : FilledButton.icon(
                    onPressed: () => context.goNamed(AppRoute.posName),
                    icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                    label: Text(AppStrings.openTill),
                  ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Charts
// ---------------------------------------------------------------------------

class DashboardChartsRow extends StatelessWidget {
  const DashboardChartsRow({super.key, required this.metrics});

  final DashboardMetrics metrics;

  /// Below this the charts row stops working as 65/35 and stacks.
  static const double _sideBySideMin = 900;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= _sideBySideMin;
        final chartHeight = context.isMobile
            ? DashboardStyle.chartHeightMobile
            : DashboardStyle.chartHeightDesktop;

        final revenue = DashboardCard(
          title: AppStrings.revenueCard,
          subtitle: AppStrings.last7DaysLabel,
          child: RevenueTrendChart(
            points: metrics.revenueSeries,
            height: chartHeight,
          ),
        );

        final donut = DashboardCard(
          title: AppStrings.salesByCategory,
          subtitle: AppStrings.last7DaysLabel,
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

class DashboardSecondaryRow extends StatelessWidget {
  const DashboardSecondaryRow({
    super.key,
    required this.metrics,
    required this.activity,
  });

  final DashboardMetrics metrics;
  final List<ActivityEntry> activity;

  /// Below this the two secondary panels stack.
  static const double _sideBySideMin = 820;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= _sideBySideMin;

        final top = DashboardCard(
          title: AppStrings.topSellingItems,
          subtitle: AppStrings.last7DaysLabel,
          child: DashboardTopItemsList(items: metrics.topItems),
        );

        final feed = DashboardCard(
          title: AppStrings.recentActivityCard,
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

class DashboardTopItemsList extends StatelessWidget {
  const DashboardTopItemsList({super.key, required this.items});

  final List<TopItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Insets.lg),
        child: Text(
          AppStrings.noSales7Days,
          style: context.text.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      );
    }

    final shown = items.take(AppLimits.dashboardListLimit).toList();
    final maxRevenue =
        shown.map((e) => e.revenue).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: 40),
          RankedListTile(
            rank: i + 1,
            title: shown[i].name,
            leadingEmoji: shown[i].emoji,
            subtitle: Fmt.money(shown[i].revenue),
            trailing: AppStrings.unitsSold(shown[i].units),
            colorIndex: shown[i].colorIndex,
            // Bar shows relative revenue so the ranking reads at a glance.
            progress: maxRevenue <= 0 ? 0 : shown[i].revenue / maxRevenue,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Card shell
// ---------------------------------------------------------------------------

/// The dashboard's panel: rounded, softly shadowed, hairline-bordered.
///
/// Distinct from [DetailPanel] on purpose — the detail screens use a flatter
/// bordered surface that sits quietly behind dense content, where this one
/// is meant to lift off the page with a stronger radius + shadow.
class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  /// Trailing header slot — e.g. a "See all" button or total pill.
  final Widget? action;

  /// Leading header slot — small icon chip for scannability.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final mobile = context.isMobile;

    return Container(
      padding: mobile
          ? DashboardStyle.cardPaddingMobile
          : DashboardStyle.cardPadding,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: context.semantic.hairline),
        boxShadow: mobile ? null : DashboardStyle.shadow(Theme.of(context).brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: Insets.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle case final sub?)
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: Insets.sm),
                action!,
              ],
            ],
          ),
          const SizedBox(height: Insets.md),
          child,
        ],
      ),
    );
  }
}

/// Small section label used on mobile between slivers — uppercase,
/// letterspaced, with an optional trailing action.
class DashboardSectionHeader extends StatelessWidget {
  const DashboardSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.eyebrow.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(Radii.pill),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Insets.sm,
                vertical: Insets.xs,
              ),
              child: Text(
                actionLabel!,
                style: context.text.labelMedium?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
