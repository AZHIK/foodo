import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_inventory.dart';
import '../data/mock_stock_movements.dart';
import '../models/stock_movement.dart';

/// Owns the stock ledger for every item.
///
/// Separate from `inventoryItemsProvider` because the two answer different
/// questions — one holds what is on the shelf now, this holds how it got there.
/// The stock dialogs write to both, in that order, so a balance recorded here
/// always matches the item it was recorded against.
class StockMovementsNotifier extends Notifier<List<StockMovement>> {
  @override
  List<StockMovement> build() =>
      MockStockMovements.forItems(MockInventory.items);

  /// Appends a movement and returns it.
  ///
  /// [balanceAfter] is passed in rather than derived, because the caller has
  /// just computed the new stock level and clamping it twice in two places is
  /// how the ledger and the item drift apart.
  StockMovement record({
    required String itemId,
    required StockMovementType type,
    required int delta,
    required int balanceAfter,
    required String actor,
    String? note,
  }) {
    final movement = StockMovement(
      id: '$itemId-mv-${DateTime.now().microsecondsSinceEpoch}',
      itemId: itemId,
      at: DateTime.now(),
      type: type,
      delta: delta,
      balance: balanceAfter,
      actor: actor,
      note: note,
    );

    state = [movement, ...state];
    return movement;
  }

  /// Drops an item's whole ledger, for when the item itself is deleted.
  void clearForItem(String itemId) =>
      state = state.where((m) => m.itemId != itemId).toList();
}

final stockMovementsProvider =
    NotifierProvider<StockMovementsNotifier, List<StockMovement>>(
      StockMovementsNotifier.new,
    );

/// One item's ledger, newest first.
///
/// A family rather than a filter at the widget layer, so the detail screen
/// rebuilds only when *its* item's history changes.
final itemStockHistoryProvider =
    Provider.family<List<StockMovement>, String>((ref, itemId) {
      final movements = ref
          .watch(stockMovementsProvider)
          .where((m) => m.itemId == itemId)
          .toList();

      movements.sort((a, b) => b.at.compareTo(a.at));
      return movements;
    });
