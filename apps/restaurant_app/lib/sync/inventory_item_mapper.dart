/// Bridges the backend-shaped cache (`CachedItems` + `CachedStockLevels`)
/// onto the UI's `InventoryItem` model.
///
/// The two shapes don't line up 1:1: `InventoryItem` carries client-only UI
/// concerns with no backend equivalent (`emoji`, `image`, `description`,
/// `supplier`, `lastCountedAt`, `trackStock`) and stock genuinely lives in a
/// separate table server-side. Rather than reshape either side, this is a
/// pure adapter — `catalogItemId` is the join key `InventoryItem` already
/// carries for exactly this purpose.
///
/// The fields with no backend source are decorative-only against real data:
/// they render with a sensible default and can be edited locally, but
/// nothing persists that edit anywhere, so it does not survive the next
/// cache refresh. Building durable local overrides for them is a follow-up,
/// not something this mapper does.
library;

import 'package:decimal/decimal.dart';

import '../database/app_database.dart';
import '../models/inventory_item.dart';

/// Backend `unit_of_measure` codes (`kg|g|l|ml|unit|pack`) to the short
/// display string `InventoryItem.unit` expects next to a quantity.
String unitOfMeasureLabel(String unitOfMeasure) => switch (unitOfMeasure) {
      'kg' => 'kg',
      'g' => 'g',
      'l' => 'L',
      'ml' => 'ml',
      'pack' => 'pack',
      _ => 'ea',
    };

/// A short, stable, display-only stand-in for a real SKU — real items have
/// no SKU field on the backend, so this is derived from the id rather than
/// left blank (the UI treats `sku` as always-present).
String _displaySku(String itemId) {
  final compact = itemId.replaceAll('-', '');
  return compact.length >= 8 ? compact.substring(0, 8).toUpperCase() : compact.toUpperCase();
}

double _toDouble(Decimal? value) => value == null ? 0 : double.parse(value.toString());

/// Maps one joined catalog+stock row to the UI model. [stockRow] is null
/// when a stock-level sync hasn't run yet (or hasn't seen this item) — the
/// item still renders, just with a `0` on-hand quantity until that catches
/// up, matching `CachedStockLevels`' own "pull-only, display hint" contract.
InventoryItem inventoryItemFromCachedRow({
  required CachedItem catalogRow,
  CachedStockLevel? stockRow,
}) {
  return InventoryItem(
    id: catalogRow.id,
    catalogItemId: catalogRow.id,
    sku: _displaySku(catalogRow.id),
    name: catalogRow.name,
    categoryId: catalogRow.category ?? 'uncategorized',
    emoji: '📦',
    stock: stockRow != null ? _toDouble(stockRow.currentQuantity) : 0,
    reorderLevel: _toDouble(catalogRow.reorderThreshold),
    unitCost: _toDouble(catalogRow.unitCost),
    unit: unitOfMeasureLabel(catalogRow.unitOfMeasure),
    isArchived: !catalogRow.isActive,
  );
}
