/// Read-side API client for POS Service's aggregated reporting endpoints.
///
/// Same plain-Dio shape as `PosApiService` — reporting is inherently online
/// (aggregates compute server-side per request), so there is no cache or
/// offline queue here: every call requires connectivity. All four endpoints
/// require `reports.view`.
library;

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';

import '../constants/api_paths.dart';
import '../constants/app_limits.dart';

/// One calendar day of takings.
class DailyTakingsDayDto {
  final DateTime date;
  final Decimal revenue;
  final int salesCount;
  final Decimal avgTicket;
  final int voidedCount;
  final int refundedCount;

  DailyTakingsDayDto({
    required this.date,
    required this.revenue,
    required this.salesCount,
    required this.avgTicket,
    required this.voidedCount,
    required this.refundedCount,
  });

  factory DailyTakingsDayDto.fromJson(Map<String, dynamic> json) =>
      DailyTakingsDayDto(
        date: DateTime.parse(json['date'] as String),
        revenue: Decimal.parse(json['revenue'].toString()),
        salesCount: json['sales_count'] as int,
        avgTicket: Decimal.parse(json['avg_ticket'].toString()),
        voidedCount: json['voided_count'] as int,
        refundedCount: json['refunded_count'] as int,
      );
}

/// One menu item's share of sales. Names are NOT resolved here — `itemId`
/// is Inventory Service's key and the app joins its catalog.
class ItemMixLineDto {
  final String itemId;
  final Decimal quantity;
  final Decimal revenue;
  final int lines;

  ItemMixLineDto({
    required this.itemId,
    required this.quantity,
    required this.revenue,
    required this.lines,
  });

  factory ItemMixLineDto.fromJson(Map<String, dynamic> json) => ItemMixLineDto(
        itemId: json['item_id'] as String,
        quantity: Decimal.parse(json['quantity'].toString()),
        revenue: Decimal.parse(json['revenue'].toString()),
        lines: json['lines'] as int,
      );
}

/// One actor's sales in the window. A null [actorId] is the explicit
/// unknown bucket (sales without attributable staff), not missing data.
class StaffPerformanceLineDto {
  final String? actorId;
  final int salesCount;
  final Decimal revenue;
  final int voidedCount;
  final int refundedCount;

  StaffPerformanceLineDto({
    this.actorId,
    required this.salesCount,
    required this.revenue,
    required this.voidedCount,
    required this.refundedCount,
  });

  factory StaffPerformanceLineDto.fromJson(Map<String, dynamic> json) =>
      StaffPerformanceLineDto(
        actorId: json['actor_id'] as String?,
        salesCount: json['sales_count'] as int,
        revenue: Decimal.parse(json['revenue'].toString()),
        voidedCount: json['voided_count'] as int,
        refundedCount: json['refunded_count'] as int,
      );
}

class FinanceCategoryTotalDto {
  final String category;
  final Decimal total;

  FinanceCategoryTotalDto({required this.category, required this.total});

  factory FinanceCategoryTotalDto.fromJson(Map<String, dynamic> json) =>
      FinanceCategoryTotalDto(
        category: json['category'] as String,
        total: Decimal.parse(json['total'].toString()),
      );
}

/// Money in vs money out: sales revenue plus ad-hoc incomes minus expenses.
class FinanceSummaryDto {
  final Decimal salesRevenue;
  final Decimal incomeTotal;
  final Decimal expenseTotal;
  final Decimal net;
  final List<FinanceCategoryTotalDto> expensesByCategory;
  final List<FinanceCategoryTotalDto> incomesByCategory;

  FinanceSummaryDto({
    required this.salesRevenue,
    required this.incomeTotal,
    required this.expenseTotal,
    required this.net,
    required this.expensesByCategory,
    required this.incomesByCategory,
  });

  factory FinanceSummaryDto.fromJson(Map<String, dynamic> json) =>
      FinanceSummaryDto(
        salesRevenue: Decimal.parse(json['sales_revenue'].toString()),
        incomeTotal: Decimal.parse(json['income_total'].toString()),
        expenseTotal: Decimal.parse(json['expense_total'].toString()),
        net: Decimal.parse(json['net'].toString()),
        expensesByCategory: (json['expenses_by_category'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(FinanceCategoryTotalDto.fromJson)
            .toList(),
        incomesByCategory: (json['incomes_by_category'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(FinanceCategoryTotalDto.fromJson)
            .toList(),
      );
}

/// Thrown when POS Service rejects a reports read with a domain-specific
/// error — callers can show [message] directly.
class PosReportsApiException implements Exception {
  final String message;
  final int? statusCode;

  PosReportsApiException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'PosReportsApiException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

class PosReportsApiService {
  const PosReportsApiService({required this._dio});

  final Dio _dio;

  Never _rethrowAsReportsError(DioException e) {
    final detail = e.response?.data is Map
        ? (e.response?.data as Map)['detail']
        : null;
    throw PosReportsApiException(
      detail?.toString() ?? e.message ?? 'Request failed',
      e.response?.statusCode,
    );
  }

  Map<String, dynamic> _window(DateTime? from, DateTime? to) => {
        if (from != null) 'from_date': from.toIso8601String(),
        if (to != null) 'to_date': to.toIso8601String(),
      };

  /// Per-day revenue, ticket count, average ticket, void/refund counts.
  Future<List<DailyTakingsDayDto>> fetchDailyTakings({
    required String businessId,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await _dio.get(
        PosApiPaths.dailyTakings(businessId),
        queryParameters: _window(from, to),
      );
      return ((response.data as Map<String, dynamic>)['days'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(DailyTakingsDayDto.fromJson)
          .toList();
    } on DioException catch (e) {
      _rethrowAsReportsError(e);
    }
  }

  /// Per-item quantity, revenue and line counts, top revenue first.
  Future<List<ItemMixLineDto>> fetchItemMix({
    required String businessId,
    DateTime? from,
    DateTime? to,
    int limit = AppLimits.reportsItemMixLimit,
  }) async {
    try {
      final response = await _dio.get(
        PosApiPaths.itemMix(businessId),
        queryParameters: {..._window(from, to), 'limit': limit},
      );
      return ((response.data as Map<String, dynamic>)['lines'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(ItemMixLineDto.fromJson)
          .toList();
    } on DioException catch (e) {
      _rethrowAsReportsError(e);
    }
  }

  /// Per-actor sales counts, revenue and void/refund counts.
  Future<List<StaffPerformanceLineDto>> fetchStaffPerformance({
    required String businessId,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await _dio.get(
        PosApiPaths.staffPerformance(businessId),
        queryParameters: _window(from, to),
      );
      return ((response.data as Map<String, dynamic>)['lines'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(StaffPerformanceLineDto.fromJson)
          .toList();
    } on DioException catch (e) {
      _rethrowAsReportsError(e);
    }
  }

  /// Sales revenue plus ad-hoc incomes minus expenses, with per-category
  /// splits.
  Future<FinanceSummaryDto> fetchFinanceSummary({
    required String businessId,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await _dio.get(
        PosApiPaths.financeSummary(businessId),
        queryParameters: _window(from, to),
      );
      return FinanceSummaryDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _rethrowAsReportsError(e);
    }
  }
}
