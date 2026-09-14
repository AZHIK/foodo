/// Reporting state: one shared date window, one notifier per section.
///
/// Every section reads its aggregate from the backend (POS or Inventory
/// Service) — nothing here rolls its own numbers from the local cache, so
/// the screen can never disagree with the server about what a day earned.
/// With no business context every section is empty rather than demo data:
/// invented takings would be worse than a blank report.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/inventory_api_service.dart';
import '../services/pos_reports_api_service.dart';
import 'inventory_api_provider.dart';
import 'inventory_provider.dart';
import 'permissions_provider.dart';
import 'pos_api_provider.dart';

// ---------------------------------------------------------------------------
// Shared date window
// ---------------------------------------------------------------------------

/// The window every report section reads. Null ends are open; the default
/// is the last 30 days, which is what an owner opening Reports almost
/// always wants to see first.
@immutable
class ReportsDateFilter {
  const ReportsDateFilter({this.from, this.to});

  final DateTime? from;
  final DateTime? to;

  ReportsDateFilter copyWith({DateTime? from, DateTime? to}) =>
      ReportsDateFilter(from: from ?? this.from, to: to ?? this.to);
}

DateTime _thirtyDaysAgo() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day).subtract(
    const Duration(days: 29),
  );
}

class ReportsDateFilterNotifier extends Notifier<ReportsDateFilter> {
  @override
  ReportsDateFilter build() =>
      ReportsDateFilter(from: _thirtyDaysAgo(), to: null);

  void setRange(DateTime? from, DateTime? to) =>
      state = ReportsDateFilter(from: from, to: to);

  void clear() => state = ReportsDateFilter(from: _thirtyDaysAgo(), to: null);
}

final reportsDateFilterProvider =
    NotifierProvider<ReportsDateFilterNotifier, ReportsDateFilter>(
      ReportsDateFilterNotifier.new,
    );

// ---------------------------------------------------------------------------
// Sales sections (POS Service)
// ---------------------------------------------------------------------------

/// Mixin-style base is deliberately avoided — each section is a few lines,
/// and a shared abstraction would hide which service and DTO each one
/// reads. Explicit over clever.
class DailyTakingsNotifier extends AsyncNotifier<List<DailyTakingsDayDto>> {
  @override
  Future<List<DailyTakingsDayDto>> build() async {
    final businessId = ref.watch(currentBusinessIdProvider);
    final filter = ref.watch(reportsDateFilterProvider);
    if (businessId == null) return const [];
    return ref.watch(posReportsApiServiceProvider).fetchDailyTakings(
          businessId: businessId,
          from: filter.from,
          to: filter.to,
        );
  }

  Future<void> refresh() async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null) return;
    final filter = ref.read(reportsDateFilterProvider);
    state = const AsyncLoading<List<DailyTakingsDayDto>>().copyWithPrevious(
      state,
    );
    state = AsyncData(
      await ref.read(posReportsApiServiceProvider).fetchDailyTakings(
            businessId: businessId,
            from: filter.from,
            to: filter.to,
          ),
    );
  }
}

final dailyTakingsProvider =
    AsyncNotifierProvider<DailyTakingsNotifier, List<DailyTakingsDayDto>>(
      DailyTakingsNotifier.new,
    );

class ItemMixNotifier extends AsyncNotifier<List<ItemMixLineDto>> {
  @override
  Future<List<ItemMixLineDto>> build() async {
    final businessId = ref.watch(currentBusinessIdProvider);
    final filter = ref.watch(reportsDateFilterProvider);
    if (businessId == null) return const [];
    return ref.watch(posReportsApiServiceProvider).fetchItemMix(
          businessId: businessId,
          from: filter.from,
          to: filter.to,
        );
  }

  Future<void> refresh() async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null) return;
    final filter = ref.read(reportsDateFilterProvider);
    state = const AsyncLoading<List<ItemMixLineDto>>().copyWithPrevious(state);
    state = AsyncData(
      await ref.read(posReportsApiServiceProvider).fetchItemMix(
            businessId: businessId,
            from: filter.from,
            to: filter.to,
          ),
    );
  }
}

final itemMixProvider =
    AsyncNotifierProvider<ItemMixNotifier, List<ItemMixLineDto>>(
      ItemMixNotifier.new,
    );

/// An item-mix line with its catalog name resolved. The backend returns ids
/// (Inventory Service owns names); this join is display-only — the numbers
/// stay exactly what the server reported.
@immutable
class ResolvedItemMixLine {
  const ResolvedItemMixLine({required this.line, required this.name});

  final ItemMixLineDto line;
  final String name;
}

final resolvedItemMixProvider = Provider<List<ResolvedItemMixLine>>((ref) {
  final lines = ref.watch(itemMixProvider).valueOrNull ?? const [];
  final items = ref.watch(inventoryItemsListProvider);
  final nameByCatalogId = {
    for (final item in items)
      if (item.catalogItemId != null) item.catalogItemId!: item.name,
  };
  return [
    for (final line in lines)
      ResolvedItemMixLine(
        line: line,
        name: nameByCatalogId[line.itemId] ?? 'Unknown item',
      ),
  ];
});

class StaffPerformanceNotifier
    extends AsyncNotifier<List<StaffPerformanceLineDto>> {
  @override
  Future<List<StaffPerformanceLineDto>> build() async {
    final businessId = ref.watch(currentBusinessIdProvider);
    final filter = ref.watch(reportsDateFilterProvider);
    if (businessId == null) return const [];
    return ref.watch(posReportsApiServiceProvider).fetchStaffPerformance(
          businessId: businessId,
          from: filter.from,
          to: filter.to,
        );
  }

  Future<void> refresh() async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null) return;
    final filter = ref.read(reportsDateFilterProvider);
    state = const AsyncLoading<List<StaffPerformanceLineDto>>().copyWithPrevious(
      state,
    );
    state = AsyncData(
      await ref.read(posReportsApiServiceProvider).fetchStaffPerformance(
            businessId: businessId,
            from: filter.from,
            to: filter.to,
          ),
    );
  }
}

final staffPerformanceProvider =
    AsyncNotifierProvider<StaffPerformanceNotifier, List<StaffPerformanceLineDto>>(
      StaffPerformanceNotifier.new,
    );

class FinanceSummaryNotifier extends AsyncNotifier<FinanceSummaryDto?> {
  @override
  Future<FinanceSummaryDto?> build() async {
    final businessId = ref.watch(currentBusinessIdProvider);
    final filter = ref.watch(reportsDateFilterProvider);
    if (businessId == null) return null;
    return ref.watch(posReportsApiServiceProvider).fetchFinanceSummary(
          businessId: businessId,
          from: filter.from,
          to: filter.to,
        );
  }

  Future<void> refresh() async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null) return;
    final filter = ref.read(reportsDateFilterProvider);
    state = const AsyncLoading<FinanceSummaryDto?>().copyWithPrevious(state);
    state = AsyncData(
      await ref.read(posReportsApiServiceProvider).fetchFinanceSummary(
            businessId: businessId,
            from: filter.from,
            to: filter.to,
          ),
    );
  }
}

final financeSummaryProvider =
    AsyncNotifierProvider<FinanceSummaryNotifier, FinanceSummaryDto?>(
      FinanceSummaryNotifier.new,
    );

// ---------------------------------------------------------------------------
// Inventory sections (Inventory Service)
// ---------------------------------------------------------------------------

class WasteSummaryNotifier extends AsyncNotifier<WasteSummaryDto?> {
  @override
  Future<WasteSummaryDto?> build() async {
    final businessId = ref.watch(currentBusinessIdProvider);
    final filter = ref.watch(reportsDateFilterProvider);
    if (businessId == null) return null;
    return ref.watch(inventoryApiServiceProvider).fetchWasteSummary(
          businessId: businessId,
          from: filter.from,
          to: filter.to,
        );
  }

  Future<void> refresh() async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null) return;
    final filter = ref.read(reportsDateFilterProvider);
    state = const AsyncLoading<WasteSummaryDto?>().copyWithPrevious(state);
    state = AsyncData(
      await ref.read(inventoryApiServiceProvider).fetchWasteSummary(
            businessId: businessId,
            from: filter.from,
            to: filter.to,
          ),
    );
  }
}

final wasteSummaryProvider =
    AsyncNotifierProvider<WasteSummaryNotifier, WasteSummaryDto?>(
      WasteSummaryNotifier.new,
    );

class ProductionSummaryNotifier extends AsyncNotifier<ProductionSummaryDto?> {
  @override
  Future<ProductionSummaryDto?> build() async {
    final businessId = ref.watch(currentBusinessIdProvider);
    final filter = ref.watch(reportsDateFilterProvider);
    if (businessId == null) return null;
    return ref.watch(inventoryApiServiceProvider).fetchProductionSummary(
          businessId: businessId,
          from: filter.from,
          to: filter.to,
        );
  }

  Future<void> refresh() async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null) return;
    final filter = ref.read(reportsDateFilterProvider);
    state = const AsyncLoading<ProductionSummaryDto?>().copyWithPrevious(state);
    state = AsyncData(
      await ref.read(inventoryApiServiceProvider).fetchProductionSummary(
            businessId: businessId,
            from: filter.from,
            to: filter.to,
          ),
    );
  }
}

final productionSummaryProvider =
    AsyncNotifierProvider<ProductionSummaryNotifier, ProductionSummaryDto?>(
      ProductionSummaryNotifier.new,
    );

class StockValuationNotifier extends AsyncNotifier<StockValuationDto?> {
  @override
  Future<StockValuationDto?> build() async {
    final businessId = ref.watch(currentBusinessIdProvider);
    // A snapshot — the date window deliberately does not apply.
    if (businessId == null) return null;
    return ref.watch(inventoryApiServiceProvider).fetchStockValuation(
          businessId: businessId,
        );
  }

  Future<void> refresh() async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null) return;
    state = const AsyncLoading<StockValuationDto?>().copyWithPrevious(state);
    state = AsyncData(
      await ref.read(inventoryApiServiceProvider).fetchStockValuation(
            businessId: businessId,
          ),
    );
  }
}

final stockValuationProvider =
    AsyncNotifierProvider<StockValuationNotifier, StockValuationDto?>(
      StockValuationNotifier.new,
    );

/// Re-reads every section — pull-to-refresh on the Reports screen.
Future<void> refreshAllReports(WidgetRef ref) async {
  await Future.wait([
    ref.read(dailyTakingsProvider.notifier).refresh(),
    ref.read(itemMixProvider.notifier).refresh(),
    ref.read(staffPerformanceProvider.notifier).refresh(),
    ref.read(financeSummaryProvider.notifier).refresh(),
    ref.read(wasteSummaryProvider.notifier).refresh(),
    ref.read(productionSummaryProvider.notifier).refresh(),
    ref.read(stockValuationProvider.notifier).refresh(),
  ]);
}
