/// Write-side API client for Inventory Service — supplier CRUD.
///
/// Matches `InventoryApiService`'s convention: a plain Dio-wrapping class,
/// no offline/demo mode — every call here requires connectivity.
library;

import 'package:dio/dio.dart';

import '../sync/suppliers_catalog_api.dart' show SupplierDto;

/// Thrown when the backend rejects a supplier write.
class SupplierApiException implements Exception {
  final String message;
  final int? statusCode;

  SupplierApiException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'SupplierApiException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

class SupplierApiService {
  const SupplierApiService({required this._dio});

  final Dio _dio;

  SupplierDto _supplierFromJson(Map<String, dynamic> s) => SupplierDto(
        id: s['id'] as String,
        businessId: s['business_id'] as String,
        name: s['name'] as String,
        phone: s['phone'] as String?,
        email: s['email'] as String?,
        addressLine1: s['address_line1'] as String?,
        notes: s['notes'] as String?,
        updatedAt: DateTime.parse(s['updated_at'] as String),
        isDeleted: false,
        createdAt: DateTime.parse(s['created_at'] as String),
      );

  Never _rethrowAsSupplierError(DioException e) {
    final detail = e.response?.data is Map ? (e.response?.data as Map)['detail'] : null;
    throw SupplierApiException(
      detail?.toString() ?? e.message ?? 'Request failed',
      e.response?.statusCode,
    );
  }

  /// Creates a new supplier. Requires `suppliers.create`.
  Future<SupplierDto> createSupplier({
    required String businessId,
    required String name,
    String? phone,
    String? email,
    String? addressLine1,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/businesses/$businessId/suppliers',
        data: {
          'name': name,
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
          if (addressLine1 != null) 'address_line1': addressLine1,
          if (notes != null) 'notes': notes,
        },
      );
      return _supplierFromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _rethrowAsSupplierError(e);
    }
  }

  /// Updates mutable fields on a supplier (partial update). Requires
  /// `suppliers.update`. Only non-null parameters are sent.
  Future<SupplierDto> updateSupplier({
    required String businessId,
    required String supplierId,
    String? name,
    String? phone,
    String? email,
    String? addressLine1,
    String? notes,
  }) async {
    try {
      final response = await _dio.patch(
        '/businesses/$businessId/suppliers/$supplierId',
        data: {
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
          if (addressLine1 != null) 'address_line1': addressLine1,
          if (notes != null) 'notes': notes,
        },
      );
      return _supplierFromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _rethrowAsSupplierError(e);
    }
  }

  /// Soft-deletes a supplier. Requires `suppliers.delete`.
  Future<void> deleteSupplier({
    required String businessId,
    required String supplierId,
  }) async {
    try {
      await _dio.delete('/businesses/$businessId/suppliers/$supplierId');
    } on DioException catch (e) {
      _rethrowAsSupplierError(e);
    }
  }
}
