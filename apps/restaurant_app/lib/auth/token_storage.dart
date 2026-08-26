/// Persistent storage for access/refresh tokens and auth metadata.
///
/// Uses flutter_secure_storage for sensitive token data.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Holds access token, refresh token, and related metadata.
class TokenSet {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String userId;

  TokenSet({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.userId,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isExpiringSoon =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 5)));
}

/// Manages persistent storage of auth tokens via secure storage.
class TokenStorage {
  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _keyAccessToken = 'auth_access_token';
  static const _keyRefreshToken = 'auth_refresh_token';
  static const _keyExpiresAt = 'auth_expires_at';
  static const _keyUserId = 'auth_user_id';

  /// Saves a token set persistently.
  Future<void> saveTokenSet(TokenSet tokenSet) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: tokenSet.accessToken),
      _storage.write(key: _keyRefreshToken, value: tokenSet.refreshToken),
      _storage.write(
        key: _keyExpiresAt,
        value: tokenSet.expiresAt.toIso8601String(),
      ),
      _storage.write(key: _keyUserId, value: tokenSet.userId),
    ]);
  }

  /// Retrieves a saved token set, or null if none exists.
  Future<TokenSet?> getTokenSet() async {
    final accessToken = await _storage.read(key: _keyAccessToken);
    if (accessToken == null) return null;

    final refreshToken = await _storage.read(key: _keyRefreshToken);
    final expiresAtStr = await _storage.read(key: _keyExpiresAt);
    final userId = await _storage.read(key: _keyUserId);

    if (refreshToken == null || expiresAtStr == null || userId == null) {
      return null;
    }

    return TokenSet(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: DateTime.parse(expiresAtStr),
      userId: userId,
    );
  }

  /// Clears all stored tokens (logout or device reset).
  Future<void> clearTokenSet() async {
    await Future.wait([
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
      _storage.delete(key: _keyExpiresAt),
      _storage.delete(key: _keyUserId),
    ]);
  }

  /// Updates only the access token (e.g., after a refresh).
  Future<void> updateAccessToken(String accessToken, DateTime expiresAt) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyExpiresAt, value: expiresAt.toIso8601String()),
    ]);
  }

  /// Updates both access token and refresh token (after token refresh/rotation).
  /// The backend rotates the refresh token on each refresh, so both must be persisted.
  Future<void> updateTokens(
    String accessToken,
    String refreshToken,
    DateTime expiresAt,
  ) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
      _storage.write(key: _keyExpiresAt, value: expiresAt.toIso8601String()),
    ]);
  }
}
