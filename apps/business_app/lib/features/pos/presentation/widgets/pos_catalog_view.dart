import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/fakes/fake_data_service.dart';
import '../../../../shared/widgets/widgets.dart';
import 'pos_layout_model.dart';

/// Search field + category pill row, shared by all three POS layouts.
///
/// Every form factor filters the catalog the same way — only the surrounding
/// panel chrome differs — so the filter row itself is written once here
/// rather than three times.
class PosCatalogFilters extends StatelessWidget {
  const PosCatalogFilters({
    super.key,
    required this.model,
    this.searchHint = 'Search in products',
  });

  final PosLayoutModel model;
  final String searchHint;

  /// Sentinel category meaning "no category filter". Kept here so both the
  /// screen (which builds the list) and the pill bar (which relabels it)
  /// agree on one value.
  static const String allCategories = 'All';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSearchField(
          controller: model.searchController,
          hintText: searchHint,
          onChanged: model.onSearchChanged,
        ),
        const SizedBox(height: AppDimensions.spaceSM),
        FilterPillBar(
          labels: model.categories,
          selectedLabel: model.selectedCategory,
          onSelected: model.onCategoryChanged,
          displayLabel: (label) =>
              label == allCategories ? 'Show All' : label,
        ),
      ],
    );
  }
}

/// Tappable product grid.
///
/// Responsive in both axes:
/// - Column count comes from the *actual* available width against
///   [minTileWidth] rather than from breakpoint pixel values, so each layout
///   only says how big it wants a tile to be and the grid then reflows
///   correctly at every width inside that tier (and mid-resize), instead of
///   being tuned for one width and breaking at others.
/// - Tile height starts from [childAspectRatio] but is capped at the
///   viewport height, so a short window (a laptop at 1280x720, a split-screen
///   tablet) can never produce a tile taller than the area it scrolls in —
///   which would leave every card's name and price clipped below the fold
///   and untappable.
class PosProductGrid extends StatelessWidget {
  const PosProductGrid({
    super.key,
    required this.items,
    required this.onItemSelected,
    required this.minTileWidth,
    required this.childAspectRatio,
    this.maxColumns = 4,
    this.spacing = AppDimensions.spaceSM,
  });

  /// Floor for a tile's height: below this the card's text block
  /// (name, category, price, stock badge) starts to clip.
  static const double _minTileHeight = 170;

  final List<FakeInventoryItem> items;
  final ValueChanged<FakeInventoryItem> onItemSelected;

  /// Target minimum width per tile; drives the column count.
  final double minTileWidth;

  /// Preferred width:height ratio, applied unless the viewport is too short
  /// to fit a tile of that height.
  final double childAspectRatio;
  final int maxColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const AppEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No Items Found',
        subtitle: 'Try another search or category.',
        compact: true,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / minTileWidth)
            .floor()
            .clamp(2, maxColumns);
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final maxTileHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight.clamp(_minTileHeight, double.infinity)
            : double.infinity;
        final tileHeight = (tileWidth / childAspectRatio).clamp(
          _minTileHeight,
          maxTileHeight,
        );
        return GridView.builder(
          padding: EdgeInsets.zero,
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: tileWidth / tileHeight,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return ProductCard(
              name: item.name,
              priceSenti: item.priceSenti,
              stockStatus: posStockStatusFor(item),
              stockLevel: item.stockLevel,
              category: item.category,
              variant: ProductCardVariant.gridTile,
              onTap: item.isOutOfStock ? null : () => onItemSelected(item),
            );
          },
        );
      },
    );
  }
}

ProductStockStatus posStockStatusFor(FakeInventoryItem item) {
  if (item.isOutOfStock) return ProductStockStatus.outOfStock;
  if (item.isLowStock) return ProductStockStatus.lowStock;
  return ProductStockStatus.inStock;
}
