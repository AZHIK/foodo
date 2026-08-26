import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/menu_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/menu_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/pos/cart_bottom_sheet.dart';
import '../../widgets/pos/category_pill.dart';
import '../../widgets/pos/menu_item_card.dart';
import '../../widgets/pos/order_summary_panel.dart';
import '../../widgets/pos/pos_top_bar.dart';

/// The order terminal.
///
/// One layout, three arrangements: on desktop and tablet the ticket is a
/// persistent panel beside the grid; on mobile it collapses to a floating
/// cart icon button that opens the same ticket as a sheet.
class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // The order panel and the sticky cart bar must stay reachable when the
      // on-screen keyboard opens over the search field.
      resizeToAvoidBottomInset: true,
      body: Builder(
        builder: (context) {
          // Which arrangement to use is a property of the window, not of this
          // box. Measuring locally would let the navigation rail's own width
          // demote a 1024px desktop into the tablet layout. The grid still
          // sizes its columns from the box it actually gets, below.
          final form = context.formFactor;

          final menuSide = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PosTopBar(form: form),
              _CategoryStrip(form: form),
              Expanded(child: _MenuGrid(form: form)),
            ],
          );

          if (!form.hasSidePanel) {
            return Stack(
              children: [
                SafeArea(
                  bottom: false,
                  child: menuSide,
                ),
                Positioned(
                  bottom: Insets.lg,
                  right: Insets.lg,
                  child: const _CartFloatingButton(),
                ),
              ],
            );
          }

          return SafeArea(
            right: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: menuSide),
                OrderSummaryPanel(width: Layout.orderPanel(form)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryStrip extends ConsumerWidget {
  const _CategoryStrip({required this.form});

  final FormFactor form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(menuCategoriesProvider);
    final counts = ref.watch(categoryCountsProvider);
    final selected = ref.watch(selectedCategoryProvider);

    return SizedBox(
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

class _MenuGrid extends ConsumerWidget {
  const _MenuGrid({required this.form});

  final FormFactor form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(filteredMenuItemsProvider);

    if (items.isEmpty) return const _NoResults();

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
          padding: EdgeInsets.fromLTRB(pad, Insets.xs, pad, Insets.sm),
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

class _CartFloatingButton extends ConsumerWidget {
  const _CartFloatingButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartItemCountProvider);
    final colors = context.colors;

    return FloatingActionButton(
      mini: true,
      elevation: 2,
      backgroundColor: colors.surfaceContainerLowest,
      onPressed: () => CartBottomSheet.show(context),
      child: Badge.count(
        count: count,
        isLabelVisible: count > 0,
        child: Icon(
          Icons.shopping_bag_outlined,
          size: 22,
          color: colors.onSurface,
        ),
      ),
    );
  }
}

class _NoResults extends ConsumerWidget {
  const _NoResults();

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
              query.isEmpty ? 'Nothing on the menu here' : 'No matches',
              style: context.text.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Insets.xs),
            Text(
              query.isEmpty
                  ? 'This category has no items yet.'
                  : 'Nothing matches “$query” in this category.',
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
                label: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
