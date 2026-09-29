/// Requisition cart dialog — ONE unified order across multiple suppliers.
///
/// DIALOG, never a route: overlays the current screen from a persistent cart
/// action. Responsive presentation, same component and logic throughout:
///
/// * mobile (< 600): full-height bottom sheet, swipe-down dismisses.
/// * tablet/desktop (≥ 600): centered modal with fixed max-width.
///
/// The item list scrolls independently; the header (title + bulk-assign
/// action bar) and the submit CTA footer stay pinned — the dialog has a
/// constrained viewport height, especially on mobile.
///
/// Dismissing (swipe / outside / close / Esc) preserves cart state: the cart
/// is session-only state in [requisitionCartProvider] (confirmed decision —
/// no server draft), so it survives the dialog closing.
///
/// Accessibility: both presentation primitives ([showModalBottomSheet] and
/// [showDialog]) provide focus trap, Esc/back to close, and focus return to
/// the trigger element. Touch targets are ≥44px on mobile/tablet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/requisition.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/requisition_cart_provider.dart';
import '../../providers/suppliers_provider.dart';
import '../../constants/app_strings.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/dialogs/supplier_picker_dialog.dart';

/// Opens the cart. Returns the submitted requisition id, or null when the
/// dialog was dismissed / the cart is still being built.
Future<String?> showRequisitionCart(BuildContext context) {
  final form = context.formFactor;
  if (form.isMobile) {
    return showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
      ),
      builder: (_) => const _CartSheet(),
    );
  }
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (_) => Dialog(
      insetPadding:
          EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(Radii.lg)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: _CartDialogBody(),
      ),
    ),
  );
}

/// Persistent cart entry point: badge with the unassigned count. Place next
/// to the existing "New purchase order" action — never a page navigation.
class RequisitionCartButton extends ConsumerWidget {
  const RequisitionCartButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(requisitionCartProvider);
    final count = cart.lines.length;
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      child: FilledButton.tonalIcon(
        onPressed: () async {
          final requisitionId = await showRequisitionCart(context);
          if (requisitionId != null && context.mounted) {
            context.push(AppRoute.requisitionDetail(requisitionId));
          }
        },
        icon: const Icon(Icons.shopping_cart_outlined, size: 18),
        label: Text(AppStrings.reqCartTitle),
      ),
    );
  }
}

class _CartSheet extends StatelessWidget {
  const _CartSheet();

  @override
  Widget build(BuildContext context) {
    // Full-height sheet: respects the keyboard (viewInsets) and the notch.
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (_, controller) => Column(
            children: [
              const SizedBox(height: Insets.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
              ),
              const Expanded(child: _CartDialogBody(scrollController: null)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartDialogBody extends ConsumerWidget {
  const _CartDialogBody({this.scrollController});

  /// Scroll controller for the sheet variant; null uses an internal one.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(requisitionCartProvider);
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CartHeader(onClose: () => Navigator.of(context).pop()),
        // Sticky bulk-assign action bar, pinned near the top.
        _BulkAssignBar(),
        const Divider(height: 1),
        Flexible(
          child: !online
              ? _offlineNotice(context)
              : cart.lines.isEmpty
                  ? _emptyCart(context, ref)
                  : _CartList(scrollController: scrollController),
        ),
        const Divider(height: 1),
        _CartFooter(),
      ],
    );
  }

  Widget _offlineNotice(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Insets.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined,
              size: 40, color: context.colors.onSurfaceVariant),
          const SizedBox(height: Insets.sm),
          Text(AppStrings.reqNeedsInternet,
              style: context.text.titleSmall, textAlign: TextAlign.center),
          const SizedBox(height: Insets.xs),
          Text(
            AppStrings.reqNeedsInternetBody,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _emptyCart(BuildContext context, WidgetRef ref) {
    final items = ref
        .watch(inventoryItemsListProvider)
        .where((i) => i.itemType != 'sellable' && !i.isArchived)
        .take(6)
        .toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Insets.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 40, color: context.colors.onSurfaceVariant),
          const SizedBox(height: Insets.sm),
          Text(AppStrings.reqCartEmpty,
              style: context.text.titleSmall, textAlign: TextAlign.center),
          const SizedBox(height: Insets.xs),
          Text(
            AppStrings.reqCartEmptyHint,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: Insets.lg),
            Wrap(
              spacing: Insets.sm,
              runSpacing: Insets.sm,
              alignment: WrapAlignment.center,
              children: [
                for (final item in items)
                  ActionChip(
                    label: Text('+ ${item.name}'),
                    onPressed: () {
                      final preferred = findPreferredSupplier(
                          ref.read(suppliersListProvider),
                          item.preferredSupplierId);
                      ref.read(requisitionCartProvider.notifier).addItem(
                            itemId: item.id,
                            itemName: item.name,
                            unit: item.unit,
                            qty: 1,
                            supplierId: preferred?.id,
                            supplierName: preferred?.name,
                            assignmentSource:
                                preferred == null ? null : 'preferred',
                          );
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CartHeader extends ConsumerWidget {
  const _CartHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(requisitionCartProvider).lines.length;
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(Insets.lg, Insets.md, Insets.sm, Insets.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.reqCartTitle, style: context.text.titleMedium),
                Text(
                  count == 0
                      ? AppStrings.reqCartSubtitle
                      : AppStrings.reqCartCount(count),
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: AppStrings.reqCloseCart,
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            constraints:
                const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ],
      ),
    );
  }
}

/// Sticky bulk-assign action bar with the explicit override toggle.
///
/// Rule (confirmed): bulk defaults to unassigned-only. The switch turns on
/// "override all", which replaces existing per-item choices.
class _BulkAssignBar extends ConsumerStatefulWidget {
  @override
  ConsumerState<_BulkAssignBar> createState() => _BulkAssignBarState();
}

class _BulkAssignBarState extends ConsumerState<_BulkAssignBar> {
  bool _overrideAll = false;

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(requisitionCartProvider);
    if (cart.lines.isEmpty) return const SizedBox.shrink();
    final unassigned = cart.unassignedCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Insets.lg, Insets.xs, Insets.lg, Insets.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.tonalIcon(
            onPressed: () => _pickBulkSupplier(context),
            icon: const Icon(Icons.store_rounded, size: 18),
            label: Text(
              unassigned == 0
                  ? AppStrings.reqReassignAll
                  : AppStrings.reqAssignAllCount(unassigned),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              alignment: Alignment.centerLeft,
            ),
          ),
          Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: Checkbox(
                  value: _overrideAll,
                  onChanged: (v) =>
                      setState(() => _overrideAll = v ?? false),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _overrideAll = !_overrideAll),
                  child: Text(
                    AppStrings.reqOverrideAll,
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickBulkSupplier(BuildContext context) async {
    final picked = await showSupplierPicker(
      context: context,
      scope: SupplierPickScope.bulk,
    );
    if (picked == null || !context.mounted) return;
    ref.read(requisitionCartProvider.notifier).bulkAssign(
          supplierId: picked.id,
          supplierName: picked.name,
          scope: _overrideAll ? BulkScope.all : BulkScope.unassignedOnly,
          overwriteAll: _overrideAll,
        );
  }
}

class _CartList extends ConsumerWidget {
  const _CartList({this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(requisitionCartProvider).lines;
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: Insets.sm),
      itemCount: lines.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: Insets.lg),
      itemBuilder: (context, i) => _CartLineRow(line: lines[i]),
    );
  }
}

class _CartLineRow extends ConsumerWidget {
  const _CartLineRow({required this.line});

  final RequisitionCartLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(requisitionCartProvider.notifier);
    final hasSupplier = line.supplierId != null;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Insets.lg, vertical: Insets.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(line.itemName,
                        style: context.text.titleSmall,
                        overflow: TextOverflow.ellipsis),
                    Text('${line.qty} ${line.unit}',
                        style: context.text.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
              _QtyStepper(
                qty: line.qty,
                onChanged: (q) => notifier.setQty(line.itemId, q),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          Row(
            children: [
              Expanded(child: _SupplierBadge(line: line)),
              if (line.priceUnconfirmed)
                Container(
                  margin: const EdgeInsets.only(left: Insets.sm),
                  padding: const EdgeInsets.symmetric(
                      horizontal: Insets.sm, vertical: Insets.xs),
                  decoration: BoxDecoration(
                    color: context.semantic.warningContainer,
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                  child: Text(
                    AppStrings.reqPriceTbc,
                    style: context.text.labelSmall?.copyWith(
                      color: context.semantic.onWarning,
                    ),
                  ),
                ),
              IconButton(
                tooltip: AppStrings.reqRemoveItem(line.itemName),
                onPressed: () => notifier.removeLine(line.itemId),
                icon: const Icon(Icons.delete_outline_rounded),
                constraints:
                    const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ],
          ),
          if (!hasSupplier)
            Padding(
              padding: const EdgeInsets.only(top: Insets.xs),
              child: Text(
                AppStrings.reqLineNeedsSupplier,
                style: context.text.bodySmall?.copyWith(
                  color: context.semantic.warning,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Assigned-supplier badge — or the red/amber "No supplier" state. Tapping
/// opens the same picker scoped to just this item.
class _SupplierBadge extends ConsumerWidget {
  const _SupplierBadge({required this.line});

  final RequisitionCartLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSupplier = line.supplierId != null;
    return ActionChip(
      avatar: Icon(
        hasSupplier ? Icons.store_rounded : Icons.warning_amber_rounded,
        size: 18,
        color: hasSupplier
            ? context.colors.primary
            : context.semantic.warning,
      ),
      label: Text(
        hasSupplier ? line.supplierName ?? 'Supplier' : AppStrings.reqNoSupplier,
        overflow: TextOverflow.ellipsis,
      ),
      side: hasSupplier
          ? null
          : BorderSide(color: context.semantic.warning),
      onPressed: () async {
        final picked = await showSupplierPicker(
          context: context,
          scope: SupplierPickScope.perItem,
          itemName: line.itemName,
          currentSupplierId: line.supplierId,
        );
        if (picked == null || !context.mounted) return;
        ref.read(requisitionCartProvider.notifier).assignSupplierToLine(
              itemId: line.itemId,
              supplierId: picked.id,
              supplierName: picked.name,
            );
      },
    );
  }
}

/// Qty stepper with ≥44px touch targets on mobile/tablet.
class _QtyStepper extends StatelessWidget {
  const _QtyStepper({required this.qty, required this.onChanged});

  final double qty;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: IconButton(
            tooltip: AppStrings.reqQtyDown,
            onPressed: () => onChanged(qty - 1),
            icon: const Icon(Icons.remove_rounded),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 40),
          child: Text(
            qty % 1 == 0 ? qty.toInt().toString() : qty.toString(),
            style: context.text.titleSmall,
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          width: 44,
          height: 44,
          child: IconButton(
            tooltip: AppStrings.reqQtyUp,
            onPressed: () => onChanged(qty + 1),
            icon: const Icon(Icons.add_rounded),
          ),
        ),
      ],
    );
  }
}

/// Pinned footer: inline blocker explanation + delivery date + submit CTA.
class _CartFooter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(requisitionCartProvider);
    final notifier = ref.read(requisitionCartProvider.notifier);
    final blocker = cart.submitBlocker;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            Insets.lg, Insets.sm, Insets.lg, Insets.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate:
                      DateTime.now().add(const Duration(days: 90)),
                  initialDate: cart.expectedAt ??
                      DateTime.now().add(const Duration(days: 2)),
                );
                if (picked != null) notifier.setExpectedAt(picked);
              },
              borderRadius: BorderRadius.circular(Radii.sm),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: Insets.sm),
                child: Row(
                  children: [
                    Icon(Icons.local_shipping_outlined,
                        size: 18,
                        color: context.colors.onSurfaceVariant),
                    const SizedBox(width: Insets.sm),
                    Expanded(
                      child: Text(
                        cart.expectedAt == null
                            ? AppStrings.reqDeliveryOptional
                            : AppStrings.reqDeliverySet('${cart.expectedAt!.day}/${cart.expectedAt!.month}/${cart.expectedAt!.year}'),
                        style: context.text.bodyMedium,
                      ),
                    ),
                    if (cart.expectedAt != null)
                      IconButton(
                        tooltip: AppStrings.reqClearDelivery,
                        constraints: const BoxConstraints(
                            minWidth: 44, minHeight: 44),
                        onPressed: () => notifier.setExpectedAt(null),
                        icon: const Icon(Icons.clear_rounded, size: 18),
                      ),
                  ],
                ),
              ),
            ),
            if (blocker != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Insets.sm),
                child: Text(
                  blocker,
                  style: context.text.bodySmall?.copyWith(
                    color: context.semantic.warning,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (cart.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Insets.sm),
                child: Text(
                  cart.error!,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            FilledButton(
              onPressed: cart.submitting
                  ? null
                  : () async {
                      if (blocker != null) {
                        // Tapping the disabled CTA explains why inline —
                        // the blocker text above is the explanation.
                        return;
                      }
                      try {
                        final submitted = await notifier.submit();
                        if (context.mounted) {
                          Navigator.of(context).pop(submitted.id);
                        }
                      } catch (_) {
                        // Error text already set on state; stays visible.
                      }
                    },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                // Visually disabled until every line has a supplier.
                disabledBackgroundColor:
                    context.colors.surfaceContainerHighest,
              ),
              child: cart.submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(blocker == null
                      ? AppStrings.reqSendOrder
                      : AppStrings.reqSendBlocked(blocker)),
            ),
          ],
        ),
      ),
    );
  }
}
