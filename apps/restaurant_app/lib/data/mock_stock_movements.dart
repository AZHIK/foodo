import 'dart:math' as math;

import '../models/inventory_item.dart';
import '../models/stock_movement.dart';
import '../models/store_location.dart';
import 'mock_staff.dart';

/// Generates a believable stock ledger for each item.
///
/// Built by walking *backwards* from the item's current stock: the newest
/// movement's balance is the number the Inventory table shows, and every
/// earlier balance is derived from the one after it. That is what keeps the
/// history reconciled with the item — a forward-generated ledger would drift
/// away from the count on the shelf immediately.
abstract final class MockStockMovements {
  /// Seeded per item id, so an item's history is the same on every launch and
  /// across hot reloads. A shared Random would make the ledger depend on the
  /// order items happen to be generated in.
  static math.Random _randomFor(String itemId) =>
      math.Random(itemId.hashCode & 0x7fffffff);

  static const _wasteReasons = [
    'Expired',
    'Spoiled in storage',
    'Prep error',
    'Dropped during service',
  ];

  static const _adjustmentReasons = [
    'Recount after stocktake',
    'Corrected mis-key',
    'Supplier short-delivered',
    'Found in cold room',
  ];

  /// How many movements to generate for one item.
  static const _minEntries = 5;
  static const _maxEntries = 9;

  static List<StockMovement> forItem(InventoryItem item) {
    final rand = _randomFor(item.id);
    final handlers = MockStaff.stockHandlerNames(MockStaff.roles);
    final destinations = <StoreLocation>[]; // No mock stores available

    // Sets the size of a plausible movement for this line: a 210-egg item
    // moves in dozens, a 3-wheel parmesan line moves in ones.
    final scale = math.max(2, item.reorderLevel);

    final movements = <StockMovement>[];
    var balance = item.stock;
    var at = DateTime.now().subtract(
      Duration(hours: 2 + rand.nextInt(20), minutes: rand.nextInt(60)),
    );

    final count = _minEntries + rand.nextInt(_maxEntries - _minEntries + 1);

    for (var i = 0; i < count; i++) {
      var type = _pickType(rand);

      // A positive movement cannot be larger than the balance it produced, or
      // the stock level before it would have been negative.
      final headroom = balance;
      if (_isIncrease(type) && headroom <= 0) {
        // Nothing to unwind — this item ran down to where it is, so the
        // movement that got it here has to be an outgoing one.
        type = rand.nextBool() ? StockMovementType.sale : StockMovementType.waste;
      }

      final delta = _delta(
        rand: rand,
        type: type,
        scale: scale,
        headroom: headroom,
      );

      movements.add(
        StockMovement(
          id: '${item.id}-mv-${(count - i).toString().padLeft(2, '0')}',
          itemId: item.id,
          at: at,
          type: type,
          delta: delta,
          balance: balance,
          actor: type == StockMovementType.sale
              // POS deductions are automatic; naming a person for them would
              // imply someone counted the shelf.
              ? 'System'
              : handlers[rand.nextInt(handlers.length)],
          note: _note(
            rand: rand,
            type: type,
            item: item,
            destinations: destinations,
          ),
        ),
      );

      // Step back to the balance this movement started from, and to a plausible
      // earlier timestamp.
      balance -= delta;
      at = at.subtract(
        Duration(
          hours: 6 + rand.nextInt(54),
          minutes: rand.nextInt(60),
        ),
      );
    }

    return movements;
  }

  /// Every item's ledger, flattened — the shape a real endpoint would return.
  static List<StockMovement> forItems(List<InventoryItem> items) => [
    for (final item in items) ...forItem(item),
  ];

  static bool _isIncrease(StockMovementType type) =>
      type == StockMovementType.restock;

  /// Weighted so sales dominate, which is what a real ledger looks like.
  static StockMovementType _pickType(math.Random rand) {
    final roll = rand.nextInt(100);
    return switch (roll) {
      < 42 => StockMovementType.sale,
      < 68 => StockMovementType.restock,
      < 80 => StockMovementType.waste,
      < 92 => StockMovementType.adjustment,
      _ => StockMovementType.transfer,
    };
  }

  static int _delta({
    required math.Random rand,
    required StockMovementType type,
    required int scale,
    required int headroom,
  }) {
    switch (type) {
      case StockMovementType.restock:
        // Capped at the balance it produced, so unwinding it never goes below
        // zero. Restocks are the largest movements a line sees.
        final want = (scale * 0.6).round() + rand.nextInt(math.max(1, scale));
        return math.max(1, math.min(want, headroom));

      case StockMovementType.sale:
        return -math.max(1, 1 + rand.nextInt(math.max(1, (scale * 0.4).round())));

      case StockMovementType.waste:
        return -math.max(1, 1 + rand.nextInt(math.max(1, (scale * 0.2).round())));

      case StockMovementType.transfer:
        return -math.max(1, 1 + rand.nextInt(math.max(1, (scale * 0.3).round())));

      case StockMovementType.adjustment:
        final size = 1 + rand.nextInt(math.max(1, (scale * 0.25).round()));
        // Corrections cut both ways, but an upward one is still bounded by the
        // balance it left behind.
        if (rand.nextBool()) return -size;
        return math.max(1, math.min(size, headroom));
    }
  }

  static String? _note({
    required math.Random rand,
    required StockMovementType type,
    required InventoryItem item,
    required List<StoreLocation> destinations,
  }) {
    return switch (type) {
      StockMovementType.restock =>
        'PO-${4200 + rand.nextInt(700)} · ${item.supplier}',
      StockMovementType.sale => 'Order #${1000 + rand.nextInt(90)}',
      StockMovementType.waste => _wasteReasons[rand.nextInt(_wasteReasons.length)],
      StockMovementType.adjustment =>
        _adjustmentReasons[rand.nextInt(_adjustmentReasons.length)],
      StockMovementType.transfer => destinations.isEmpty
          ? 'Transferred out'
          : 'To ${destinations[rand.nextInt(destinations.length)].name}',
    };
  }
}
