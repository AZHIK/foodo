/// Inventory items cached from Inventory Service.
///
/// `CachedItems` mirrors the backend's `Item` model (from
/// `services/inventory-service/app/models/inventory.py`), storing the full
/// item catalog for offline access and as a foreign-key target for sales
/// that reference items by ID.
///
/// Rather than row-deleting items when they stop appearing in syncs,
/// `CachedItems` marks them `isActive = false`. This keeps any
/// `PendingSaleLineItems` rows that reference them valid: a completed sale
/// is a completed sale, even if the item was later retired from the catalog.
///
/// The `lastSeenAt` timestamp records when each item last appeared in a
/// catalog pull; anything not updated in the current pull gets
/// `isActive = false`, allowing soft-deletion without row removal.
library;

import 'package:drift/drift.dart';
import '../converters/decimal_converter.dart';

/// Inventory items cached from Inventory Service.
class CachedItems extends Table {
  /// Item UUID (primary key).
  TextColumn get id => text()();

  /// Business this item belongs to.
  TextColumn get businessId => text()();

  /// Business location this item belongs to.
  TextColumn get businessLocationId => text()();

  /// Item name.
  TextColumn get name => text()();

  /// Unit of measure (e.g., 'kg', 'l', 'unit', 'pack').
  TextColumn get unitOfMeasure => text()(); // kg|g|l|ml|unit|pack

  /// Item category (optional) — the backend `Category` row's UUID (see
  /// `CachedCategories`), not a free-text label. Was a raw free-text string
  /// before migration `f1a2b3c4d5e6_create_category_and_migrate_item_category`;
  /// the column itself is unchanged, only what it holds.
  TextColumn get category => text().nullable()();

  /// Reorder threshold quantity.
  TextColumn get reorderThreshold => text().map(const DecimalConverter())();

  /// Reorder quantity.
  TextColumn get reorderQuantity => text().map(const DecimalConverter())();

  /// Selling price (optional).
  TextColumn get sellingPrice => text().map(const DecimalConverter()).nullable()();

  /// Cost basis for the inventory-value metric (optional).
  TextColumn get unitCost => text().map(const DecimalConverter()).nullable()();

  /// Whether negative stock is allowed.
  BoolColumn get allowNegativeStock =>
      boolean().withDefault(const Constant(false))();

  /// Item type: `sellable`, `raw_material`, or `both`.
  TextColumn get itemType => text()(); // sellable|raw_material|both

  /// Soft-delete flag: false means the item is no longer available from the
  /// catalog, but existing references to it (e.g., completed sales) remain valid.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Backend creation timestamp.
  DateTimeColumn get createdAtServer => dateTime()();

  /// Backend last-update timestamp (used to detect changed rows on pull).
  DateTimeColumn get updatedAtServer => dateTime()();

  /// Local timestamp of the most recent pull that included this row.
  /// Anything with a stale `lastSeenAt` after a full pull gets `isActive=false`.
  DateTimeColumn get lastSeenAt => dateTime()();

  /// Local timestamp of the last catalog sync that touched this row.
  DateTimeColumn get lastSyncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
