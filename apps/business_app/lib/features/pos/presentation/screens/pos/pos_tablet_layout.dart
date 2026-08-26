import 'package:flutter/material.dart';

import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../widgets/pos_cart_view.dart';
import '../../widgets/pos_catalog_view.dart';
import '../../widgets/pos_layout_model.dart';

/// POS at tablet width (600–899px).
///
/// Two panels fit here, but barely: at this tier [MainShell] is already
/// showing its icon rail, so the usable body can be as little as ~500px.
/// Everything is therefore tuned for density rather than comfort —
/// a single-line header with a short-label action, a cart column sized as a
/// *fraction* of the real available width (never a fixed 320px that would
/// starve the grid at 600px), compact cart rows with no thumbnail, and
/// smaller product tiles.
///
/// No [Scaffold]/[AppBar] of its own — the shell rail supplies the chrome
/// at this width.
class PosTabletLayout extends StatelessWidget {
  const PosTabletLayout({super.key, required this.model});

  final PosLayoutModel model;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Proportional, clamped: keeps the ticket readable without
          // collapsing the catalog to one column on a 600px device.
          final cartWidth = (constraints.maxWidth * 0.38).clamp(230.0, 300.0);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _CatalogPanel(model: model)),
              const SizedBox(width: AppDimensions.spaceMD),
              SizedBox(width: cartWidth, child: _CartPanel(model: model)),
            ],
          );
        },
      ),
    );
  }
}

class _CatalogPanel extends StatelessWidget {
  const _CatalogPanel({required this.model});

  final PosLayoutModel model;

  @override
  Widget build(BuildContext context) {
    return AppCard.elevated(
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Point of Sale',
                  style: AppTextStyles.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Short label rather than desktop's "Sales History" — the
              // header shares a single line with the title here.
              AppSecondaryButton(
                label: 'Sales',
                icon: Icons.history_outlined,
                expanded: false,
                onPressed: model.onOpenSalesHistory,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          PosCatalogFilters(model: model, searchHint: 'Search products'),
          const SizedBox(height: AppDimensions.spaceMD),
          Expanded(
            child: PosProductGrid(
              items: model.items,
              onItemSelected: model.onItemSelected,
              minTileWidth: 140,
              maxColumns: 3,
              childAspectRatio: 0.68,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartPanel extends StatelessWidget {
  const _CartPanel({required this.model});

  final PosLayoutModel model;

  @override
  Widget build(BuildContext context) {
    return AppCard.elevated(
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Current Sale', style: AppTextStyles.titleLarge),
              ),
              StatusBadge(
                label: '${model.lines.length}',
                variant: StatusBadgeVariant.info,
                size: StatusBadgeSize.compact,
              ),
              if (model.hasCart)
                IconButton(
                  onPressed: model.onClearCart,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'Clear cart',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMD),
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
                        // No thumbnail at this width — the column is too
                        // narrow to spend 44px on a placeholder icon.
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
          const SizedBox(height: AppDimensions.spaceMD),
          AppPrimaryButton(
            label: 'Complete Sale',
            icon: Icons.payments_outlined,
            onPressed: model.hasCart ? model.onCompleteSale : null,
          ),
        ],
      ),
    );
  }
}
