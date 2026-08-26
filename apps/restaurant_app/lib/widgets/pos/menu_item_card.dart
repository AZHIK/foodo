import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/menu_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/menu_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../dialogs/menu_item_form_dialog.dart';

/// A tappable menu tile in the POS grid.
///
/// Watches only its own line via [cartQuantityProvider], so adding one item
/// rebuilds one card rather than the whole grid.
class MenuItemCard extends ConsumerWidget {
  const MenuItemCard({super.key, required this.item});

  final MenuItem item;

  /// Artwork is this much wider than it is tall.
  static const double _artworkAspect = 1.5;

  /// The name/price block below the artwork. Fixed so the grid can hand each
  /// tile an exact height and no card can overflow its cell.
  static const double _captionHeight = 72;

  /// Height a card needs at [cardWidth]. Used to compute the grid's
  /// `mainAxisExtent` instead of guessing a `childAspectRatio`.
  static double heightFor(double cardWidth) =>
      cardWidth / _artworkAspect + _captionHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final quantity = ref.watch(cartQuantityProvider(item.id));
    final inCart = quantity > 0;
    final available = item.isAvailable;

    return _Pressable(
      enabled: available,
      onLongPress: () => _showContextMenu(context, ref),
      child: Material(
        color: colors.surfaceContainerLowest,
        clipBehavior: Clip.antiAlias,
        elevation: inCart ? 0.5 : 0,
        shadowColor: inCart ? colors.primary : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.card,
          side: BorderSide(
            color: inCart ? colors.primary : context.semantic.hairline,
            width: inCart ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: available
              ? () => ref.read(cartProvider.notifier).add(item)
              : null,
          child: Opacity(
            opacity: available ? 1 : 0.45,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Artwork(
                    item: item,
                    quantity: quantity,
                    available: available,
                  ),
                ),
                SizedBox(
                  height: _captionHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Insets.sm,
                      vertical: 6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        LayoutBuilder(
                          builder: (context, constraints) => Row(
                            children: [
                              // Price is the one thing a cashier scans for, so
                              // it gets the heaviest weight on the card.
                              Expanded(
                                child: Text(
                                  Fmt.money(item.price),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: colors.onSurface,
                                  ),
                                ),
                              ),
                              // Prep time yields to the price on a narrow
                              // card rather than pushing it into an ellipsis.
                              if (constraints.maxWidth >= 90) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '${item.prepMinutes}m',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, WidgetRef ref) {
    showMenu(
      context: context,
      position: RelativeRect.fill,
      items: [
        PopupMenuItem(
          child: const Text('Edit item'),
          onTap: () => showMenuItemFormDialog(context, existingItem: item),
        ),
        PopupMenuItem(
          child: const Text('Archive item'),
          onTap: () {
            ref.read(menuItemsProvider.notifier).upsert(
              item.copyWith(isArchived: true),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${item.name} archived')),
            );
          },
        ),
      ],
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({
    required this.item,
    required this.quantity,
    required this.available,
  });

  final MenuItem item;
  final int quantity;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Emoji stands in for photography; scaling it off the box keeps the
        // tile looking deliberate at every column count.
        final glyph = (constraints.maxHeight * 0.48).clamp(20.0, 44.0);

        return Container(
          color: colors.surfaceContainerHigh,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Text(item.emoji, style: TextStyle(fontSize: glyph)),
              ),
              if (item.isPopular && available)
                Positioned(
                  top: Insets.xs,
                  left: Insets.xs,
                  child: Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: context.semantic.warning,
                  ),
                ),
              if (!available)
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.semantic.dangerContainer,
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Insets.sm,
                        vertical: Insets.xs,
                      ),
                      child: Text(
                        "86'd",
                        style: TextStyle(
                          color: context.semantic.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              if (quantity > 0)
                Positioned(
                  top: Insets.sm,
                  right: Insets.sm,
                  child: _QuantityBadge(quantity: quantity),
                ),
              if (item.linkedInventoryItemId != null)
                Positioned(
                  bottom: Insets.xs,
                  left: Insets.xs,
                  child: Icon(
                    Icons.link_rounded,
                    size: 14,
                    color: colors.primary,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _QuantityBadge extends StatelessWidget {
  const _QuantityBadge({required this.quantity});

  final int quantity;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Keyed on the value so each change replays the pop — cheap confirmation
    // that a tap landed without waiting to read the panel.
    return TweenAnimationBuilder<double>(
      key: ValueKey(quantity),
      tween: Tween(begin: 0.7, end: 1),
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        alignment: Alignment.center,
        child: Text(
          '$quantity',
          style: TextStyle(
            color: colors.onPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

/// Tap-scale micro-interaction. Local animation state only — nothing here
/// belongs in Riverpod.
class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.child,
    required this.enabled,
    this.onLongPress,
  });

  final Widget child;
  final bool enabled;
  final VoidCallback? onLongPress;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: Listener(
        onPointerDown: (_) => _set(true),
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
