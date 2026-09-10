/// Write-side API client for POS Service — void/refund on an already-synced
/// sale.
///
/// Unlike `sync/http_sync_api.dart` (which pushes new sales through the
/// offline outbox), void/refund goes straight through this plain
/// Dio-wrapping class, matching `InventoryApiService` — there is no
/// offline-first queue for it (see `pending_voids_refunds.dart`'s doc
/// comment for why): every call here requires connectivity.
library;

import 'package:dio/dio.dart';

/// Thrown when POS Service rejects a void/refund with a domain-specific
/// error (already voided/refunded, sale not found, validation).
class PosApiException implements Exception {
  final String message;
  final int? statusCode;

  PosApiException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'PosApiException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

class PosApiService {
  const PosApiService({required this._dio});

  final Dio _dio;

  /// Voids or refunds an already-completed sale. Requires `pos.refund` —
  /// the backend gates both actions behind the same permission, there is no
  /// separate `pos.void`. [clientActionId] is a fresh UUID per call, the
  /// idempotency key for this specific action (distinct from the sale's own
  /// `client_sale_id`).
  Future<void> voidOrRefund({
    required String businessId,
    required String saleId,
    required String clientActionId,
    required String newStatus, // 'voided' | 'refunded'
    required String reason,
  }) async {
    try {
      await _dio.post(
        '/businesses/$businessId/sales/$saleId/void-or-refund',
        data: {
          'client_action_id': clientActionId,
          'new_status': newStatus,
          'reason': reason,
        },
      );
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response?.data as Map)['detail']
          : null;
      throw PosApiException(
        detail?.toString() ?? e.message ?? 'Request failed',
        e.response?.statusCode,
      );
    }
  }
}
