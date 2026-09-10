/// Write-side API client for Inventory Service — reorder create/receive/cancel.
///
/// Matches `InventoryApiService`'s convention: a plain Dio-wrapping class,
/// no offline/demo mode — every call here requires connectivity.
library;

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';

import '../sync/reorders_catalog_api.dart' show ReorderDto;

/// Thrown when the backend rejects a reorder write — a sellable-item
/// rejection, an already-received/cancelled conflict, etc. Callers can show
/// [message] directly.
class ReorderApiException implements Exception {
  final String message;
  final int? statusCode;

  ReorderApiException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'ReorderApiException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

class ReorderApiService {
  const ReorderApiService({required this._dio});

  final Dio _dio;

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

  Never _rethrowAsReorderError(DioException e) {
    final detail = e.response?.data is Map ? (e.response?.data as Map)['detail'] : null;
    throw ReorderApiException(
      detail?.toString() ?? e.message ?? 'Request failed',
      e.response?.statusCode,
    );
  }

  /// Places a new reorder. Requires `reorders.create`.
  Future<ReorderDto> createReorder({
    required String businessId,
    required String storeId,
    required String itemId,
    required String supplierId,
    required Decimal quantity,
    required Decimal unitCost,
    String? notes,
    DateTime? expectedAt,
  }) async {
    try {
      final response = await _dio.post(
        '/businesses/$businessId/reorders',
        data: {
          'store_id': storeId,
          'item_id': itemId,
          'supplier_id': supplierId,
          'quantity': quantity.toString(),
          'unit_cost': unitCost.toString(),
          if (notes != null) 'notes': notes,
          if (expectedAt != null) 'expected_at': expectedAt.toIso8601String(),
        },
      );
      return _reorderFromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _rethrowAsReorderError(e);
    }
  }

  /// Marks a pending reorder received — adds its quantity to stock via the
  /// backend's stock-movement engine. Requires `reorders.receive`.
  Future<ReorderDto> receiveReorder({
    required String businessId,
    required String reorderId,
  }) async {
    try {
      final response = await _dio.post('/businesses/$businessId/reorders/$reorderId/receive');
      return _reorderFromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _rethrowAsReorderError(e);
    }
  }

  /// Cancels a pending reorder. Requires `reorders.cancel`.
  Future<ReorderDto> cancelReorder({
    required String businessId,
    required String reorderId,
  }) async {
    try {
      final response = await _dio.post('/businesses/$businessId/reorders/$reorderId/cancel');
      return _reorderFromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _rethrowAsReorderError(e);
    }
  }
}
