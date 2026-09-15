import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_strings.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../../widgets/pos/cart_bottom_sheet.dart';
import '../../widgets/pos/pos_top_bar.dart';
import 'pos_widgets.dart';

/// The order terminal as a phone experience.
///
/// Same menu side as desktop, but the ticket collapses to a bottom cart bar:
/// a full-width thumb target showing the item count and running total that
/// opens the ticket as a sheet. The bar only appears once something is in
/// the order, so an empty cart never steals grid space.
class PosMobileScreen extends ConsumerWidget {
  const PosMobileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const form = FormFactor.mobile;
    final hasItems = ref.watch(cartItemCountProvider) > 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      // The sticky cart bar must stay reachable when the on-screen keyboard
      // opens over the search field.
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PosTopBar(form: form),
                const PosCategoryStrip(form: form),
                Expanded(
                  child: PosMenuGrid(
                    form: form,
                    // Clear of the floating cart bar when it is showing.
                    bottomPadding: hasItems ? 88 : Insets.sm,
                  ),
                ),
              ],
            ),
          ),
          if (hasItems)
            const Positioned(
              left: Insets.lg,
              right: Insets.lg,
              bottom: Insets.lg,
              child: _CartBar(),
            ),
        ],
      ),
    );
  }
}

/// The running order as a bottom bar: count on the left, total on the right,
/// one tap to the ticket sheet.
///
/// 56px tall and edge-to-edge within its margins — a thumb target, not the
/// 40px mini FAB it replaces, which asked a cashier mid-rush to hit a coin
/// in the corner of the screen.
class _CartBar extends ConsumerWidget {
  const _CartBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final count = ref.watch(cartItemCountProvider);
    final total = ref.watch(cartProvider.select((cart) => cart.totals.total));

    return Material(
      color: colors.primary,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      elevation: 4,
      child: InkWell(
        onTap: () => CartBottomSheet.show(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg,
            vertical: Insets.md,
          ),
          child: Row(
            children: [
              Badge.count(
                count: count,
                backgroundColor: colors.onPrimary,
                textColor: colors.primary,
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 22,
                  color: colors.onPrimary,
                ),
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Text(
                  AppStrings.cartItemCount(count),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleMedium?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                Fmt.money(total),
                maxLines: 1,
                style: context.text.titleMedium?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: Insets.xs),
              Icon(
                Icons.keyboard_arrow_up_rounded,
                color: colors.onPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
