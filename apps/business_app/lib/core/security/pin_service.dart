import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hashes and verifies device-local PINs using Argon2id.
///
/// A fresh random 16-byte salt is generated per PIN with [Random.secure]
/// and persisted alongside the hash in a self-describing PHC-style string:
///
/// ```text
/// argon2id$v=19$m=<memory>,t=<iterations>,p=<parallelism>$<saltB64>$<hashB64>
/// ```
///
/// The stored string carries its own parameters so hashes stay verifiable
/// even if [PinService] defaults change later. PINs are never retained in
/// memory after hashing and never leave the device.
class PinService {
  const PinService({
    this.memory = recommendedMemory,
    this.iterations = recommendedIterations,
    this.parallelism = recommendedParallelism,
  });

  /// 19 MiB of 1 kB blocks — OWASP guidance for Argon2id memory.
  static const int recommendedMemory = 19456;
  static const int recommendedIterations = 3;
  static const int recommendedParallelism = 1;

  static const int _hashLength = 32;
  static const int _saltLength = 16;
  static const String _prefix = 'argon2id';

  final int memory;
  final int iterations;
  final int parallelism;

  Argon2id _algorithm() => Argon2id(
        parallelism: parallelism,
        memory: memory,
        iterations: iterations,
        hashLength: _hashLength,
      );

  /// Hashes [pin] with a fresh random salt.
  Future<String> hashPin(String pin) async {
    final salt = _randomSalt();
    final key = await _algorithm().deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );
    final hash = await key.extractBytes();

    return '$_prefix\$v=19\$m=$memory,t=$iterations,p=$parallelism'
        '\$${base64Encode(salt)}\$${base64Encode(hash)}';
  }

  /// Returns `true` when [pin] matches the stored [pinHash].
  ///
  /// A malformed or unknown hash format returns `false` rather than
  /// throwing, so a corrupted record degrades to a failed attempt.
  Future<bool> verifyPin(String pin, String pinHash) async {
    final parts = pinHash.split(r'$');
    if (parts.length != 5 || parts[0] != _prefix) return false;

    final memory = _paramValue(parts[2], 'm');
    final iterations = _paramValue(parts[2], 't');
    final parallelism = _paramValue(parts[2], 'p');
    if (memory == null || iterations == null || parallelism == null) {
      return false;
    }

    List<int> salt;
    List<int> expected;
    try {
      salt = base64Decode(parts[3]);
      expected = base64Decode(parts[4]);
    } on FormatException {
      return false;
    }

    final algorithm = Argon2id(
      parallelism: parallelism,
      memory: memory,
      iterations: iterations,
      hashLength: _hashLength,
    );
    final key = await algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );
    final hash = await key.extractBytes();

    return _constantTimeEquals(hash, expected);
  }

  List<int> _randomSalt() {
    final rng = Random.secure();
    return List<int>.generate(_saltLength, (_) => rng.nextInt(256));
  }

  int? _paramValue(String params, String name) {
    for (final part in params.split(',')) {
      if (part.startsWith('$name=')) {
        return int.tryParse(part.substring(name.length + 1));
      }
    }
    return null;
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

/// App-wide [PinService] instance.
final pinServiceProvider = Provider<PinService>((ref) => const PinService());
