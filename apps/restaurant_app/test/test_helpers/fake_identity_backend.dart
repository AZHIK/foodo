/// A hand-rolled fake for the identity-service backend, used only in tests.
///
/// [AuthNotifier]/[IdentityServiceApi] talk to a real backend in the running
/// app (see `identityServiceDioProvider`), so widget tests that exercise the
/// OTP flow need something to answer those calls without a live server.
/// Implementing Dio's [HttpClientAdapter] directly avoids pulling in a mocking
/// package for what is a handful of canned JSON responses.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// The only code [FakeIdentityAdapter] accepts as correct.
const fakeOtpCode = '111111';

/// Builds an unsigned (test-only) JWT with the given claims — the app never
/// verifies the signature client-side (see `jwt_decoder.dart`), only decodes
/// the payload, so this is enough to round-trip `sub`/`exp`.
String _fakeJwt(Map<String, dynamic> claims) {
  String segment(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${segment({
        'alg': 'none',
      })}.${segment(claims)}.fake-signature';
}

class FakeIdentityBackendState {
  FakeIdentityBackendState();

  /// The name returned by onboarding-status — non-empty by default so tests
  /// that aren't specifically about the "complete your profile" step don't
  /// get routed there. Set to '' to exercise that path.
  String fullName = 'Test User';
  String? email;
  bool needsOnboarding = true;
  String? businessId;
  String? businessName;
}

class FakeIdentityAdapter implements HttpClientAdapter {
  FakeIdentityAdapter(this.state);

  final FakeIdentityBackendState state;

  ResponseBody _json(Object? body, int statusCode) {
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    final data = options.data;
    final body = data is Map ? data : <String, dynamic>{};

    if (options.method == 'POST' && path.endsWith('/auth/otp/request')) {
      return _json(null, 204);
    }

    if (options.method == 'POST' && path.endsWith('/auth/otp/verify')) {
      if (body['code'] != fakeOtpCode) {
        return _json({'detail': 'Invalid or expired code'}, 401);
      }
      final now = DateTime.now().toUtc();
      final token = _fakeJwt({
        'sub': 'fake-user-id',
        'exp': now.add(const Duration(minutes: 15)).millisecondsSinceEpoch ~/ 1000,
        'user_category': 'business_user',
      });
      return _json({
        'access_token': token,
        'refresh_token': 'fake-refresh-token',
        'token_type': 'bearer',
      }, 200);
    }

    if (options.method == 'GET' && path.endsWith('/users/me/onboarding-status')) {
      return _json({
        'needs_onboarding': state.needsOnboarding,
        'business_id': state.businessId,
        'business_name': state.businessName,
        'full_name': state.fullName,
        'email': state.email,
      }, 200);
    }

    if (options.method == 'PATCH' && path.endsWith('/users/me')) {
      state.fullName = body['full_name'] as String? ?? state.fullName;
      state.email = body['email'] as String?;
      return _json({'full_name': state.fullName, 'email': state.email}, 200);
    }

    return _json({'detail': 'Not found (fake backend): $path'}, 404);
  }

  @override
  void close({bool force = false}) {}
}
