/// Application's offline-first Drift database.
///
/// `AppDatabase` is the single source of truth for all local persisted state:
/// auth (staff profiles, PIN hashes, lockout), device config, pending sales
/// awaiting sync, and a cached item catalog.
///
/// ─────────────────────────────────────────────────────────────────────────
/// DESIGN DECISION: No `activeBusinessId` and no `CachedBusinessContext`
/// ─────────────────────────────────────────────────────────────────────────
///
/// The original task described removing these as dead code from a prior
/// schema. This is a greenfield build (v1 is the first version), so they
/// are never created:
///
/// - `LocalUserProfiles.activeBusinessId` would always equal
///   `DeviceConfig.businessId` (the device is locked to one business).
///   A per-request "active business" concept has no use case.
///
/// - `CachedBusinessContext` would duplicate `DeviceConfig` (only ever one
///   row, already there). A business-context cache table has no use case.
///
/// These are documented as a design decision, not removed via migration.
///
/// ─────────────────────────────────────────────────────────────────────────
/// ENCRYPTION
/// ─────────────────────────────────────────────────────────────────────────
///
/// The database connection is opened with at-rest SQLCipher encryption via
/// `NativeDatabase.createInBackground` + a `PRAGMA key` setup, backed by
/// SQLite3MultipleCiphers. The encryption key is generated once on first
/// launch (32 random bytes via `Random.secure()`) and stored in
/// `flutter_secure_storage` (platform keychain/keystore). Subsequent launches
/// retrieve the key and reopen the same encrypted file. See
/// `lib/database/encryption_key_service.dart` for key lifecycle and known
/// edge cases (secure storage cleared but DB file persists, etc.).
///
/// ─────────────────────────────────────────────────────────────────────────
/// SYNC BOOKKEEPING & CONCURRENCY
/// ─────────────────────────────────────────────────────────────────────────
///
/// `PendingSales` tracks sync state across app restarts:
/// - `syncStatus`: pending → syncing → synced|failed
/// - `syncAttemptCount`: incremented on each attempt (tracks retries)
/// - `syncError`: populated if sync failed (not a transport error)
///
/// Synced rows are NEVER deleted; they double as local sale history for
/// offline receipts. The `syncStatus = 'syncing'` value is a row-claim
/// marker for cross-isolate concurrency safety: one DB transaction claims
/// and flips rows to 'syncing' before uploading, so a concurrent background
/// isolate (e.g., workmanager) cannot claim the same rows.
///
/// ─────────────────────────────────────────────────────────────────────────
/// MIGRATION STRATEGY
/// ─────────────────────────────────────────────────────────────────────────
///
/// This is `schemaVersion` 1, so `onCreate` handles everything. The
/// `onUpgrade` skeleton is present (not omitted) so future schema changes
/// have a place to attach, but nothing is needed here since there is no
/// prior version to migrate from.
library;

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'converters/decimal_converter.dart';
import 'tables/local_user_profiles.dart';
import 'tables/device_config.dart';
import 'tables/pending_sales.dart';
import 'tables/pending_sale_line_items.dart';
import 'tables/cached_items.dart';

part 'app_database.g.dart';

/// Application's Drift database.
@DriftDatabase(tables: [
  LocalUserProfiles,
  DeviceConfig,
  PendingSales,
  PendingSaleLineItems,
  CachedItems,
])
class AppDatabase extends _$AppDatabase {
  /// Creates an instance using the provided connection.
  AppDatabase(super.connection);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v1 is the first version; no migration path is needed yet.
      // Future schema changes attach migrations here.
    },
    beforeOpen: (details) async {
      // Enforce foreign key constraints.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
