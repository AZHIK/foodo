/// Units of measure cached from Inventory Service, for the item form's
/// unit picker.
///
/// `CachedUnits` mirrors the backend's `UnitRead` schema (from
/// `services/inventory-service/app/schemas/units.py`) — a pull-only read
/// cache, global rather than business-scoped, exactly like
/// `CachedCategories`. No soft-delete column either: the backend never lets
/// a referenced unit disappear (`Item.unit_id` is `ondelete=RESTRICT`), so
/// `isActive=false` is the only "retired" state that can ever occur.
library;

import 'package:drift/drift.dart';

/// Units of measure cached from Inventory Service.
class CachedUnits extends Table {
  /// Unit UUID (primary key), server-assigned.
  TextColumn get id => text()();

  /// Stable slug (e.g. `kg`) — not used by the UI directly, kept for
  /// debugging/traceability back to the seed script.
  TextColumn get code => text()();

  TextColumn get name => text()();

  /// Short display label shown next to a quantity (e.g. `L`, `ea`) — what
  /// the item form's dropdown actually shows and what gets stored on
  /// `InventoryItem.unit`.
  TextColumn get abbreviation => text()();

  /// Display ordering for pickers, ascending.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Local timestamp of the most recent pull that included this row.
  DateTimeColumn get lastSyncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
