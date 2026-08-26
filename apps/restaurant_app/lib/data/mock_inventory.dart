import 'package:flutter/material.dart';

import '../models/inventory_item.dart';

/// In-memory stand-in for a stock service.
///
/// Swap this for an HTTP/DB implementation and only
/// `lib/providers/inventory_provider.dart` needs to change.
abstract final class MockInventory {
  static const categories = <InventoryCategory>[
    InventoryCategory(
      id: 'produce',
      label: 'Produce',
      icon: Icons.eco_outlined,
    ),
    InventoryCategory(
      id: 'meat',
      label: 'Meat & Fish',
      icon: Icons.set_meal_outlined,
    ),
    InventoryCategory(
      id: 'dairy',
      label: 'Dairy',
      icon: Icons.egg_outlined,
    ),
    InventoryCategory(
      id: 'dry',
      label: 'Dry goods',
      icon: Icons.grain_outlined,
    ),
    InventoryCategory(
      id: 'drinks',
      label: 'Beverages',
      icon: Icons.local_bar_outlined,
    ),
    InventoryCategory(
      id: 'supplies',
      label: 'Supplies',
      icon: Icons.inventory_2_outlined,
    ),
  ];

  /// Units a stock line can be counted in. A closed list rather than free text
  /// so "kg" and "Kg" cannot end up as two different units in the same table.
  static const units = <String>['ea', 'kg', 'L', 'bunch', 'case', 'keg', 'jar'];

  static InventoryCategory? categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  static String categoryLabel(String id) => categoryById(id)?.label ?? id;

  /// Deliberately mixed: enough healthy stock to look normal, a realistic
  /// tail of low and out-of-stock lines so the filters and badges have
  /// something to show.
  static final List<InventoryItem> items = <InventoryItem>[
    _item('inv-01', 'PRD-1001', 'Heirloom Tomatoes', 'produce', '🍅', 42, 15, 3.80, 'kg', 'Mixed heritage varieties from Fenwick Farm. Ripen at room temperature; never refrigerate.'),
    _item('inv-02', 'PRD-1002', 'Baby Spinach', 'produce', '🥬', 12, 14, 5.20, 'kg'),
    _item('inv-03', 'PRD-1003', 'Lemons', 'produce', '🍋', 88, 20, 0.45, 'ea'),
    _item('inv-04', 'PRD-1004', 'Avocados', 'produce', '🥑', 0, 24, 1.65, 'ea', 'Hass, ripened to order. Check daily — the window between firm and soft is about 36 hours.'),
    _item('inv-05', 'PRD-1005', 'Wild Mushrooms', 'produce', '🍄', 7, 8, 14.50, 'kg', 'Seasonal mix: chanterelle, oyster, king trumpet. Brush clean, never rinse.'),
    _item('inv-06', 'PRD-1006', 'Red Onions', 'produce', '🧅', 64, 25, 1.10, 'kg'),
    _item('inv-07', 'PRD-1007', 'Fresh Basil', 'produce', '🌿', 9, 6, 2.75, 'bunch'),

    _item('inv-08', 'MTF-2001', 'Ribeye Steak', 'meat', '🥩', 26, 12, 28.40, 'kg', '35-day dry-aged, cut to 280g portions in house. Trim goes to the stock pot.'),
    _item('inv-09', 'MTF-2002', 'Chicken Breast', 'meat', '🍗', 55, 20, 9.80, 'kg'),
    _item('inv-10', 'MTF-2003', 'Atlantic Salmon', 'meat', '🐟', 11, 12, 22.90, 'kg', 'Line-caught, delivered whole on Tuesdays and Fridays. Pin-boned on arrival.'),
    _item('inv-11', 'MTF-2004', 'Octopus', 'meat', '🐙', 0, 5, 19.75, 'kg', 'Frozen at sea, 1.5–2kg. Needs 24h thaw plus a 45-minute braise before service.'),
    _item('inv-12', 'MTF-2005', 'Tiger Prawns', 'meat', '🦐', 18, 10, 26.00, 'kg'),
    _item('inv-13', 'MTF-2006', 'Pancetta', 'meat', '🥓', 6, 6, 17.30, 'kg'),

    _item('inv-14', 'DRY-3001', 'Burrata', 'dairy', '🧀', 24, 10, 6.90, 'ea'),
    _item('inv-15', 'DRY-3002', 'Parmesan Wheel', 'dairy', '🧀', 3, 2, 89.00, 'ea', '24-month Reggiano, whole wheel. Rind reserved for the minestrone.'),
    _item('inv-16', 'DRY-3003', 'Unsalted Butter', 'dairy', '🧈', 40, 15, 4.25, 'kg'),
    _item('inv-17', 'DRY-3004', 'Free-range Eggs', 'dairy', '🥚', 210, 60, 0.32, 'ea', 'Free-range, size medium. Supplier rotates stock weekly, so check the date on the tray.'),
    _item('inv-18', 'DRY-3005', 'Double Cream', 'dairy', '🥛', 13, 14, 3.10, 'L'),

    _item('inv-19', 'GDS-4001', 'Arborio Rice', 'dry', '🍚', 48, 20, 3.95, 'kg'),
    _item('inv-20', 'GDS-4002', '00 Flour', 'dry', '🌾', 72, 25, 1.85, 'kg'),
    _item('inv-21', 'GDS-4003', 'Black Truffle Paste', 'dry', '🫙', 4, 4, 62.00, 'jar', 'Winter black truffle, 12% paste. Open jars keep 5 days refrigerated.'),
    _item('inv-22', 'GDS-4004', 'Olive Oil (EV)', 'dry', '🫒', 31, 12, 11.40, 'L', 'First cold press, single estate. Finishing oil only — do not use for frying.'),
    _item('inv-23', 'GDS-4005', 'Sea Salt Flakes', 'dry', '🧂', 19, 8, 6.20, 'kg'),
    _item('inv-24', 'GDS-4006', 'Dark Chocolate 70%', 'dry', '🍫', 0, 6, 13.80, 'kg'),

    _item('inv-25', 'BEV-5001', 'House Red (Case)', 'drinks', '🍷', 22, 8, 96.00, 'case', 'House Tempranillo blend, 12 bottles per case. Two cases held back for functions.'),
    _item('inv-26', 'BEV-5002', 'Craft Lager (Keg)', 'drinks', '🍺', 5, 6, 128.00, 'keg', '30L keg, rotates with the seasonal tap. Line cleaned every second Monday.'),
    _item('inv-27', 'BEV-5003', 'Espresso Beans', 'drinks', '☕', 27, 10, 18.60, 'kg', 'Medium roast, ground fresh per service. Discard any beans open longer than 10 days.'),
    _item('inv-28', 'BEV-5004', 'Sparkling Water', 'drinks', '🥤', 144, 48, 0.68, 'ea'),
    _item('inv-29', 'BEV-5005', 'Tonic Water', 'drinks', '🧴', 9, 24, 0.74, 'ea'),

    _item('inv-30', 'SUP-6001', 'Takeaway Boxes', 'supplies', '📦', 320, 100, 0.22, 'ea', 'Compostable kraft, three sizes nested. Reorder before a bank holiday weekend.'),
    _item('inv-31', 'SUP-6002', 'Napkins', 'supplies', '🧻', 68, 80, 0.04, 'ea'),
    _item('inv-32', 'SUP-6003', 'Cleaning Degreaser', 'supplies', '🧽', 14, 6, 7.95, 'L'),
    _item('inv-33', 'SUP-6004', 'Nitrile Gloves', 'supplies', '🧤', 0, 20, 0.11, 'ea', 'Powder-free, size L. Kitchen and cleaning both draw from this line.'),
    _item('inv-34', 'SUP-6005', 'Receipt Rolls', 'supplies', '🧾', 46, 15, 1.35, 'ea'),
  ];

  static InventoryItem _item(
    String id,
    String sku,
    String name,
    String categoryId,
    String emoji,
    int stock,
    int reorderLevel,
    double unitCost,
    String unit, [
    // Optional and genuinely empty for most lines — a real catalogue is
    // described where it matters and blank everywhere else, and the detail
    // screen has to handle both.
    String description = '',
  ]) {
    return InventoryItem(
      id: id,
      sku: sku,
      name: name,
      categoryId: categoryId,
      emoji: emoji,
      stock: stock,
      reorderLevel: reorderLevel,
      unitCost: unitCost,
      unit: unit,
      description: description,
    );
  }
}
