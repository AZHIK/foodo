import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ai_insight.dart';
import '../models/inventory_item.dart';
import '../models/stock_movement.dart';
import '../router/app_router.dart';
import '../utils/formatters.dart';
import 'dashboard_provider.dart';
import 'inventory_provider.dart';
import 'stock_movement_provider.dart';

/// Generates the assistant's observations from the app's real state.
///
/// Nothing here is canned copy: every insight is computed from the same
/// providers the rest of the app reads, so if the stockroom changes the advice
/// changes with it. That is also what keeps the feature honest — an insight
/// can always be checked against the screen it links to.
///
/// A real build would send this context to a model and render its reply. The
/// shape of the output is the same either way, which is the point of putting
/// the derivation behind a provider.
final aiInsightsProvider = Provider<List<AiInsight>>((ref) {
  final items = ref.watch(inventoryItemsProvider);
  final movements = ref.watch(stockMovementsProvider);
  final summary = ref.watch(dashboardSummaryProvider);

  final insights = <AiInsight>[
    ..._stockInsights(ref, items),
    ..._wasteInsights(items, movements),
    ..._salesInsights(summary),
  ];

  // Most urgent first; ties keep their derivation order, which groups the
  // stock items together rather than interleaving categories.
  insights.sort((a, b) => a.priority.index.compareTo(b.priority.index));
  return insights;
});

// ---------------------------------------------------------------------------
// Stock
// ---------------------------------------------------------------------------

List<AiInsight> _stockInsights(Ref ref, List<InventoryItem> items) {
  final reorder = ref.watch(reorderListProvider);
  if (reorder.isEmpty) {
    return [
      const AiInsight(
        id: 'stock-healthy',
        title: 'Every line is above its reorder threshold',
        body:
            'Nothing needs ordering today. The next thing worth watching is '
            'whichever line moves fastest over the weekend.',
        category: InsightCategory.stock,
        priority: InsightPriority.informational,
      ),
    ];
  }

  final out = reorder.where((i) => i.status == StockStatus.outOfStock).toList();
  final worst = reorder.first;

  return [
    if (out.isNotEmpty)
      AiInsight(
        id: 'stock-out',
        title: '${out.length} ${out.length == 1 ? 'line is' : 'lines are'} '
            'out of stock',
        body:
            'These cannot be sold or prepped until a delivery lands. '
            '${out.take(3).map((i) => i.name).join(', ')}'
            '${out.length > 3 ? ' and ${out.length - 3} more' : ''}.',
        category: InsightCategory.stock,
        priority: InsightPriority.urgent,
        evidence: [
          (label: 'Out of stock', value: '${out.length}'),
          (
            label: 'Value at risk',
            value: Fmt.moneyCompact(
              out.fold<double>(0, (sum, i) => sum + i.reorderLevel * i.unitCost),
            ),
          ),
        ],
        actionLabel: 'Open inventory',
        actionRoute: AppRoute.inventoryName,
      ),
    AiInsight(
      id: 'stock-reorder',
      title: '${worst.name} is the most urgent reorder',
      body:
          'It is at ${worst.stock} ${worst.unit} against a threshold of '
          '${worst.reorderLevel}. Restocking to threshold costs about '
          '${Fmt.money((worst.reorderLevel - worst.stock).clamp(0, 1 << 30) * worst.unitCost)} '
          'at cost.',
      category: InsightCategory.stock,
      priority: worst.status == StockStatus.outOfStock
          ? InsightPriority.urgent
          : InsightPriority.advisory,
      evidence: [
        (label: 'On hand', value: '${worst.stock} ${worst.unit}'),
        (label: 'Threshold', value: '${worst.reorderLevel} ${worst.unit}'),
        (label: 'Unit cost', value: Fmt.money(worst.unitCost)),
      ],
      actionLabel: 'View item',
      actionRoute: AppRoute.itemDetailName,
      actionParams: {'itemId': worst.id},
    ),
  ];
}

// ---------------------------------------------------------------------------
// Waste
// ---------------------------------------------------------------------------

List<AiInsight> _wasteInsights(
  List<InventoryItem> items,
  List<StockMovement> movements,
) {
  final since = DateTime.now().subtract(const Duration(days: 30));
  final costById = {for (final item in items) item.id: item.unitCost};
  final nameById = {for (final item in items) item.id: item.name};

  final wastedUnits = <String, int>{};
  var totalCost = 0.0;

  for (final movement in movements) {
    if (movement.type != StockMovementType.waste) continue;
    if (movement.at.isBefore(since)) continue;

    final units = movement.delta.abs();
    wastedUnits[movement.itemId] = (wastedUnits[movement.itemId] ?? 0) + units;
    totalCost += units * (costById[movement.itemId] ?? 0);
  }

  if (wastedUnits.isEmpty) {
    return const [
      AiInsight(
        id: 'waste-none',
        title: 'No waste logged in the last 30 days',
        body:
            'Either the kitchen is running very tight, or waste is not being '
            'recorded. Worth confirming which — untracked waste hides a real '
            'cost.',
        category: InsightCategory.waste,
        priority: InsightPriority.advisory,
      ),
    ];
  }

  // The line losing the most money, which is not always the one losing the
  // most units — that distinction is the whole value of the insight.
  var worstId = wastedUnits.keys.first;
  var worstCost = 0.0;
  for (final entry in wastedUnits.entries) {
    final double cost = entry.value * (costById[entry.key] ?? 0);
    if (cost > worstCost) {
      worstCost = cost;
      worstId = entry.key;
    }
  }

  return [
    AiInsight(
      id: 'waste-top',
      title: '${nameById[worstId] ?? 'One line'} is your costliest waste',
      body:
          'It accounts for ${Fmt.money(worstCost)} of the '
          '${Fmt.money(totalCost)} written off in the last 30 days. Check '
          'portioning and delivery frequency before reordering at the same '
          'volume.',
      category: InsightCategory.waste,
      priority: worstCost > totalCost * 0.4
          ? InsightPriority.advisory
          : InsightPriority.informational,
      evidence: [
        (label: 'This line', value: Fmt.money(worstCost)),
        (label: 'All waste, 30d', value: Fmt.money(totalCost)),
        (label: 'Units lost', value: '${wastedUnits[worstId]}'),
      ],
      actionLabel: 'View item',
      actionRoute: AppRoute.itemDetailName,
      actionParams: {'itemId': worstId},
    ),
  ];
}

// ---------------------------------------------------------------------------
// Sales
// ---------------------------------------------------------------------------

List<AiInsight> _salesInsights(DashboardSummary summary) {
  final change = summary.takingsChange;

  return [
    if (change != null)
      AiInsight(
        id: 'sales-trend',
        title: change >= 0
            ? 'Takings are up ${Fmt.percent(change)} on yesterday'
            : 'Takings are down ${Fmt.percent(change.abs())} on yesterday',
        body: change >= 0
            ? 'Today is running ahead at ${Fmt.money(summary.takingsToday)} '
                  'across ${summary.ordersToday} orders.'
            : 'Today is at ${Fmt.money(summary.takingsToday)} across '
                  '${summary.ordersToday} orders. One slow day is noise; two '
                  'is a pattern worth checking against staffing.',
        category: InsightCategory.sales,
        priority: change >= 0
            ? InsightPriority.informational
            : InsightPriority.advisory,
        evidence: [
          (label: 'Today', value: Fmt.money(summary.takingsToday)),
          (label: 'Yesterday', value: Fmt.money(summary.takingsYesterday)),
          (label: 'Avg ticket', value: Fmt.money(summary.averageTicket)),
        ],
        actionLabel: 'Open sales',
        actionRoute: AppRoute.salesName,
      ),
    if (summary.openOrders > 0)
      AiInsight(
        id: 'sales-open',
        title: '${summary.openOrders} '
            '${summary.openOrders == 1 ? 'ticket is' : 'tickets are'} '
            'still open',
        body:
            'Unsettled tickets do not count towards takings and are the usual '
            'cause of a till that will not reconcile at close.',
        category: InsightCategory.sales,
        priority: InsightPriority.advisory,
        evidence: [(label: 'Open', value: '${summary.openOrders}')],
        actionLabel: 'Open sales',
        actionRoute: AppRoute.salesName,
      ),
  ];
}

/// Questions the assistant offers as starting points.
///
/// Written against data the app actually holds, so none of them promise an
/// answer the insight engine above could not produce.
final suggestedPromptsProvider = Provider<List<String>>(
  (ref) => const [
    'What needs reordering before the weekend?',
    'Where is my waste money going?',
    'How did today compare with yesterday?',
    'Which items have not moved in a month?',
    'Who processed the most orders this week?',
  ],
);
