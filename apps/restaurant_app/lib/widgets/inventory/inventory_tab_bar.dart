import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../../theme/breakpoints.dart';

/// Which of the Inventory section's two views is showing. Mirrors
/// [FinanceTab] — Groceries and Menu Items are two different mental models
/// over the same underlying catalog, the same way Other Expenses and Other
/// Incomes are two views over Finance's ledger.
enum InventoryTab { groceries, menuItems }

/// The segmented control that switches between Groceries and Menu Items.
///
/// Reuses Finance's sub-navigation pattern exactly — a [SegmentedButton]
/// above the page body, driving `context.replace` between two sibling routes
/// nested under the same shell branch — rather than a `TabBar`/tab
/// controller or a filter chip on one shared table. The two views really do
/// have different columns and different stats; a filter would paper over
/// that they are different screens.
class InventoryTabBar extends StatelessWidget {
  const InventoryTabBar({super.key, required this.active});

  final InventoryTab active;

  @override
  Widget build(BuildContext context) {
    final pad = Insets.page(context.formFactor);

    return Padding(
      padding: EdgeInsets.fromLTRB(pad, Insets.md, pad, Insets.md),
      child: SegmentedButton<InventoryTab>(
        segments: const [
          ButtonSegment(
            value: InventoryTab.groceries,
            label: Text('Groceries'),
            icon: Icon(Icons.shopping_basket_outlined),
          ),
          ButtonSegment(
            value: InventoryTab.menuItems,
            label: Text('Menu items'),
            icon: Icon(Icons.restaurant_menu_rounded),
          ),
        ],
        selected: {active},
        onSelectionChanged: (selected) {
          final tab = selected.first;
          if (tab == InventoryTab.groceries) {
            context.replace(AppRoute.groceries());
          } else {
            context.replace(AppRoute.menuItems());
          }
        },
      ),
    );
  }
}
