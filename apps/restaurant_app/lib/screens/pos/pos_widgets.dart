import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/menu_item.dart';
import '../../constants/app_strings.dart';
import '../../providers/menu_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/pos/category_pill.dart';
import '../../widgets/pos/menu_item_card.dart';

/// Pieces of the order terminal shared by the mobile and desktop views.
///
/// The views decide how the ticket beside the grid behaves — a bottom bar
/// and sheet on phones, a persistent panel on larger screens — but the menu
/// side (search bar, category strip, item grid, empty state) is one
/// definition used by both.
class PosWidgets {
  const PosWidgets._();
}

class PosCategoryStrip extends ConsumerWidget {
  const PosCategoryStrip({super.key, required this.form});

  final FormFactor form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(menuCategoriesProvider);
    final counts = ref.watch(categoryCountsProvider);
    final selected = ref.watch(selectedCategoryProvider);

    return SizedBox(
      // Taller strip where pointer precision is cheap, compact where thumbs
      // do the scrolling — 44px still clears the 44px touch target floor.
      height: form.isMobile ? 44 : 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: Insets.page(form)),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: Insets.xs),
        itemBuilder: (context, index) {
          final category = categories[index];
          return Center(
            child: CategoryPill(
              label: category.label,
              icon: category.icon,
              count: counts[category.id],
              selected: category.id == selected,
              onTap: () =>
                  ref.read(selectedCategoryProvider.notifier).state =
                      category.id,
            ),
          );
        },
      ),
    );
  }
}

class PosMenuGrid extends ConsumerWidget {
  const PosMenuGrid({super.key, required this.form, this.bottomPadding});

  final FormFactor form;

  /// Space below the last row. The mobile view raises it past the floating
  /// cart bar so the final row is tappable rather than covered.
  final double? bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(filteredMenuItemsProvider);

    if (items.isEmpty) return const PosNoResults();

    final pad = form.isMobile ? Insets.md : Insets.page(form);
    final spacing = form.isMobile ? 6.0 : Insets.md;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Column count comes from the width the grid actually got — after the
        // rail and the order panel have taken theirs — not from the window.
        final available = constraints.maxWidth - pad * 2;
        final columns = Layout.columnsFor(available, form);
        final cardWidth = (available - spacing * (columns - 1)) / columns;

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            pad,
            Insets.xs,
            pad,
            bottomPadding ?? Insets.sm,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            // An exact extent rather than an aspect ratio, so the caption
            // block can never be squeezed into an overflow.
            mainAxisExtent: MenuItemCard.heightFor(cardWidth),
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => MenuItemCard(item: items[index]),
        );
      },
    );
  }
}

class PosNoResults extends ConsumerWidget {
  const PosNoResults({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final query = ref.watch(searchQueryProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 36,
              color: colors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: Insets.md),
            Text(
              query.isEmpty ? AppStrings.noMenuHere : AppStrings.noMatches,
              style: context.text.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Insets.xs),
            Text(
              query.isEmpty
                  ? AppStrings.noItemsInCategory
                  : AppStrings.nothingMatches(query),
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (query.isNotEmpty) ...[
              const SizedBox(height: Insets.lg),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(searchQueryProvider.notifier).state = '';
                  ref.read(selectedCategoryProvider.notifier).state =
                      MenuCategory.all.id;
                },
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: const Text(AppStrings.clearFilters),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
