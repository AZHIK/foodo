import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/dio_failure_mapper.dart';

/// Result of a successful OTP verification.
class OtpVerificationResult {
  const OtpVerificationResult({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
  });

  final String userId;
  final String accessToken;
  final String refreshToken;
}

/// Result of the onboarding status check.
class OnboardingStatusResult {
  const OnboardingStatusResult({
    required this.needsOnboarding,
    this.businessId,
    this.businessName,
  });

  /// Whether the user needs to complete business onboarding.
  final bool needsOnboarding;

  /// The business ID if the user already belongs to a business (null if needs onboarding).
  final String? businessId;

  /// The business name if the user already belongs to a business (null if needs onboarding).
  final String? businessName;
}

/// Client for the Identity Service OTP endpoints.
///
/// Methods throw the app-wide [Failure] sealed type on error so callers
/// (e.g. [AuthNotifier]) handle them with pattern matching.
abstract class IdentityApi {
  /// Requests a one-time code be sent to [phone].
  Future<void> requestOtp(String phone);

  /// Verifies [code] for [phone] and returns fresh tokens plus the
  /// verified user's id (from the JWT `sub` claim).
  Future<OtpVerificationResult> verifyOtp(String phone, String code);

  /// Returns the onboarding status for the authenticated caller.
  ///
  /// This is the source of truth the boot path re-checks on every restart,
  /// so a mid-onboarding kill is never resumed from a stale local flag.
  /// Returns [OnboardingStatusResult] with needsOnboarding, businessId, and businessName.
  Future<OnboardingStatusResult> fetchOnboardingStatus();

  /// Exchanges a stored refresh token for a fresh access token and a
  /// rotated refresh token.
  ///
  /// The backend rotates refresh tokens on every use, so the caller must
  /// persist the returned `refreshToken`.
  Future<OtpVerificationResult> refreshAccessToken(String refreshToken);

  /// Scopes the caller's session to [businessId] (`POST /auth/context/switch`).
  ///
  /// OTP-verify and refresh only ever issue unscoped tokens
  /// (`active_business_id=None`, empty `roles`/`permissions`); this is the
  /// only way to obtain a business-scoped access token, which any
  /// business-scoped endpoint requires. The response also carries a rotated
  /// refresh token that the caller must persist.
  Future<OtpVerificationResult> switchBusinessContext(String businessId);
}

class IdentityApiImpl implements IdentityApi {
  IdentityApiImpl(this._dio);

  final Dio _dio;

  @override
  Future<void> requestOtp(String phone) async {
    try {
      await _dio.post('/api/v1/auth/otp/request', data: {'phone': phone});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<OtpVerificationResult> verifyOtp(String phone, String code) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/otp/verify',
        data: {'phone': phone, 'code': code},
      );
      return _parseTokenResponse(response);
    } on DioException catch (e) {
      throw mapDioException(e);
    } on FormatException catch (e) {
      throw Failure.unknown(message: 'Malformed token response.', error: e);
    } on TypeError catch (e) {
      throw Failure.unknown(
        message: 'Unexpected token response shape.',
        error: e,
      );
    }
  }

  @override
  Future<OnboardingStatusResult> fetchOnboardingStatus() async {
    try {
      final response = await _dio.get('/api/v1/users/me/onboarding-status');
      final body = response.data as Map<String, dynamic>;
      final needs = body['needs_onboarding'];
      if (needs is! bool) {
        throw const FormatException(
          'onboarding-status response has no needs_onboarding flag.',
        );
      }
      final businessId = body['business_id'] as String?;
      final businessName = body['business_name'] as String?;
      return OnboardingStatusResult(
        needsOnboarding: needs,
        businessId: businessId,
        businessName: businessName,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    } on FormatException catch (e) {
      throw Failure.unknown(
        message: 'Malformed onboarding-status response.',
        error: e,
      );
    } on TypeError catch (e) {
      throw Failure.unknown(
        message: 'Unexpected onboarding-status response shape.',
        error: e,
      );
    }
  }

  @override
  Future<OtpVerificationResult> refreshAccessToken(
    String refreshToken,
  ) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      return _parseTokenResponse(response);
    } on DioException catch (e) {
      throw mapDioException(e);
    } on FormatException catch (e) {
      throw Failure.unknown(message: 'Malformed token response.', error: e);
    } on TypeError catch (e) {
      throw Failure.unknown(
        message: 'Unexpected token response shape.',
        error: e,
      );
    }
  }

  @override
  Future<OtpVerificationResult> switchBusinessContext(
    String businessId,
  ) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/context/switch',
        data: {'business_id': businessId},
      );
      return _parseTokenResponse(response);
    } on DioException catch (e) {
      throw mapDioException(e);
    } on FormatException catch (e) {
      throw Failure.unknown(
        message: 'Malformed context-switch response.',
        error: e,
      );
    } on TypeError catch (e) {
      throw Failure.unknown(
        message: 'Unexpected context-switch response shape.',
        error: e,
      );
    }
  }
}

/// App-wide [IdentityApi] instance backed by the shared [ApiClient] Dio.
final identityApiProvider = Provider<IdentityApi>((ref) {
  return IdentityApiImpl(ref.watch(dioProvider));
});

OtpVerificationResult _parseTokenResponse(Response<dynamic> response) {
  final body = response.data as Map<String, dynamic>;
  final accessToken = body['access_token'] as String;
  final refreshToken = body['refresh_token'] as String;

  return OtpVerificationResult(
    userId: _userIdFromAccessToken(accessToken),
    accessToken: accessToken,
    refreshToken: refreshToken,
  );
}

String _userIdFromAccessToken(String token) {
  final segments = token.split('.');
  if (segments.length != 3) {
    throw const FormatException('Access token is not a JWT.');
  }

  final payload =
      utf8.decode(base64Url.decode(base64Url.normalize(segments[1])));
  final claims = jsonDecode(payload) as Map<String, dynamic>;
  final sub = claims['sub'];
  if (sub is! String || sub.isEmpty) {
    throw const FormatException('JWT payload has no sub claim.');
  }
  return sub;
}
