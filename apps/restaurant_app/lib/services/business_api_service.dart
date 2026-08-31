import 'package:dio/dio.dart';

import '../auth/auth_dtos.dart' show BusinessReadDto, BusinessUpdateInput;

/// API client for business operations.
///
/// Handles CRUD operations for business data including:
/// - Getting business details
/// - Updating business information
/// - Managing business settings
///
/// All operations are authenticated and require a valid access token.
class BusinessApiService {
  const BusinessApiService({required Dio dio}) : _dio = dio;

  final Dio _dio;
  static const _apiPrefix = '/businesses';

  /// Get details for a specific business.
  ///
  /// Requires an active business context in the authentication token.
  Future<BusinessReadDto> getBusiness({
    required String businessId,
  }) async {
    try {
      final response = await _dio.get('$_apiPrefix/$businessId');
      return BusinessReadDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Update business information (partial update).
  ///
  /// Only fields present in the input are updated.
  /// Requires [BUSINESSES_UPDATE] permission.
  Future<BusinessReadDto> updateBusiness({
    required String businessId,
    required BusinessUpdateInput input,
  }) async {
    try {
      final response = await _dio.patch(
        '$_apiPrefix/$businessId',
        data: input.toJson(),
      );
      return BusinessReadDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }
}
