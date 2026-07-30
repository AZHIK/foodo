import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper around [FlutterSecureStorage] that is multi-profile aware.
///
/// Every value is keyed by `user_id` so that switching between profiles
/// (staff members who share a device) never leaks tokens between users.
///
/// Placeholder implementation — the actual encrypt / decrypt / refresh
/// flows will be added once the auth service integration is built.
class SecureStorageService {
  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
        );

  final FlutterSecureStorage _storage;

  // ── Token helpers (keyed by user_id) ──────────────────────────
  Future<void> saveRefreshToken({
    required String userId,
    required String token,
  }) =>
      _storage.write(key: 'refresh_token_$userId', value: token);

  Future<String?> readRefreshToken(String userId) =>
      _storage.read(key: 'refresh_token_$userId');

  Future<void> deleteRefreshToken(String userId) =>
      _storage.delete(key: 'refresh_token_$userId');

  // ── Generic key-value ─────────────────────────────────────────
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  Future<String?> read(String key) => _storage.read(key: key);
  Future<void> delete(String key) => _storage.delete(key: key);
  Future<void> clearAll() => _storage.deleteAll();
}
