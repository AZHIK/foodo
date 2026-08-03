import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'api_endpoints.dart';
import 'token_store.dart';

/// Singleton [Dio] HTTP client with auth interceptors.
///
/// Features:
/// - Automatic auth header injection from the active session's access token
/// - Silent token refresh on 401 responses
/// - Retry logic for transient network errors
class ApiClient {
  ApiClient._();

  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;

  late final Dio dio = _createDio();

  Dio _createDio() {
    final baseUrl = dotenv.env['IDENTITY_BASE_URL'] ?? ApiEndpoints.identityBase;

    final d = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Auth header interceptor - injects the active session's access token
    d.interceptors.add(
      AuthHeaderInterceptor(() => TokenStore.instance.accessToken),
    );

    // Token refresh interceptor - retries on 401 with refresh token
    d.interceptors.add(
      TokenRefreshInterceptor(d, _attemptTokenRefresh),
    );

    // Retry interceptor for transient network errors
    d.interceptors.add(RetryInterceptor(d));

    return d;
  }

  Future<bool> _attemptTokenRefresh() async {
    try {
      // This would need access to the current user's refresh token
      // For now, return false to let the 401 propagate
      // Full implementation requires integration with AuthNotifier
      return false;
    } catch (_) {
      return false;
    }
  }
}

/// Injects `Authorization: Bearer <token>` on every request while a session
/// access token is available.
///
/// The token is read through an injected getter so the interceptor is
/// trivially testable; the real app wires it to [TokenStore.instance].
class AuthHeaderInterceptor extends Interceptor {
  AuthHeaderInterceptor(this._accessToken);

  final String? Function() _accessToken;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _accessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Retries a failed request once after a 401 by triggering a token refresh
/// and replaying the original request on success.
///
/// [refresh] performs the actual refresh (token exchange + persistence).
/// It is injected so tests can stub the outcome; the real app wires
/// [ApiClient._attemptTokenRefresh].
class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor(this._dio, this._refresh);

  final Dio _dio;
  final Future<bool> Function() _refresh;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        err.requestOptions.path != '/api/v1/auth/refresh') {
      final refreshed = await _refresh();
      if (refreshed) {
        // Retry the original request
        try {
          final response = await _dio.fetch(err.requestOptions);
          handler.resolve(response);
          return;
        } catch (_) {
          // Retry failed, fall through to original error
        }
      }
    }
    handler.next(err);
  }
}

/// Simple retry interceptor for transient network errors.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(
    this._dio, {
    this.retryDelay = const Duration(seconds: 1),
  });

  final Dio _dio;
  final Duration retryDelay;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final shouldRetry = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError;

    if (shouldRetry && err.requestOptions.extra['retryCount'] == null) {
      err.requestOptions.extra['retryCount'] = 1;
      await Future.delayed(retryDelay);
      try {
        final response = await _dio.fetch(err.requestOptions);
        handler.resolve(response);
      } catch (e) {
        handler.next(err);
      }
      return;
    }

    handler.next(err);
  }
}

/// Provider for the shared [ApiClient] instance.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient.instance);

/// Provider for the [Dio] instance for direct use in tests.
final dioProvider = Provider<Dio>((ref) => ref.watch(apiClientProvider).dio);