import 'package:flutter/material.dart';

import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../widgets/pos_cart_view.dart';
import '../../widgets/pos_catalog_view.dart';
import '../../widgets/pos_layout_model.dart';

/// POS at phone width (<600px).
///
/// One column is all there is, so browsing and the ticket are separate
/// destinations behind a segmented control rather than two squeezed panels.
/// The running total and the primary action live in a persistent bottom bar
/// so the cashier can check out from either tab without hunting for a
/// button — that bar is the *only* place "Complete Sale" appears on phones.
///
/// This is the one tier that supplies its own [Scaffold]/[AppBar]: at phone
/// width [MainShell] gives the app bottom navigation and no side rail, so
/// screen-level actions (sales history, clear cart) have nowhere else to go.
class PosMobileLayout extends StatefulWidget {
  const PosMobileLayout({super.key, required this.model});

  final PosLayoutModel model;

  @override
  State<PosMobileLayout> createState() => _PosMobileLayoutState();
}

class _PosMobileLayoutState extends State<PosMobileLayout> {
  static const int _browseTab = 0;
  static const int _cartTab = 1;

  int _tab = _browseTab;

  @override
  void didUpdateWidget(PosMobileLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Emptying the cart (checkout, or "Clear") leaves the cart tab with
    // nothing to show — fall back to browsing instead of a dead end.
    if (_tab == _cartTab && !widget.model.hasCart) {
      _tab = _browseTab;
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS'),
        actions: [
          IconButton(
            onPressed: model.onOpenSalesHistory,
            icon: const Icon(Icons.history_outlined),
            tooltip: 'Sales history',
          ),
          if (model.hasCart)
            IconButton(
              onPressed: model.onClearCart,
              icon: const Icon(Icons.remove_shopping_cart_outlined),
              tooltip: 'Clear cart',
            ),
          const SizedBox(width: AppDimensions.spaceXS),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spaceMD,
              AppDimensions.spaceSM,
              AppDimensions.spaceMD,
              0,
            ),
            child: SegmentedButton<int>(
              segments: [
                const ButtonSegment<int>(
                  value: _browseTab,
                  label: Text('Browse'),
                  icon: Icon(Icons.grid_view_rounded),
                ),
                ButtonSegment<int>(
                  value: _cartTab,
                  label: Text('Cart (${model.cartQuantity})'),
                  icon: const Icon(Icons.receipt_long_outlined),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (selection) =>
                  setState(() => _tab = selection.first),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.spaceMD),
                  child: _BrowseTab(model: model),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.spaceMD),
                  child: _CartTab(model: model),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _CheckoutBar(model: model),
    );
  }
}

class _BrowseTab extends StatelessWidget {
  const _BrowseTab({required this.model});

  final PosLayoutModel model;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PosCatalogFilters(model: model, searchHint: 'Search items or SKU'),
        const SizedBox(height: AppDimensions.spaceMD),
        Expanded(
          child: PosProductGrid(
            items: model.items,
            onItemSelected: model.onItemSelected,
            // Two columns on a phone; tiles get taller relative to their
            // width so the name still fits on a narrow card.
            minTileWidth: 150,
            maxColumns: 2,
            childAspectRatio: 0.78,
            spacing: AppDimensions.spaceMD,
          ),
        ),
      ],
    );
  }
}

class _CartTab extends StatelessWidget {
  const _CartTab({required this.model});

  final PosLayoutModel model;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: model.lines.isEmpty
              ? const PosEmptyCart()
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: model.lines.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppDimensions.spaceSM),
                  itemBuilder: (context, index) {
                    final line = model.lines[index];
                    return PosCartLineTile(
                      line: line,
                      variant: PosCartLineVariant.compact,
                      onQuantityChanged: (quantity) =>
                          model.onQuantityChanged(line.item.id, quantity),
                      onRemoved: () => model.onLineRemoved(line.item.id),
                      onDiscountChanged: (discount) =>
                          model.onLineDiscountChanged(line.item.id, discount),
                    );
                  },
                ),
        ),
        const SizedBox(height: AppDimensions.spaceMD),
        PosTicketSummary(
          subtotalSenti: model.subtotalSenti,
          saleDiscountSenti: model.saleDiscountSenti,
          taxSenti: model.taxSenti,
          totalSenti: model.totalSenti,
          onSaleDiscountChanged: model.onSaleDiscountChanged,
        ),
      ],
    );
  }
}

/// Persistent total + checkout bar, visible from both tabs.
class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.model});

  final PosLayoutModel model;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spaceMD),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${model.cartQuantity} item'
                    '${model.cartQuantity == 1 ? '' : 's'}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    MoneyField.formatDisplay(model.totalSenti),
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spaceMD),
            AppPrimaryButton(
              label: 'Complete Sale',
              icon: Icons.payments_outlined,
              expanded: false,
              onPressed: model.hasCart ? model.onCompleteSale : null,
            ),
          ],
        ),
      ),
    );
  }
}
