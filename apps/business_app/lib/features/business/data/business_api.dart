import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/dio_failure_mapper.dart';
import '../domain/business_create_request.dart';
import '../domain/business_create_response.dart';

/// Client for the Identity Service business endpoints.
///
/// Business creation lives on the Identity Service (`POST /businesses`),
/// so this uses the same [dioProvider] as the auth client. Methods throw
/// the app-wide [Failure] sealed type on error.
abstract class BusinessApi {
  /// Creates a business on behalf of the authenticated caller and assigns
  /// them the platform's protected owner role.
  Future<BusinessCreateResult> createBusiness(BusinessCreateRequest request);
}

class BusinessApiImpl implements BusinessApi {
  BusinessApiImpl(this._dio);

  final Dio _dio;

  @override
  Future<BusinessCreateResult> createBusiness(
    BusinessCreateRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/api/v1/businesses',
        data: request.toJson(),
      );
      return BusinessCreateResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    } on FormatException catch (e) {
      throw Failure.unknown(message: 'Malformed business response.', error: e);
    } on TypeError catch (e) {
      throw Failure.unknown(
        message: 'Unexpected business response shape.',
        error: e,
      );
    }
  }
}

/// App-wide [BusinessApi] instance backed by the shared [ApiClient] Dio.
final businessApiProvider = Provider<BusinessApi>((ref) {
  return BusinessApiImpl(ref.watch(dioProvider));
});
