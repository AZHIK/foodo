/// Local cache of staff members who can sign in on this shared device.
///
/// `LocalUserProfiles` backs the Profile Picker (staff selection at signin)
/// and PIN unlock flow, persisting staff identities, PIN hashes, and lockout
/// state across app restarts. This replaces the in-memory `SessionState`'s
/// plaintext PIN storage with a salted hash and persistent lockout tracking.
///
/// The `id` is the staff member's UUID from Identity Service. All other fields
/// are cached or derived locally; no FK constraints outward since they
/// reference external services.
library;

import 'package:drift/drift.dart';

/// Local cache of staff who can sign in on this device.
class LocalUserProfiles extends Table {
  /// Staff member's UUID from Identity Service (primary key).
  TextColumn get id => text()();

  /// Display name, cached for the Profile Picker.
  TextColumn get displayName => text()();

  /// Salted hash of the PIN (HMAC-SHA256).
  TextColumn get pinHash => text()();

  /// Per-profile random salt for PIN hashing.
  TextColumn get pinSalt => text()();

  /// Cached display-only role name.
  TextColumn get roleLabel => text().nullable()();

  /// Last successful sign-in timestamp.
  DateTimeColumn get lastSignedInAt => dateTime().nullable()();

  /// Consecutive failed PIN attempts (persisted so lockout survives restart).
  IntColumn get failedPinAttempts => integer().withDefault(const Constant(0))();

  /// When the current lockout ends, or null when not locked out.
  DateTimeColumn get lockedUntil => dateTime().nullable()();

  /// Row creation timestamp.
  DateTimeColumn get createdAt => dateTime()();

  /// Row last-updated timestamp.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
