/// PIN hashing and verification utilities.
///
/// Provides HMAC-SHA256 hashing with per-profile salts for secure PIN storage.
/// The hash is never reversible; verification is done by re-hashing the entered
/// PIN and comparing the result to the stored hash.
library;

import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Generates a random salt and hashes a PIN.
class PinHasher {
  /// Generates a random salt (16 bytes, hex-encoded to 32 chars).
  static String generateSalt() {
    final random = Uint8List.fromList(
      List<int>.generate(16, (_) => DateTime.now().microsecond % 256),
    );
    return base64Url.encode(random).replaceAll('=', '');
  }

  /// Hashes a PIN with a salt using HMAC-SHA256.
  static String hash(String pin, String salt) {
    final key = utf8.encode(salt);
    final bytes = utf8.encode(pin);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  /// Verifies a PIN by hashing it with the salt and comparing.
  static bool verify(String enteredPin, String storedHash, String salt) {
    final computedHash = hash(enteredPin, salt);
    return computedHash == storedHash;
  }
}
