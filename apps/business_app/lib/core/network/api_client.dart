import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'api_endpoints.dart';

/// Singleton [Dio] HTTP client configured with the base URL from the
/// environment and sensible defaults.
///
/// Placeholder interceptor slots are registered at construction time
/// but left as no-ops.  Real interceptors (auth-header injection,
/// token-refresh, retry-on-401) will be wired in later stages once
/// the auth service integration is built.
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

    // ── Placeholder interceptor slots ──────────────────────────
    // Auth header interceptor    — will read token from SecureStorageService
    // Token refresh interceptor  — will retry on 401 with refresh token
    // Retry interceptor          — will retry on transient network errors

    return d;
  }
}
