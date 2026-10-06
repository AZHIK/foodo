/// Cost-of-goods math shared by every profit figure in the app.
///
/// A sellable's true cost is its recipe's [costPerUnit] at current raw
/// prices; items with no recipe fall back to their own [unitCost] (correct
/// for bought-and-resold goods like bottled drinks, zero for prepared
/// dishes with no formula yet). Anything with neither is costed at zero
/// and flagged `estimated` so the UI can say so instead of pretending.
///
/// All money here is [Decimal] — dashboards convert at the edge with
/// `double.parse(x.toString())` rather than accumulating in doubles.
library;

import 'package:decimal/decimal.dart';

/// One unit's cost plus whether that number is a guess.
class UnitCost {
  const UnitCost(this.cost, {this.estimated = false});

  final Decimal cost;
  final bool estimated;
}

/// Index recipes and fallback items once, then cost many lines cheaply.
class CogsIndex {
  CogsIndex({
    required this._recipeCost,
    required this._recipeComplete,
    required this._fallbackCost,
  });

  final Map<String, Decimal> _recipeCost;
  final Map<String, bool> _recipeComplete;
  final Map<String, Decimal> _fallbackCost;

  UnitCost unitCostFor(String itemId) {
    final recipe = _recipeCost[itemId];
    if (recipe != null) {
      return UnitCost(
        recipe,
        estimated: _recipeComplete[itemId] == false,
      );
    }
    final fallback = _fallbackCost[itemId];
    if (fallback != null && fallback != Decimal.zero) {
      return UnitCost(fallback);
    }
    return UnitCost(Decimal.zero, estimated: true);
  }

  /// `quantityByItemId` maps item id → units sold.
  ({Decimal cogs, bool estimated}) cogsForQuantities(
    Map<String, Decimal> quantityByItemId,
  ) {
    var cogs = Decimal.zero;
    var estimated = false;
    quantityByItemId.forEach((itemId, qty) {
      if (qty == Decimal.zero) return;
      final unit = unitCostFor(itemId);
      if (unit.cost != Decimal.zero) {
        cogs += unit.cost * qty;
      } else if (qty != Decimal.zero) {
        // Zero-cost sale still makes the total an estimate when the
        // formula is missing entirely.
        estimated = true;
      }
      if (unit.estimated) estimated = true;
    });
    return (cogs: cogs, estimated: estimated);
  }
}
