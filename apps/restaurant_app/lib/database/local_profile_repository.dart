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

  /// Inserts or updates a staff profile.
  Future<void> upsertProfile(LocalUserProfilesCompanion profile) {
    return _db.into(_db.localUserProfiles).insertOnConflictUpdate(profile);
  }

  /// Deletes a staff profile.
  Future<void> deleteProfile(String staffId) {
    return (_db.delete(_db.localUserProfiles)
          ..where((row) => row.id.equals(staffId)))
        .go();
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
}
