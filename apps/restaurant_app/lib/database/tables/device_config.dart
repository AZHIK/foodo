/// Device-level lock to a single business and location.
///
/// `DeviceConfig` is a singleton row (`id = 0`) that records which business
/// and location this terminal belongs to. The app is device-locked to exactly
/// one `(businessId, businessLocationId)` pair, so there is no per-request
/// "active business" concept (e.g., no `LocalUserProfiles.activeBusinessId` —
/// that would be redundant with `DeviceConfig.businessId` and would only ever
/// hold one value).
///
/// The `CHECK (id = 0)` constraint prevents accidental multiple-row bugs.
/// An unprovisioned device has no `DeviceConfig` row; the app falls back to
/// the hardcoded `BusinessProfile.seed` ("The Copper Fig") exactly as today,
/// keeping all existing tests passing with zero setup.
library;

import 'package:drift/drift.dart';

/// Device-level lock to a single business and location.
class DeviceConfig extends Table {
  /// Singleton key (always 0).
  IntColumn get id => integer().clientDefault(() => 0)();

  /// Business UUID this device is locked to.
  TextColumn get businessId => text()();

  /// Business location UUID this device is locked to.
  TextColumn get businessLocationId => text()();

  /// Cached business name for offline use (receipts, headers).
  TextColumn get businessName => text()();

  /// Optional device label (e.g., "Front counter").
  TextColumn get deviceLabel => text().nullable()();

  /// When this device was provisioned.
  DateTimeColumn get provisionedAt => dateTime()();

  /// Last provisioning update timestamp.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (id = 0)'];
}
