/// Bridges the backend-shaped cache (`CachedItems` + `CachedStockLevels`)
/// onto the UI's `InventoryItem` model.
///
/// The two shapes don't line up 1:1: `InventoryItem` carries client-only UI
/// concerns with no backend equivalent (`emoji`, `image`, `description`,
/// `supplier`, `lastCountedAt`) and stock genuinely lives in a separate table
/// server-side. Rather than reshape either side, this is a pure adapter —
/// `catalogItemId` is the join key `InventoryItem` already carries for
/// exactly this purpose.
///
/// The fields with no backend source are decorative-only against real data:
/// they render with a sensible default and can be edited locally, but
/// nothing persists that edit anywhere, so it does not survive the next
/// cache refresh. Building durable local overrides for them is a follow-up,
/// not something this mapper does. `trackStock` is the one exception — it is
/// re-derived from `itemType` on every map rather than left at the model's
/// default, because getting it wrong is not decorative: a `sellable` item
/// with no stock-level row would otherwise come back "tracked" with a 0
/// on-hand quantity and read as out of stock everywhere, POS included.
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
  final sellingPrice = catalogRow.sellingPrice == null ? null : _toDouble(catalogRow.sellingPrice);
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
    sellingPrice: sellingPrice,
    // Raw materials never sell through the till, even if a price leaked in.
    isSellable: catalogRow.itemType != 'raw_material' && sellingPrice != null,
    itemType: catalogRow.itemType,
    // The backend has no `track_stock` column — this mirrors the entry-choice
    // step's own default (`ItemFormNotifier.chooseType`) rather than falling
    // back to `InventoryItem`'s `true` default. Without this, every synced
    // `sellable` item would come back "tracked" with a 0 on-hand quantity (no
    // stock-level row is ever created for a prepared-to-order dish) and
    // read as out of stock — unsellable at the till the moment it syncs,
    // even though it was never meant to carry a stock count at all.
    trackStock: catalogRow.itemType != 'sellable',
    reorderQuantity: _toDouble(catalogRow.reorderQuantity),
    allowNegativeStock: catalogRow.allowNegativeStock,
  );
}
