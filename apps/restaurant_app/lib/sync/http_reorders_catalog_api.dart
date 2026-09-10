/// HTTP implementation of the reorders catalog API using Dio.
///
/// Calls Inventory Service's real `/businesses/{business_id}/reorders`
/// list endpoint, filtered to one store.
library;

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';

import 'reorders_catalog_api.dart';

const _pageSize = 100;

/// HTTP client for fetching reorders from Inventory Service via Dio.
class HttpReordersCatalogApi extends ReordersCatalogApi {
  final Dio _dio;
  final String _businessId;

  HttpReordersCatalogApi({required Dio dio, required String businessId})
      : _dio = dio,
        _businessId = businessId;

  @override
  Future<List<ReorderDto>> fetchReorders({required String storeId}) async {
    try {
      final reorders = <ReorderDto>[];
      var offset = 0;
      while (true) {
        final response = await _dio.get(
          '/businesses/$_businessId/reorders',
          queryParameters: {
            'store_id': storeId,
            'limit': _pageSize,
            'offset': offset,
          },
        );
        final page =
            (response.data['items'] as List<dynamic>).cast<Map<String, dynamic>>();
        reorders.addAll(page.map(_reorderFromJson));
        if (page.length < _pageSize) break;
        offset += _pageSize;
      }
      return reorders;
    } on DioException catch (e) {
      throw ReordersFetchException(
        'Reorders fetch failed: ${e.message}',
        e.response?.statusCode,
      );
    }
  }

  ReorderDto _reorderFromJson(Map<String, dynamic> r) => ReorderDto(
        id: r['id'] as String,
        businessId: r['business_id'] as String,
        storeId: r['store_id'] as String,
        itemId: r['item_id'] as String,
        supplierId: r['supplier_id'] as String,
        quantity: Decimal.parse(r['quantity'].toString()),
        unit: r['unit'] as String,
        unitCost: Decimal.parse(r['unit_cost'].toString()),
        status: r['status'] as String,
        notes: r['notes'] as String?,
        orderedAt: DateTime.parse(r['ordered_at'] as String),
        orderedBy: r['ordered_by'] as String?,
        expectedAt:
            r['expected_at'] != null ? DateTime.parse(r['expected_at'] as String) : null,
        receivedAt:
            r['received_at'] != null ? DateTime.parse(r['received_at'] as String) : null,
        receivedBy: r['received_by'] as String?,
        cancelledAt:
            r['cancelled_at'] != null ? DateTime.parse(r['cancelled_at'] as String) : null,
        cancelledBy: r['cancelled_by'] as String?,
        createdAt: DateTime.parse(r['created_at'] as String),
      );
}

/// Reorders fetch error for debugging.
class ReordersFetchException implements Exception {
  final String message;
  final int? statusCode;

  ReordersFetchException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'ReordersFetchException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}
