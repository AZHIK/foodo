import 'package:flutter/material.dart';

import '../widgets/data_page/status_badge.dart';

/// Why a stock number changed.
///
/// Every movement carries one, because "the count went down by six" is not an
/// auditable fact on its own — a sale, a spill and a transfer are three very
/// different conversations with a supplier.
enum StockMovementType {
  restock('Restock'),
  sale('Sale'),
  waste('Waste'),
  adjustment('Adjustment'),
  transfer('Transfer');

  const StockMovementType(this.label);
  final String label;

  IconData get icon => switch (this) {
    StockMovementType.restock => Icons.local_shipping_outlined,
    StockMovementType.sale => Icons.point_of_sale_outlined,
    StockMovementType.waste => Icons.delete_sweep_outlined,
    StockMovementType.adjustment => Icons.tune_rounded,
    StockMovementType.transfer => Icons.swap_horiz_rounded,
  };

  /// Maps onto the shared badge tones, the same way `StockStatus` does — the
  /// badge widget stays free of stockroom vocabulary.
  StatusTone get tone => switch (this) {
    StockMovementType.restock => StatusTone.positive,
    StockMovementType.sale => StatusTone.info,
    StockMovementType.waste => StatusTone.danger,
    StockMovementType.adjustment => StatusTone.neutral,
    StockMovementType.transfer => StatusTone.warning,
  };
}

/// One entry in an item's stock ledger.
///
/// [balance] is stored rather than recomputed: a ledger that recalculates its
/// own running total cannot show a discrepancy, which is the one thing a stock
/// audit is looking for.
@immutable
class StockMovement {
  const StockMovement({
    required this.id,
    required this.itemId,
    required this.at,
    required this.type,
    required this.delta,
    required this.balance,
    required this.actor,
    this.note,
  });

  final String id;
  final String itemId;
  final DateTime at;
  final StockMovementType type;

  /// Signed change. Negative for sales, waste and transfers out.
  final int delta;

  /// Stock level immediately after this movement.
  final int balance;

  /// Who performed it — a staff member's name, or "System" for automatic
  /// deductions such as a POS sale.
  final String actor;

  /// Free text: a waste reason, a transfer destination, a recount note.
  final String? note;

  /// "+12" / "−6", with a true minus sign rather than a hyphen.
  String get deltaLabel => delta >= 0 ? '+$delta' : '−${delta.abs()}';
}
