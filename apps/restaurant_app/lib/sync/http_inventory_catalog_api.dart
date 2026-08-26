/// HTTP implementation of the inventory catalog API using Dio.
///
/// Calls the real Inventory Service `/businesses/{business_id}/items` endpoint.
/// Requires bearer token auth from the session.
library;

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'inventory_catalog_api.dart';

/// HTTP client for fetching catalog items from Inventory Service via Dio.
class HttpInventoryCatalogApi extends InventoryCatalogApi {
  final Dio _dio;
  final String _businessId;
  final String _bearerToken;

  HttpInventoryCatalogApi({
    required Dio dio,
    required String businessId,
    required String bearerToken,
  })  : _dio = dio,
        _businessId = businessId,
        _bearerToken = bearerToken;

  @override
  Future<List<CatalogItemDto>> fetchItems({
    required String businessLocationId,
  }) async {
    try {
      final response = await _dio.get(
        '/businesses/$_businessId/items',
        queryParameters: {
          'business_location_id': businessLocationId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_bearerToken',
          },
        ),
      );

      final items = (response.data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((item) => CatalogItemDto(
            id: item['id'] as String,
            businessId: item['business_id'] as String,
            businessLocationId: item['business_location_id'] as String,
            name: item['name'] as String,
            unitOfMeasure: item['unit_of_measure'] as String,
            category: item['category'] as String?,
            reorderThreshold: Decimal.parse(item['reorder_threshold'].toString()),
            reorderQuantity: Decimal.parse(item['reorder_quantity'].toString()),
            sellingPrice: item['selling_price'] != null
                ? Decimal.parse(item['selling_price'].toString())
                : null,
            allowNegativeStock: item['allow_negative_stock'] as bool? ?? false,
            itemType: item['item_type'] as String,
            createdAt: DateTime.parse(item['created_at'] as String),
            updatedAt: DateTime.parse(item['updated_at'] as String),
          ))
          .toList();

      return items;
    } on DioException catch (e) {
      throw CatalogFetchException(
        'Catalog fetch failed: ${e.message}',
        e.response?.statusCode,
      );
    }
  }
}

/// Catalog fetch error for debugging.
class CatalogFetchException implements Exception {
  final String message;
  final int? statusCode;

  CatalogFetchException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'CatalogFetchException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}
