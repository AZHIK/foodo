import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_strings.dart';
import '../../models/inventory_item.dart';
import '../../providers/requisition_cart_provider.dart';
import '../../providers/suppliers_provider.dart';
import '../../screens/purchasing/requisition_cart_dialog.dart';

/// Default quantity when an inventory line is sent to the order cart: the
/// item's own reorder quantity when one is set, else its reorder level,
/// else a single unit. Mirrors what the removed reorder dialog prefilled.
double orderCartDefaultQty(InventoryItem item) {
  if (item.reorderQuantity > 0) return item.reorderQuantity;
  if (item.reorderLevel > 0) return item.reorderLevel;
  return 1;
}

/// Adds an inventory line to the purchasing order cart and confirms with a
/// snackbar that opens the cart on tap.
///
/// Shared by the Groceries/Menu Items row menus and the item detail quick
/// actions so all three add the same line in the same way. Adding merges
/// into the existing cart line when the item is already there (see
/// `RequisitionCartNotifier.addItem`) — never a duplicate row.
///
/// The line arrives pre-assigned to the item's preferred supplier when one
/// resolves in the directory ([findPreferredSupplier]); otherwise it stays
/// unassigned. Either way the supplier stays changeable — per line via the
/// cart's supplier badge, or for every line at once via the bulk-assign bar.
void addItemToOrderCart(
  BuildContext context,
  WidgetRef ref,
  InventoryItem item,
) {
  final preferred = findPreferredSupplier(
      ref.read(suppliersListProvider), item.preferredSupplierId);
  ref.read(requisitionCartProvider.notifier).addItem(
        itemId: item.id,
        itemName: item.name,
        unit: item.unit,
        qty: orderCartDefaultQty(item),
        supplierId: preferred?.id,
        supplierName: preferred?.name,
        assignmentSource: preferred == null ? null : 'preferred',
      );
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(AppStrings.addedToOrderCart(item.name)),
      action: SnackBarAction(
        label: AppStrings.viewCartAction,
        onPressed: () => showRequisitionCart(context),
      ),
    ),
  );
}
