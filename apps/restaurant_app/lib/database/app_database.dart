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
/// v1 was the first version, so its `onCreate` handled everything.
///
/// v2 is additive-only: offline RBAC (`CachedPermissions`), an advisory
/// stock-level cache (`CachedStockLevels`), void/refund and expense/income
/// outboxes (`PendingVoidsRefunds`, `ExpenseEntries`, `OtherIncomeEntries`),
/// an audit trail outbox (`LocalAuditLog`), and one new nullable column on
/// `LocalUserProfiles` (`lastRevocationCheckAt`). No existing table is
/// dropped, renamed, or has a column removed.
library;

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'converters/decimal_converter.dart';
import 'tables/local_user_profiles.dart';
import 'tables/device_config.dart';
import 'tables/pending_sales.dart';
import 'tables/pending_sale_line_items.dart';
import 'tables/cached_items.dart';
import 'tables/cached_permissions.dart';
import 'tables/cached_stock_levels.dart';
import 'tables/cached_business_roles.dart';
import 'tables/pending_voids_refunds.dart';
import 'tables/expense_entries.dart';
import 'tables/other_income_entries.dart';
import 'tables/local_audit_log.dart';

part 'app_database.g.dart';

/// Application's Drift database.
@DriftDatabase(tables: [
  LocalUserProfiles,
  DeviceConfig,
  PendingSales,
  PendingSaleLineItems,
  CachedItems,
  CachedPermissions,
  CachedStockLevels,
  CachedBusinessRoles,
  PendingVoidsRefunds,
  ExpenseEntries,
  OtherIncomeEntries,
  LocalAuditLog,
])
class AppDatabase extends _$AppDatabase {
  /// Creates an instance using the provided connection.
  AppDatabase(super.connection);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(
          localUserProfiles,
          localUserProfiles.lastRevocationCheckAt,
        );
        await m.createTable(cachedBusinessRoles);
        await m.createTable(cachedPermissions);
        await m.createTable(cachedStockLevels);
        await m.createTable(pendingVoidsRefunds);
        await m.createTable(expenseEntries);
        await m.createTable(otherIncomeEntries);
        await m.createTable(localAuditLog);
      }
      if (from < 3) {
        // v2→v3: Create CachedBusinessRoles if it wasn't created in v1→v2 upgrade
        // (safety net for installations that upgraded v1→v2 before this fix)
        try {
          await m.createTable(cachedBusinessRoles);
        } catch (e) {
          // Table may already exist; ignore error
        }
      }
    },
    beforeOpen: (details) async {
      // Enforce foreign key constraints.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
