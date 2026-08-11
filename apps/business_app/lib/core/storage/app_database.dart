import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'converters/string_list_converter.dart';
import 'tables/cached_business_contexts.dart';
import 'tables/cached_items.dart';
import 'tables/device_config.dart';
import 'tables/local_user_profiles.dart';
import 'tables/pending_sales.dart';
import 'tables/pending_sale_line_items.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  LocalUserProfiles,
  DeviceConfigs,
  CachedBusinessContexts,
  CachedItems,
  PendingSales,
  PendingSaleLineItems,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from == 1) {
            await m.addColumn(localUserProfiles, localUserProfiles.pinAttemptCount);
            await m.addColumn(localUserProfiles, localUserProfiles.pinLockedUntil);
          }
          if (from <= 2) {
            await m.createTable(deviceConfigs);
          }
        },
      );
}

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

/// App-wide [AppDatabase] instance, encrypted with a passphrase persisted
/// in secure storage. The passphrase is applied via SQLCipher's `PRAGMA
/// key` when the connection is opened.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final connection = DatabaseConnection.delayed(_openEncryptedConnection());

  final db = AppDatabase(connection);
  ref.onDispose(db.close);
  return db;
});

Future<DatabaseConnection> _openEncryptedConnection() async {
  final directory = await getApplicationDocumentsDirectory();
  final passphrase = await getDatabasePassphrase();
  final file = File('${directory.path}/foodlink.sqlite');

  return DatabaseConnection(
    NativeDatabase(
      file,
      setup: (db) {
        db.execute('PRAGMA key = "$passphrase";');
      },
    ),
  );
}
