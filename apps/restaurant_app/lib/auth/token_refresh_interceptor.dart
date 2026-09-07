/// Dio interceptor for automatic access token refresh.
///
/// Catches 401 responses, attempts to refresh the token using the refresh token,
/// and retries the original request with the new access token.
///
/// Uses its own bare Dio instance (no interceptors) for refresh calls to avoid
/// reentrancy issues if the refresh call itself fails with 401.
library;

import 'package:dio/dio.dart';
import '../database/local_profile_repository.dart';
import 'identity_service_api.dart';
import 'permissions_cache_sync.dart';
import 'token_storage.dart';

/// Handles silent token refresh on 401 responses.
class TokenRefreshInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  final String _baseUrl;

  /// Optional: when given, a successful background refresh also updates
  /// the local `CachedPermissions` table (see `syncPermissionsCache`) —
  /// without this, a long session kept alive purely by this reactive
  /// refresh (no PIN unlock, no cold start) would never pick up a
  /// permission change an admin makes mid-session. Null in call sites that
  /// have no database to write to (e.g. a bare pre-login Dio client).
  final LocalProfileRepository? _profileRepo;

  /// Called after a successful cache sync so a Riverpod-aware caller can
  /// bump `permissionsCacheTickProvider` — this class has no `ref` of its
  /// own to do that directly.
  final void Function()? _onPermissionsSynced;
  late final IdentityServiceApi _api;

  /// Public endpoints whose own normal error path is a 401 unrelated to
  /// token expiry (wrong OTP code, wrong password) — refreshing and
  /// retrying these would just resend the same bad credentials and get
  /// the same 401 back, wasting a round-trip on every failed attempt.
  static const _publicAuthPaths = [
    '/auth/otp/verify',
    '/auth/login/password',
    '/auth/platform/login',
  ];

  // Lock to prevent multiple simultaneous refresh attempts.
  bool _isRefreshing = false;
  late Future<void> _refreshFuture;

  TokenRefreshInterceptor({
    required TokenStorage tokenStorage,
    required String baseUrl,
    LocalProfileRepository? profileRepo,
    void Function()? onPermissionsSynced,
  })  : _tokenStorage = tokenStorage,
        _baseUrl = baseUrl,
        _profileRepo = profileRepo,
        _onPermissionsSynced = onPermissionsSynced {
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
    // Every IdentityServiceApi call that needs auth already sets its own
    // Authorization header with the exact token it was handed (e.g. the
    // freshly-issued one from /auth/otp/verify, before it's ever written to
    // TokenStorage by _switchContextAndLock). Only fall back to the stored
    // token for requests that didn't set one — overwriting an explicit
    // header here would replace a known-good token with a stale or
    // already-rotated one from a previous session.
    if (!options.headers.containsKey('Authorization')) {
      final tokenSet = await _tokenStorage.getTokenSet();
      if (tokenSet != null) {
        options.headers['Authorization'] = 'Bearer ${tokenSet.accessToken}';
      }
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

    // These endpoints 401 for reasons unrelated to token expiry — refreshing
    // and retrying would just resend the same bad credentials.
    if (_publicAuthPaths.any((p) => err.requestOptions.path.contains(p))) {
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

      // Get the current token set to extract the userId for per-user storage.
      final currentTokenSet = await _tokenStorage.getTokenSet();
      final userId = currentTokenSet?.userId;

      if (userId != null) {
        // Update per-user tokens.
        await _tokenStorage.updateTokens(
          userId,
          output.accessToken,
          output.refreshToken,
          expiresAt,
        );

        final profileRepo = _profileRepo;
        if (profileRepo != null) {
          await syncPermissionsCache(
            profileRepo: profileRepo,
            userId: userId,
            accessToken: output.accessToken,
            onSynced: _onPermissionsSynced,
          );
        }
      }
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
