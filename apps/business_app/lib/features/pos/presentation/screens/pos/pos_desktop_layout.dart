import 'package:flutter/material.dart';

import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../widgets/pos_cart_view.dart';
import '../../widgets/pos_catalog_view.dart';
import '../../widgets/pos_layout_model.dart';

/// POS at desktop width (>=900px).
///
/// Same two-panel skeleton as the tablet tier — deliberately, so crossing
/// 900px while resizing is a density change and not a structural rebuild —
/// but with the room to spend: a titled header with breadcrumb and a
/// full-label action, a wider ticket column, roomier product tiles, and
/// detailed cart rows (thumbnail, inline `unit × qty = total`, corner
/// remove button).
///
/// No [Scaffold]/[AppBar] of its own — [MainShell]'s expanded sidebar is
/// the chrome at this width.
///
/// Deviations from the design reference, and why:
/// - The reference's "+New / QR Menu Orders / Draft List / Table Order"
///   row collapses to the one action that exists in this app —
///   "Sales History". No fabricated table/QR-ordering buttons.
/// - "Select Dining" / "Select Table" are omitted — no table-management
///   concept exists here.
/// - "Search in Existing" (searching within the cart) is omitted — not a
///   useful affordance for a cart that is rarely more than a few lines.
/// - The reference's four discount rows collapse to the one sale-level
///   discount this data model supports ([PosTicketSummary]); per-line
///   discounts remain as the small action on each cart row, filling the
///   slot the reference gave a non-functional "Add Notes" link.
/// - The bottom action row loses "KOT & Print" (no kitchen-ticket
///   workflow), "Draft" (no saved carts yet), and "Bill & Print" (in-app
///   only per the SRS). Only "Complete Sale" remains, mapped to the
///   reference's "Bill & Payment" primary action.
class PosDesktopLayout extends StatelessWidget {
  const PosDesktopLayout({super.key, required this.model});

  final PosLayoutModel model;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cartWidth = (constraints.maxWidth * 0.28).clamp(300.0, 380.0);
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
    final cs = Theme.of(context).colorScheme;
    return AppCard.elevated(
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Point of Sale (POS)',
                      style: AppTextStyles.headlineSmall,
                    ),
                    const SizedBox(height: AppDimensions.spaceXXS),
                    Text(
                      'Dashboard  •  POS',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              AppSecondaryButton(
                label: 'Sales History',
                icon: Icons.history_outlined,
                expanded: false,
                onPressed: model.onOpenSalesHistory,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceLG),
          // Search on its own full-width row; category filtering lives only
          // in the pill row below it — a separate category dropdown
          // duplicated the same filter with no real benefit.
          PosCatalogFilters(model: model, searchHint: 'Search in products'),
          const SizedBox(height: AppDimensions.spaceMD),
          Expanded(
            child: PosProductGrid(
              items: model.items,
              onItemSelected: model.onItemSelected,
              minTileWidth: 170,
              maxColumns: 5,
              childAspectRatio: 0.66,
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
    final cs = Theme.of(context).colorScheme;
    return AppCard.elevated(
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 20,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: AppDimensions.spaceXS),
              const Expanded(
                child: Text('Current Sale', style: AppTextStyles.titleLarge),
              ),
              StatusBadge(
                label: '${model.lines.length} items',
                variant: StatusBadgeVariant.info,
                size: StatusBadgeSize.compact,
              ),
              if (model.hasCart) ...[
                const SizedBox(width: AppDimensions.spaceXS),
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
                        variant: PosCartLineVariant.detailed,
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
