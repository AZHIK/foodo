import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../feedback/status_badge.dart';
import 'app_card.dart';

/// Stock-level semantics consumed by [ProductCard] to pick the right
/// status colour and label.
enum ProductStockStatus {
  inStock,
  lowStock,
  outOfStock,
}

/// Layout variant for [ProductCard].
///
/// - [gridTile] → square-ish tile with image on top, name/price/badges
///   stacked below.  Used in the POS item-picker grid.
/// - [listTile] → compact horizontal row: image on the left, meta on
///   the right.  Used in Inventory list view.
enum ProductCardVariant {
  gridTile,
  listTile,
}

/// Reusable card that represents a single inventory item / sellable
/// product across both POS and Inventory screens.
///
/// A **single widget with a [variant] enum** was chosen over two widget
/// classes because the two layouts share ~85% of the data and rendering
/// logic (image fallback, price formatting, stock badge, category tag).
/// Keeping them in one class means the stock-status colour mapping,
/// price formatter, and semantics live in exactly one place.
///
/// Usage — POS grid:
/// ```dart
/// ProductCard(
///   variant: ProductCardVariant.gridTile,
///   name: 'Ugali',
///   priceSenti: 200000,       // 2,000 TZS
///   stockStatus: ProductStockStatus.inStock,
///   category: 'Staples',
///   onTap: () => _addToSale(item),
/// )
/// ```
///
/// Usage — Inventory list:
/// ```dart
/// ProductCard(
///   variant: ProductCardVariant.listTile,
///   name: 'Beef Pilau',
///   priceSenti: 850000,       // 8,500 TZS
///   stockStatus: ProductStockStatus.lowStock,
///   stockLevel: 4,
///   category: 'Rice Dishes',
///   onTap: () => _openItemEditor(item),
/// )
/// ```
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.name,
    required this.priceSenti,
    required this.stockStatus,
    this.variant = ProductCardVariant.gridTile,
    this.imageUrl,
    this.iconFallback = Icons.restaurant_outlined,
    this.category,
    this.stockLevel,
    this.onTap,
    this.onLongPress,
  });

  final String name;

  /// Price in **senti** (hundredths of a TZS).  1 TZS = 100 senti.
  /// Display formatting happens inside this widget so callers never
  /// accidentally convert via floats.
  final int priceSenti;

  final ProductStockStatus stockStatus;
  final ProductCardVariant variant;

  /// Optional product image URL.  When missing, a solid-colour tile
  /// with [iconFallback] is rendered instead.
  final String? imageUrl;

  final IconData iconFallback;
  final String? category;

  /// Numeric stock level — when present, it's shown next to the status
  /// badge; [stockStatus] still drives the colour.
  final int? stockLevel;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      ProductCardVariant.gridTile => _buildGridTile(context),
      ProductCardVariant.listTile => _buildListTile(context),
    };
  }

  // ── Grid tile variant (POS) ──────────────────────────────────────

  Widget _buildGridTile(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard.elevated(
      onTap: onTap,
      onLongPress: onLongPress,
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _imageTile(cs)),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceSM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimensions.spaceXXS),
                if (category != null)
                  Text(
                    category!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: AppDimensions.spaceSM),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatPrice(priceSenti),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _stockBadge(
                      size: StatusBadgeSize.compact,
                      showNumericLevel: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── List tile variant (Inventory) ────────────────────────────────

  Widget _buildListTile(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard.elevated(
      onTap: onTap,
      onLongPress: onLongPress,
      padding: const EdgeInsets.all(AppDimensions.spaceSM),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: _imageTile(cs, radius: AppDimensions.radiusSM),
          ),
          const SizedBox(width: AppDimensions.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimensions.spaceXXS),
                if (category != null)
                  Text(
                    category!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                const SizedBox(height: AppDimensions.spaceSM),
                Row(
                  children: [
                    Flexible(
                      child: _stockBadge(
                        size: StatusBadgeSize.compact,
                        showNumericLevel: true,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceSM),
                    Expanded(
                      child: Text(
                        _formatPrice(priceSenti),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared internals ─────────────────────────────────────────────

  Widget _imageTile(ColorScheme cs, {double? radius}) {
    final bg = cs.primaryContainer.withValues(alpha: 0.35);
    final fg = cs.onPrimaryContainer.withValues(alpha: 0.75);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius ?? 0),
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(radius ?? 0),
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(iconFallback, size: 36, color: fg),
              ),
            )
          : Icon(iconFallback, size: 40, color: fg),
    );
  }

  Widget _stockBadge({
    required StatusBadgeSize size,
    bool showNumericLevel = false,
  }) {
    final (variant, label) = switch (stockStatus) {
      ProductStockStatus.inStock => (
          StatusBadgeVariant.success,
          showNumericLevel && stockLevel != null
              ? '$stockLevel in stock'
              : 'In stock',
        ),
      ProductStockStatus.lowStock => (
          StatusBadgeVariant.warning,
          showNumericLevel && stockLevel != null
              ? 'Low · $stockLevel'
              : 'Low stock',
        ),
      ProductStockStatus.outOfStock => (
          StatusBadgeVariant.danger,
          'Out of stock',
        ),
    };
    return StatusBadge(
      label: label,
      variant: variant,
      size: size,
    );
  }

  static String _formatPrice(int senti) {
    final whole = senti ~/ 100;
    final groups = <String>[];
    var remaining = whole.abs();
    if (remaining == 0) {
      groups.add('0');
    } else {
      while (remaining > 0) {
        groups.insert(0, (remaining % 1000).toString().padLeft(3, '0'));
        remaining ~/= 1000;
      }
      if (groups.isNotEmpty) {
        groups[0] = groups[0].replaceFirst(RegExp(r'^0+'), '');
        if (groups[0].isEmpty) groups[0] = '0';
      }
    }
    final sign = senti < 0 ? '-' : '';
    return '$sign TZS ${groups.join(',')}';
  }
}
