/// Key generation and retrieval for at-rest database encryption.
///
/// `EncryptionKeyService` handles the lifecycle of the database encryption key:
/// - **First launch**: generates 32 random bytes (via `Random.secure()`, OS-backed
///   CSPRNG), hex-encodes to a 64-char string, stores in secure storage.
/// - **Subsequent launches**: retrieves the stored key to reopen the encrypted file.
///
/// The key is stored in `flutter_secure_storage` (Android: EncryptedSharedPreferences
/// in the hardware keystore; iOS: Keychain; Windows/macOS/Linux: platform keychain).
/// The raw database file is unreadable without the key.
///
/// **Known edge cases (not solved, documented)**:
/// - **Secure storage cleared, DB file persists**: detect via the first query failing
///   after `PRAGMA key` (SQLCipher reports this as a "file is not a database" error).
///   Recovery: offer "reset local data" (deletes the DB file), which loses unsynced
///   `PendingSales` rows.
/// - **DB file deleted, key persists**: silently recreates the DB; same data-loss
///   caveat for unsynced sales.
library;

import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Generates and persists database encryption keys.
class EncryptionKeyService {
  static const _keyStorageKey = 'db_encryption_key';

  final FlutterSecureStorage _storage;

  EncryptionKeyService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                resetOnError: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  /// Retrieves the stored key, or generates and stores a new one if none exists.
  ///
  /// Returns a 64-character hex string (32 random bytes encoded).
  Future<String> getOrCreateKey() async {
    final existing = await _storage.read(key: _keyStorageKey);
    if (existing != null) {
      return existing;
    }

    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
    final hexKey = keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    await _storage.write(key: _keyStorageKey, value: hexKey);
    return hexKey;
  }
}
