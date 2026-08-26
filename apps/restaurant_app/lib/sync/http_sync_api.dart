/// HTTP implementation of the POS sync API using Dio.
///
/// Calls the real POS Service `/businesses/{business_id}/sales/sync` endpoint.
/// Requires bearer token auth from the session.
library;

import 'package:dio/dio.dart';
import 'pos_sync_api.dart';
import 'sync_dtos.dart';

/// HTTP client for syncing sales to POS Service via Dio.
class HttpSyncApi extends PosSyncApi {
  final Dio _dio;
  final String _businessId;
  final String _bearerToken;

  HttpSyncApi({
    required Dio dio,
    required String businessId,
    required String bearerToken,
  })  : _dio = dio,
        _businessId = businessId,
        _bearerToken = bearerToken;

  @override
  Future<SyncBatchResult> syncSales(List<PendingSaleDto> batch) async {
    try {
      final response = await _dio.post(
        '/businesses/$_businessId/sales/sync',
        data: {
          'sales': batch.map((s) => s.toJson()).toList(),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_bearerToken',
          },
        ),
      );

      final results = (response.data['results'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((r) => SyncRowResult(
            clientSaleId: r['client_sale_id'] as String,
            status: r['status'] as String, // created|duplicate|failed
            reason: r['reason'] as String?,
          ))
          .toList();

      return SyncBatchResult(results: results);
    } on DioException catch (e) {
      throw HttpException(
        'Sync failed: ${e.message}',
        e.response?.statusCode,
      );
    }
  }
}

/// HTTP error for debugging.
class HttpException implements Exception {
  final String message;
  final int? statusCode;

  HttpException(this.message, [this.statusCode]);

  @override
  String toString() => 'HttpException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}
