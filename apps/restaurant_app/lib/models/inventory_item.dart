import 'dart:typed_data';

import 'package:flutter/material.dart';

/// A picked product photo, held in memory.
///
/// Bytes rather than a path because the app runs on web as well as desktop and
/// mobile, and `dart:io` is not available there — [Image.memory] is the one
/// renderer that works on every target. A real build would upload these and
/// keep a URL instead.
@immutable
class ItemImage {
  const ItemImage({required this.name, required this.bytes});

  /// Original file name, so the form can show what was picked.
  final String name;

  final Uint8List bytes;
}

/// Where an item sits against its reorder level.
///
/// Derived from stock rather than stored, so it can never disagree with the
/// number next to it in the table.
enum StockStatus {
  inStock('In stock'),
  lowStock('Low stock'),
  outOfStock('Out of stock');

  const StockStatus(this.label);
  final String label;
}

/// A stockroom category. Separate from the menu's categories — flour and
/// napkins are inventory but never appear on a menu.
@immutable
class InventoryCategory {
  const InventoryCategory({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

/// A tracked stock line.
@immutable
class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.categoryId,
    required this.emoji,
    required this.stock,
    required this.reorderLevel,
    required this.unitCost,
    this.unit = 'ea',
    this.supplier = 'House',
    this.description = '',
    this.lastCountedAt,
    this.image,
    this.trackStock = true,
    this.isArchived = false,
    this.catalogItemId,
    this.sellingPrice,
    this.isSellable = false,
    this.itemType = 'both',
    this.reorderQuantity = 0,
    this.allowNegativeStock = false,
  });

  final String id;
  final String sku;
  final String name;
  final String categoryId;

  /// Stands in for product photography, keeping the UI fully offline.
  final String emoji;

  /// On-hand quantity. A `double`, not an `int` — Inventory Service tracks
  /// quantities to 3 decimal places so weight/volume units (kg, L) don't get
  /// truncated.
  final double stock;

  /// At or below this, the item needs reordering.
  final double reorderLevel;

  final double unitCost;

  /// "kg", "L", "ea" — shown next to the quantity so a count is unambiguous.
  final String unit;

  final String supplier;

  /// Free text about the line — grade, origin, prep notes. Optional, and empty
  /// for plenty of items, so anything rendering it has to handle the blank.
  final String description;

  final DateTime? lastCountedAt;

  /// Product photo, when one has been uploaded. [emoji] is the fallback.
  final ItemImage? image;

  /// False for items counted by eye rather than by unit — a bottomless
  /// condiment, a service charge line. Their stock numbers are meaningless, so
  /// the reorder machinery has to leave them alone.
  final bool trackStock;

  /// Archived items stay in the data for historical reporting but are not
  /// meant to be reordered or put on new tickets.
  final bool isArchived;

  /// Link to the cached inventory item (for sync layer).
  /// Optional: populated when this item is linked to the catalog.
  final String? catalogItemId;

  /// Price charged when this item is sold through the POS. Null means the
  /// item has never had a price set and cannot appear on the POS menu.
  final double? sellingPrice;

  /// Whether this item is eligible to appear on the POS menu — true only for
  /// items the backend marked sellable (or "both") that also carry a
  /// [sellingPrice]. Raw materials and priceless items never show at the till.
  final bool isSellable;

  /// The backend's item-type discriminator: `sellable`, `raw_material`, or
  /// `both`. Drives which of the Inventory section's two views (Groceries,
  /// Menu Items) this item appears in — it is never forced into just one,
  /// since a `both` item (a bottled drink bought and resold unchanged) is
  /// genuinely both a stockroom line and a till item.
  final String itemType;

  /// How much to reorder when this line falls below [reorderLevel]. Distinct
  /// from the threshold itself — a case-lot item might trigger a reorder at 5
  /// units but always reorder 24 at a time.
  final double reorderQuantity;

  /// Whether this line is allowed to go below zero — a tab kept for an item
  /// sold before its delivery is logged, rather than blocking the sale.
  final bool allowNegativeStock;

  /// Whether this item belongs in the Groceries (raw-material) view — every
  /// item except a pure `sellable` one.
  bool get isGroceryItem => itemType != 'sellable';

  /// Whether this item belongs in the Menu Items (sellable) view — every item
  /// except a pure `raw_material` one.
  bool get isMenuCatalogItem => itemType != 'raw_material';

  /// An untracked item is never "low": there is no count to be low against, so
  /// it reports as in stock rather than dragging the low-stock metric down.
  StockStatus get status => !trackStock
      ? StockStatus.inStock
      : switch (stock) {
          <= 0 => StockStatus.outOfStock,
          _ when stock <= reorderLevel => StockStatus.lowStock,
          _ => StockStatus.inStock,
        };

  /// What this line is worth at cost — the basis for the inventory value
  /// metric. Retail value would need a margin the stockroom does not know.
  double get totalValue => stock * unitCost;

  InventoryItem copyWith({
    String? sku,
    String? name,
    String? categoryId,
    String? emoji,
    double? stock,
    double? reorderLevel,
    double? unitCost,
    String? unit,
    String? supplier,
    String? description,
    DateTime? lastCountedAt,
    ItemImage? image,
    bool? trackStock,
    bool? isArchived,
    String? catalogItemId,
    double? sellingPrice,
    bool? isSellable,
    String? itemType,
    double? reorderQuantity,
    bool? allowNegativeStock,
    // `image: null` cannot mean "remove it" when null already means "leave it
    // alone", so clearing needs its own flag.
    bool clearImage = false,
    bool clearCatalogItemId = false,
    bool clearSellingPrice = false,
  }) {
    return InventoryItem(
      id: id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      emoji: emoji ?? this.emoji,
      stock: stock ?? this.stock,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      unitCost: unitCost ?? this.unitCost,
      unit: unit ?? this.unit,
      supplier: supplier ?? this.supplier,
      description: description ?? this.description,
      lastCountedAt: lastCountedAt ?? this.lastCountedAt,
      image: clearImage ? null : (image ?? this.image),
      trackStock: trackStock ?? this.trackStock,
      isArchived: isArchived ?? this.isArchived,
      catalogItemId: clearCatalogItemId
          ? null
          : (catalogItemId ?? this.catalogItemId),
      sellingPrice: clearSellingPrice
          ? null
          : (sellingPrice ?? this.sellingPrice),
      isSellable: isSellable ?? this.isSellable,
      itemType: itemType ?? this.itemType,
      reorderQuantity: reorderQuantity ?? this.reorderQuantity,
      allowNegativeStock: allowNegativeStock ?? this.allowNegativeStock,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is InventoryItem && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
