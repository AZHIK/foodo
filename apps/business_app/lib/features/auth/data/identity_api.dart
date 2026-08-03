import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/network/api_client.dart';

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
}

class IdentityApiImpl implements IdentityApi {
  IdentityApiImpl(this._dio);

  final Dio _dio;

  @override
  Future<void> requestOtp(String phone) async {
    try {
      await _dio.post('/api/v1/auth/otp/request', data: {'phone': phone});
    } on DioException catch (e) {
      throw _mapDioException(e);
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
      throw _mapDioException(e);
    } on FormatException catch (e) {
      throw Failure.unknown(message: 'Malformed token response.', error: e);
    } on TypeError catch (e) {
      throw Failure.unknown(
        message: 'Unexpected token response shape.',
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

Failure _mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return Failure.network(message: e.message);
    default:
      final status = e.response?.statusCode;
      if (status == 400 || status == 422) {
        return Failure.validation(message: _detail(e));
      }
      if (status == 401) {
        return const Failure.auth(message: 'Unauthorized.');
      }
      return Failure.network(statusCode: status, message: _detail(e));
  }
}

String _detail(DioException e) {
  final data = e.response?.data;
  if (data is Map<String, dynamic> && data['detail'] is String) {
    return data['detail'] as String;
  }
  return e.message ?? 'Request failed.';
}
