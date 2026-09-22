import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_insights_provider.dart';
import 'couriers_provider.dart';
import 'customers_provider.dart';
import 'dashboard_metrics_provider.dart';
import 'inventory_provider.dart';
import 'orders_provider.dart';
import 'other_expenses_provider.dart';
import 'other_incomes_provider.dart';
import 'production_provider.dart';
import 'reorder_provider.dart';
import 'reports_provider.dart';
import 'roles_provider.dart';
import 'staff_provider.dart';
import 'stock_movement_provider.dart';
import 'store_api_provider_real.dart';
import 'suppliers_provider.dart';

/// Shell branch indices, in the order the tabs are declared.
///
/// These MUST stay in lockstep with [_destinations] in
/// `widgets/responsive_scaffold.dart` and the `branches` list in
/// `router/app_router.dart` — all three line up index-for-index.
abstract final class ShellBranch {
  static const dashboard = 0;
  static const pos = 1;
  static const sales = 2;
  static const customers = 3;
  static const reorders = 4;
  static const production = 5;
  static const suppliers = 6;
  static const couriers = 7;
  static const finance = 8;
  static const reports = 9;
  static const insights = 10;
  static const inventory = 11;
  static const staff = 12;
  static const settings = 13;
}

/// The branch the shell is currently showing, as an index into [ShellBranch].
///
/// Written by `ResponsiveScaffold` on every tab switch and read by the
/// top bar's refresh button, so the button always refreshes the visible tab
/// without needing the navigation shell itself.
final currentBranchIndexProvider = StateProvider<int>((ref) => 0);

/// Re-reads whatever backs [branchIndex] and completes when it has.
///
/// Every list notifier in this app follows the same stale-while-revalidate
/// contract — `build()` returns the cached rows immediately and syncs in the
/// background — so awaiting here never blanks the screen the user is looking
/// at; the spinner only reflects real completion.
///
/// Navigation taps call this without awaiting (the switch itself stays
/// instant); the top bar's refresh button awaits it to drive its spinner.
///
/// Takes a [WidgetRef] (rather than a bare [Ref]) because the reports and
/// store refresh helpers it delegates to are typed that way.
Future<void> refreshBranch(WidgetRef ref, int branchIndex) async {
  switch (branchIndex) {
    case ShellBranch.dashboard:
      // Derived read models recompute; the invalidated sources below pull
      // fresh rows behind them.
      ref
        ..invalidate(ordersProvider)
        ..invalidate(inventoryItemsProvider)
        ..invalidate(otherExpensesProvider)
        ..invalidate(otherIncomesProvider)
        ..invalidate(stockMovementsProvider)
        ..invalidate(dashboardMetricsProvider)
        ..invalidate(dashboardActivityProvider)
        ..invalidate(aiInsightsProvider);
    case ShellBranch.pos:
      // The till menu derives from the inventory cache.
      await ref.read(inventoryItemsProvider.notifier).refresh();
    case ShellBranch.sales:
      await ref.read(ordersProvider.notifier).checkForNewOrders();
    case ShellBranch.customers:
      await ref.read(customersProvider.notifier).refresh();
    case ShellBranch.reorders:
      await ref.read(reordersProvider.notifier).refresh();
    case ShellBranch.production:
      await Future.wait([
        ref.read(recipesCatalogProvider.notifier).refresh(),
        ref.read(productionRunsProvider.notifier).refresh(),
        ref.read(productionHistoryProvider.notifier).refresh(),
      ]);
    case ShellBranch.suppliers:
      await ref.read(suppliersProvider.notifier).refresh();
    case ShellBranch.couriers:
      ref.invalidate(couriersProvider);
    case ShellBranch.finance:
      await Future.wait([
        ref.read(otherExpensesProvider.notifier).refresh(),
        ref.read(otherIncomesProvider.notifier).refresh(),
      ]);
    case ShellBranch.reports:
      await refreshAllReports(ref);
    case ShellBranch.insights:
      ref.invalidate(aiInsightsProvider);
    case ShellBranch.inventory:
      await ref.read(inventoryItemsProvider.notifier).refresh();
    case ShellBranch.staff:
      await Future.wait([
        ref.read(staffMembersProvider.notifier).refresh(),
        ref.read(rolesProvider.notifier).refresh(),
      ]);
    case ShellBranch.settings:
      await refreshStores(ref);
    default:
      break;
  }
}

/// Fire-and-forget variant for navigation taps, where awaiting would only
/// delay a switch that is already showing cached data.
void refreshBranchInBackground(WidgetRef ref, int branchIndex) {
  unawaited(refreshBranch(ref, branchIndex));
}
