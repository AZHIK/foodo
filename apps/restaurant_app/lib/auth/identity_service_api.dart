/// HTTP client for Identity Service endpoints.
///
/// Handles OTP login, token refresh, business creation, and store lookups.
/// Verified against the live identity-service backend.
library;

import 'package:dio/dio.dart';
import 'auth_dtos.dart';

/// Calls Identity Service endpoints via Dio.
class IdentityServiceApi {
  final Dio _dio;

  IdentityServiceApi({required Dio dio}) : _dio = dio;

  /// POST /auth/otp/request - Request an OTP code for a phone number.
  /// Returns void (204 No Content response from backend).
  Future<void> requestOtp(String phone) async {
    try {
      await _dio.post(
        '/auth/otp/request',
        data: OtpRequestInput(phone: phone).toJson(),
      );
    } on DioException catch (e) {
      throw AuthException('OTP request failed: ${e.message}', e.response?.statusCode);
    }
  }

  /// POST /auth/otp/verify - Verify OTP code and get tokens.
  Future<TokenResponse> verifyOtp({
    required String phone,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/otp/verify',
        data: OtpVerifyInput(phone: phone, code: code).toJson(),
      );
      return TokenResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException('OTP verify failed: ${e.message}', e.response?.statusCode);
    }
  }

  /// GET /users/me/onboarding-status - Check onboarding status (requires bearer token).
  Future<OnboardingStatusOutput> getOnboardingStatus(String bearerToken) async {
    try {
      final response = await _dio.get(
        '/users/me/onboarding-status',
        options: Options(
          headers: {'Authorization': 'Bearer $bearerToken'},
        ),
      );
      return OnboardingStatusOutput.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException(
        'Onboarding status check failed: ${e.message}',
        e.response?.statusCode,
      );
    }
  }

  /// PATCH /users/me - Set the caller's own name/email (requires bearer token).
  Future<UpdateProfileOutput> updateProfile({
    required UpdateProfileInput input,
    required String bearerToken,
  }) async {
    try {
      final response = await _dio.patch(
        '/users/me',
        data: input.toJson(),
        options: Options(
          headers: {'Authorization': 'Bearer $bearerToken'},
        ),
      );
      return UpdateProfileOutput.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException(
        'Profile update failed: ${e.message}',
        e.response?.statusCode,
      );
    }
  }

  /// POST /auth/refresh - Refresh access token using refresh token.
  /// Note: the backend rotates the refresh token; the returned refresh_token is new.
  Future<TokenResponse> refreshAccessToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: TokenRefreshInput(refreshToken: refreshToken).toJson(),
      );
      return TokenResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException('Token refresh failed: ${e.message}', e.response?.statusCode);
    }
  }

  /// POST /auth/context/switch - Scope token to a business (requires bearer token).
  Future<TokenResponse> switchContext({
    required String businessId,
    required String bearerToken,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/context/switch',
        data: ContextSwitchInput(businessId: businessId).toJson(),
        options: Options(
          headers: {'Authorization': 'Bearer $bearerToken'},
        ),
      );
      return TokenResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException(
        'Context switch failed: ${e.message}',
        e.response?.statusCode,
      );
    }
  }

  /// POST /api/v1/businesses - Create a new business (requires bearer token).
  Future<BusinessCreateOutput> createBusiness({
    required BusinessCreateInput input,
    required String bearerToken,
  }) async {
    try {
      final response = await _dio.post(
        '/businesses',
        data: input.toJson(),
        options: Options(
          headers: {'Authorization': 'Bearer $bearerToken'},
        ),
      );
      return BusinessCreateOutput.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException(
        'Business creation failed: ${e.message}',
        e.response?.statusCode,
      );
    }
  }

  /// GET /api/v1/businesses/{businessId}/stores - List stores for a business.
  Future<List<StoreDto>> listStores({
    required String businessId,
    required String bearerToken,
  }) async {
    try {
      final response = await _dio.get(
        '/businesses/$businessId/stores',
        options: Options(
          headers: {'Authorization': 'Bearer $bearerToken'},
        ),
      );
      final items = (response.data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((item) => StoreDto.fromJson(item))
          .toList();
      return items;
    } on DioException catch (e) {
      throw AuthException(
        'Store list failed: ${e.message}',
        e.response?.statusCode,
      );
    }
  }
}

/// Auth operation error.
class AuthException implements Exception {
  final String message;
  final int? statusCode;

  AuthException(this.message, [this.statusCode]);

  /// Builds from a failed Dio call, preferring the backend's own `detail`
  /// string over Dio's generic "Http status error [409]" — so a caller
  /// surfacing this to the UI shows what the backend actually said, not an
  /// invented paraphrase of it.
  factory AuthException.fromDio(String action, DioException e) {
    final data = e.response?.data;
    final detail = data is Map && data['detail'] is String
        ? data['detail'] as String
        : null;
    return AuthException('$action: ${detail ?? e.message}', e.response?.statusCode);
  }

  @override
  String toString() =>
      'AuthException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}
