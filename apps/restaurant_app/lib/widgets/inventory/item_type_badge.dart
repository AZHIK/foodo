import 'package:flutter/material.dart';

import '../../constants/app_strings.dart';
import '../../models/inventory_item.dart';
import '../data_page/status_badge.dart';

/// Plain-text label for an item's backend `item_type`.
///
/// Mirrors the About panel on the detail screen so the list, the detail
/// view and the exports all call the same thing the same name.
String itemTypeLabel(InventoryItem item) => switch (item.itemType) {
      'raw_material' => AppStrings.itemTypeGrocery,
      'sellable' => AppStrings.itemTypeMenuItem,
      _ => AppStrings.itemTypeBoth,
    };

/// Badge tone per type: groceries are neutral stockroom facts, menu items
/// use the informational tone, dual-use (`both`) lines get the positive
/// tone so they stand out in either list.
StatusTone itemTypeTone(InventoryItem item) => switch (item.itemType) {
      'raw_material' => StatusTone.neutral,
      'sellable' => StatusTone.info,
      _ => StatusTone.positive,
    };

/// Badge icon per type — same icons as the detail screen's About panel.
IconData itemTypeIcon(InventoryItem item) => switch (item.itemType) {
      'raw_material' => Icons.shopping_basket_outlined,
      'sellable' => Icons.restaurant_menu_rounded,
      _ => Icons.swap_horiz_rounded,
    };

/// Small pill showing whether a row is a Grocery, a Menu item, or both.
///
/// Shared by the Groceries and Menu Items tables so a `both` item (which
/// legitimately appears in both lists) is recognisable wherever it shows.
class ItemTypeBadge extends StatelessWidget {
  const ItemTypeBadge({super.key, required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      label: itemTypeLabel(item),
      tone: itemTypeTone(item),
      icon: itemTypeIcon(item),
      dense: true,
    );
  }
}
