import 'package:flutter/material.dart';

import '../../../../shared/fakes/fake_data_service.dart';

/// One line of the in-progress ticket.
///
/// Lives in local widget state only — POS is offline-first and the ticket
/// has no server-side representation until payment completes.
class PosCartLine {
  const PosCartLine({
    required this.item,
    this.quantity = 1,
    this.discountSenti = 0,
  });

  final FakeInventoryItem item;
  final int quantity;
  final int discountSenti;

  int get grossTotalSenti => item.priceSenti * quantity;

  int get lineTotalSenti =>
      (grossTotalSenti - discountSenti).clamp(0, 1 << 62).toInt();

  PosCartLine copyWith({int? quantity, int? discountSenti}) {
    return PosCartLine(
      item: item,
      quantity: quantity ?? this.quantity,
      discountSenti: discountSenti ?? this.discountSenti,
    );
  }
}

/// Everything a POS form-factor layout needs: the already-filtered catalog,
/// the computed ticket totals, and the callbacks back into `PosScreen`'s
/// state.
///
/// The three layouts ([PosMobileLayout], [PosTabletLayout],
/// [PosDesktopLayout]) are pure presentation — all sale state and all
/// business math lives in `PosScreen` and is handed down through this one
/// object, so a layout can be rewritten for its form factor without
/// touching (or duplicating) ticket logic.
@immutable
class PosLayoutModel {
  const PosLayoutModel({
    required this.items,
    required this.categories,
    required this.selectedCategory,
    required this.searchController,
    required this.lines,
    required this.subtotalSenti,
    required this.saleDiscountSenti,
    required this.taxSenti,
    required this.totalSenti,
    required this.cartQuantity,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onItemSelected,
    required this.onQuantityChanged,
    required this.onLineRemoved,
    required this.onLineDiscountChanged,
    required this.onSaleDiscountChanged,
    required this.onClearCart,
    required this.onCompleteSale,
    required this.onOpenSalesHistory,
  });

  /// Catalog items already filtered by [selectedCategory] and the search
  /// query — layouts render this list as-is.
  final List<FakeInventoryItem> items;

  /// All selectable categories, `'All'` first.
  final List<String> categories;
  final String selectedCategory;
  final TextEditingController searchController;

  final List<PosCartLine> lines;
  final int subtotalSenti;
  final int saleDiscountSenti;
  final int taxSenti;
  final int totalSenti;

  /// Total units across all lines (not the number of lines) — used for the
  /// mobile cart badge.
  final int cartQuantity;

  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<FakeInventoryItem> onItemSelected;
  final void Function(String itemId, int quantity) onQuantityChanged;
  final ValueChanged<String> onLineRemoved;
  final void Function(String itemId, int discountSenti) onLineDiscountChanged;
  final ValueChanged<int> onSaleDiscountChanged;
  final VoidCallback onClearCart;
  final VoidCallback onCompleteSale;
  final VoidCallback onOpenSalesHistory;

  bool get hasCart => lines.isNotEmpty;
}
