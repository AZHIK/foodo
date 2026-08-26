/// Database connection setup with at-rest SQLCipher encryption.
///
/// `driftDatabaseConnection` creates a `LazyDatabase` that:
/// 1. Opens (or creates) `app.db` in the app's documents directory.
/// 2. Applies `PRAGMA key` to enable SQLCipher encryption.
/// 3. Returns a `NativeDatabase` via `drift_flutter` on all native platforms.
///
/// The `key` parameter is the 64-character hex-encoded encryption key (32 bytes,
/// generated once by `EncryptionKeyService` on first launch). The same key must
/// be used to reopen an existing encrypted database.
library;

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Creates a Drift database connection with SQLCipher encryption.
///
/// The database file (`app.db`) is stored in the app's documents directory.
/// SQLCipher encryption is configured via `PRAGMA key` with the provided key.
/// Foreign key constraints are enforced at all times.
LazyDatabase driftDatabaseConnection(String encryptionKey) =>
    LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'app.db'));
      return NativeDatabase.createInBackground(
        file,
        setup: (rawDb) {
          // Enable SQLCipher encryption with the provided key.
          rawDb.execute("PRAGMA key = '$encryptionKey';");
          // Enforce foreign key constraints.
          rawDb.execute('PRAGMA foreign_keys = ON');
        },
      );
    });
