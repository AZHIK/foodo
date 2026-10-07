/// Data access layer for local staff profiles and device configuration.
///
/// `LocalProfileRepository` provides read/write methods for `LocalUserProfiles`
/// and `DeviceConfig`, abstracting the Drift query patterns and making the
/// sync and session layers' intentions explicit.
library;

import 'package:drift/drift.dart';
import 'app_database.dart';

/// Data access layer for staff profiles and device config.
class LocalProfileRepository {
  final AppDatabase _db;

  LocalProfileRepository(this._db);

  /// Retrieves the device configuration (singleton row), or null if unprovisioned.
  Future currentDevice() {
    return (_db.select(_db.deviceConfig)
          ..where((row) => row.id.equals(0)))
        .getSingleOrNull();
  }

  /// Provisions this device to a business and location.
  /// Upserts (replaces) the singleton DeviceConfig row.
  Future<void> provisionDevice({
    required String businessId,
    required String businessLocationId,
    required String businessName,
    String? deviceLabel,
  }) {
    final now = DateTime.now();
    return _db.into(_db.deviceConfig).insertOnConflictUpdate(
          DeviceConfigCompanion(
            id: const Value(0),
            businessId: Value(businessId),
            businessLocationId: Value(businessLocationId),
            businessName: Value(businessName),
            deviceLabel: Value(deviceLabel),
            provisionedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  /// Provisions like [provisionDevice], but when the device is already locked
  /// to a DIFFERENT business, wipes all local data first: one terminal
  /// serves exactly one business, so the old business's profiles, caches
  /// and outboxes must never linger under the new lock. Same-business
  /// re-locks (store moves, re-logins) keep everything.
  ///
  /// Used on every login provisioning path, so a terminal that re-logs-in
  /// after its business was deleted/reset online automatically starts afresh
  /// instead of mixing stale rows with the new business.
  Future<void> reprovisionDevice({
    required String businessId,
    required String businessLocationId,
    required String businessName,
    String? deviceLabel,
  }) async {
    final current = await currentDevice();
    final lockedBusinessId = current?.businessId as String?;
    if (lockedBusinessId != null && lockedBusinessId != businessId) {
      await wipeAllLocalData();
    }
    await provisionDevice(
      businessId: businessId,
      businessLocationId: businessLocationId,
      businessName: businessName,
      deviceLabel: deviceLabel,
    );
  }

  /// Retrieves a staff profile by ID.
  Future getProfile(String staffId) {
    return (_db.select(_db.localUserProfiles)
          ..where((row) => row.id.equals(staffId)))
        .getSingleOrNull();
  }

  /// Retrieves all saved staff profiles.
  Future allProfiles() {
    return _db.select(_db.localUserProfiles).get();
  }

  /// Retrieves only profiles that logout has not deactivated. Every
  /// saved-profile list (Profile Picker, boot restore, local staff) reads
  /// through here — a logged-out profile keeps its row (PIN, role, cached
  /// permissions) for instant reactivation but is never offered.
  Future activeProfiles() {
    return (_db.select(_db.localUserProfiles)
          ..where((row) => row.isDeactivated.equals(false)))
        .get();
  }

  /// Deactivates (`true`) or reactivates (`false`) a profile without
  /// deleting its row. Logout deactivates; the next login reactivates.
  /// A missing row is a no-op — creation paths write active rows directly.
  Future<void> setDeactivated(String staffId, bool deactivated) {
    return (_db.update(_db.localUserProfiles)
          ..where((row) => row.id.equals(staffId)))
        .write(
      LocalUserProfilesCompanion(
        isDeactivated: Value(deactivated),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Inserts or updates a staff profile.
  Future<void> upsertProfile(LocalUserProfilesCompanion profile) {
    return _db.into(_db.localUserProfiles).insertOnConflictUpdate(profile);
  }

  /// Records [displayName] locally as soon as it's known — right after
  /// Complete Profile, before a PIN exists — rather than waiting for Set
  /// PIN to create the row. Creates a placeholder profile (empty PIN hash/
  /// salt, filled in later by `setPin`) if one doesn't exist yet; otherwise
  /// only refreshes the name, never touching an existing PIN.
  ///
  /// Always marks the row active: this runs in the login flow, so a
  /// re-logging user reactivates here even before Set PIN.
  Future<void> upsertDisplayName(String staffId, String displayName) async {
    final existing = await getProfile(staffId);
    final now = DateTime.now();
    if (existing == null) {
      await upsertProfile(
        LocalUserProfilesCompanion.insert(
          id: staffId,
          displayName: displayName,
          pinHash: '',
          pinSalt: '',
          createdAt: now,
          updatedAt: now,
          isDeactivated: const Value(false),
        ),
      );
    } else {
      await (_db.update(_db.localUserProfiles)..where((row) => row.id.equals(staffId))).write(
        LocalUserProfilesCompanion(
          displayName: Value(displayName),
          isDeactivated: const Value(false),
          updatedAt: Value(now),
        ),
      );
    }
  }

  /// Deletes a staff profile.
  Future<void> deleteProfile(String staffId) {
    return (_db.delete(_db.localUserProfiles)
          ..where((row) => row.id.equals(staffId)))
        .go();
  }

  /// Removes the singleton `DeviceConfig` row, returning the device to an
  /// unprovisioned state. Used when the locked store is deleted remotely:
  /// the business still exists, so local cached data is kept and the next
  /// login re-provisions the device to a surviving store.
  Future<void> clearDeviceProvisioning() {
    return (_db.delete(_db.deviceConfig)
          ..where((row) => row.id.equals(0)))
        .go();
  }

  /// Full local wipe for a remotely-deleted business: deletes EVERY local
  /// row (all 20 tables) in one transaction, including `DeviceConfig` and
  /// all profiles/caches/outboxes.
  ///
  /// This is destructive by design — unsynced outbox rows for the deleted
  /// business can never sync (their FK targets are gone) and keeping them
  /// would leave orphaned data on a device that no longer belongs to any
  /// business. Callers must have already confirmed `businessGone` online
  /// (see `remote_provision_guard.dart`) — never call this offline or on
  /// transient errors. Tokens are cleared separately via `TokenStorage`.
  Future<void> wipeAllLocalData() {
    return _db.transaction(() async {
      // Children before parents where FKs are enforced (permissions cascade
      // off profiles, but explicit ordering keeps this robust even if the
      // pragma is ever off).
      await _db.delete(_db.pendingSaleLineItems).go();
      await _db.delete(_db.pendingSales).go();
      await _db.delete(_db.pendingVoidsRefunds).go();
      await _db.delete(_db.cachedSaleLineItems).go();
      await _db.delete(_db.cachedSales).go();
      await _db.delete(_db.customerEntries).go();
      await _db.delete(_db.cachedCustomers).go();
      await _db.delete(_db.expenseEntries).go();
      await _db.delete(_db.otherIncomeEntries).go();
      await _db.delete(_db.cachedOtherExpenses).go();
      await _db.delete(_db.cachedOtherIncomes).go();
      await _db.delete(_db.cachedItems).go();
      await _db.delete(_db.cachedStockLevels).go();
      await _db.delete(_db.cachedSuppliers).go();
      await _db.delete(_db.cachedCategories).go();
      await _db.delete(_db.cachedUnits).go();
      await _db.delete(_db.cachedBusinessRoles).go();
      await _db.delete(_db.cachedPermissions).go();
      await _db.delete(_db.localAuditLog).go();
      await _db.delete(_db.localUserProfiles).go();
      await _db.delete(_db.deviceConfig).go();
    });
  }

  /// Updates failedPinAttempts and lockedUntil for a profile.
  Future<void> updateLockout(
    String staffId,
    int failedAttempts,
    DateTime? lockedUntil,
  ) {
    return (_db.update(_db.localUserProfiles)
          ..where((row) => row.id.equals(staffId)))
        .write(
      LocalUserProfilesCompanion(
        failedPinAttempts: Value(failedAttempts),
        lockedUntil: Value(lockedUntil),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Updates lastSignedInAt for a profile.
  Future<void> recordSignIn(String staffId) {
    return (_db.update(_db.localUserProfiles)
          ..where((row) => row.id.equals(staffId)))
        .write(
      LocalUserProfilesCompanion(
        lastSignedInAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Updates roleLabel for a profile (used after context switch to cache roles).
  Future<void> updateRoleLabel(String staffId, String? roleLabel) {
    return (_db.update(_db.localUserProfiles)
          ..where((row) => row.id.equals(staffId)))
        .write(
      LocalUserProfilesCompanion(
        roleLabel: Value(roleLabel),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Inserts or replaces the cached role/permission set for a staff member.
  Future<void> upsertPermissions(CachedPermissionsCompanion permissions) {
    return _db.into(_db.cachedPermissions).insertOnConflictUpdate(permissions);
  }

  /// Retrieves the cached permissions for a staff member, or null if none exist.
  Future<CachedPermission?> getPermissions(String userId) {
    return (_db.select(_db.cachedPermissions)
          ..where((row) => row.userId.equals(userId)))
        .getSingleOrNull();
  }

  /// Gets all cached business roles for a business.
  Future<List<CachedBusinessRole>> getCachedRoles(String businessId) {
    return (_db.select(_db.cachedBusinessRoles)
          ..where((row) => row.businessId.equals(businessId)))
        .get();
  }

  /// Replaces all cached business roles for a business (wholesale refresh).
  Future<void> setCachedRoles(String businessId, List<CachedBusinessRolesCompanion> roles) {
    return _db.transaction(() async {
      // Delete old cache for this business
      await (_db.delete(_db.cachedBusinessRoles)
            ..where((row) => row.businessId.equals(businessId)))
          .go();
      // Insert new roles
      for (final role in roles) {
        await _db.into(_db.cachedBusinessRoles).insert(role);
      }
    });
  }
}
