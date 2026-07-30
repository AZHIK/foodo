import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Placeholder for the Drift-powered encrypted local database.
///
/// SQLCipher-based encryption is prepared (passphrase generation below)
/// but no tables are defined yet — that happens in Stage 2 when the
/// POS and Inventory caching schemas are designed.
///
/// Once tables exist, this class will extend the drift-generated
/// `_$AppDatabase` and be opened via:
/// ```dart
/// driftDatabase(
///   name: 'foodlink_business',
///   native: DriftNativeOptions(
///     passphrase: getDatabasePassphrase,
///   ),
/// )
/// ```
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
}

/// Generates or retrieves a persistent 256-bit database encryption key
/// from secure storage.
///
/// On first launch a random key is generated and persisted so that
/// subsequent launches can re-read the same key.  This ensures the
/// underlying SQLite file is always encrypted at rest.
Future<String> getDatabasePassphrase() async {
  const keyName = 'db_passphrase_v1';
  const storage = FlutterSecureStorage();
  final existing = await storage.read(key: keyName);
  if (existing != null && existing.isNotEmpty) return existing;

  final rng = Random.secure();
  final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
  final b64 = base64Url.encode(bytes);
  await storage.write(key: keyName, value: b64);
  return b64;
}
