/// Dio interceptor for automatic access token refresh.
///
/// Catches 401 responses, attempts to refresh the token using the refresh token,
/// and retries the original request with the new access token.
///
/// Uses its own bare Dio instance (no interceptors) for refresh calls to avoid
/// reentrancy issues if the refresh call itself fails with 401.
library;

import 'package:dio/dio.dart';
import 'identity_service_api.dart';
import 'token_storage.dart';

/// Handles silent token refresh on 401 responses.
class TokenRefreshInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  final String _baseUrl;
  late final IdentityServiceApi _api;

  // Lock to prevent multiple simultaneous refresh attempts.
  bool _isRefreshing = false;
  late Future<void> _refreshFuture;

  TokenRefreshInterceptor({
    required TokenStorage tokenStorage,
    required String baseUrl,
  })  : _tokenStorage = tokenStorage,
        _baseUrl = baseUrl {
    // Create a bare Dio instance (no interceptors) for refresh calls.
    // This prevents reentrancy if the refresh call itself fails.
    final bareDio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));
    _api = IdentityServiceApi(dio: bareDio);
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Attach the current access token to every request.
    final tokenSet = await _tokenStorage.getTokenSet();
    if (tokenSet != null) {
      options.headers['Authorization'] = 'Bearer ${tokenSet.accessToken}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only handle 401 Unauthorized responses.
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final tokenSet = await _tokenStorage.getTokenSet();
    if (tokenSet == null) {
      handler.next(err);
      return;
    }

    try {
      // If already refreshing, wait for that to complete.
      if (_isRefreshing) {
        await _refreshFuture;
        // Retry the original request with the new token.
        return handler.resolve(await _retry(err.requestOptions));
      }

      // Start a refresh.
      _isRefreshing = true;
      _refreshFuture = _performRefresh(tokenSet.refreshToken);

      await _refreshFuture;

      // Retry the original request.
      handler.resolve(await _retry(err.requestOptions));
    } on DioException catch (e) {
      handler.next(e);
    } finally {
      _isRefreshing = false;
    }
  }

  /// Calls the API to refresh the access token.
  /// The backend rotates the refresh token on each refresh.
  Future<void> _performRefresh(String refreshToken) async {
    try {
      final output = await _api.refreshAccessToken(refreshToken);
      final expiresAt = DateTime.now().add(
        Duration(seconds: 900), // Assume 15-min TTL (env config default)
      );

      // Update BOTH access and refresh tokens (refresh is rotated).
      await _tokenStorage.updateTokens(
        output.accessToken,
        output.refreshToken,
        expiresAt,
      );
    } catch (e) {
      // If refresh fails, the session is lost. Clear tokens.
      await _tokenStorage.clearTokenSet();
      rethrow;
    }
  }

  /// Retries a failed request with the new access token.
  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final tokenSet = await _tokenStorage.getTokenSet();
    if (tokenSet != null) {
      requestOptions.headers['Authorization'] = 'Bearer ${tokenSet.accessToken}';
    }

    final dio = Dio(BaseOptions(baseUrl: _baseUrl));
    return dio.request<dynamic>(
      requestOptions.path,
      options: Options(
        method: requestOptions.method,
        sendTimeout: requestOptions.sendTimeout,
        receiveTimeout: requestOptions.receiveTimeout,
        extra: requestOptions.extra,
        headers: requestOptions.headers,
        responseType: requestOptions.responseType,
        contentType: requestOptions.contentType,
        validateStatus: requestOptions.validateStatus,
        receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
        followRedirects: requestOptions.followRedirects,
        maxRedirects: requestOptions.maxRedirects,
      ),
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
    );
  }
}
