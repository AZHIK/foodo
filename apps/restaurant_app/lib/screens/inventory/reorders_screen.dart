import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/permission.dart';
import '../../constants/app_strings.dart';
import '../../models/reorder.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/permissions_provider.dart';
import '../../providers/reorder_provider.dart';
import '../../providers/suppliers_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../../widgets/data_page/status_badge.dart';
import '../../widgets/data_page/summary_metric_card.dart';

/// Reorder tracking and management screen.
class ReordersScreen extends ConsumerWidget {
  const ReordersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reorders = ref.watch(reordersListProvider);
    final pending = reorders.where((r) => r.status == ReorderStatus.pending).toList();
    final received = reorders.where((r) => r.status == ReorderStatus.received).toList();
    final cancelled = reorders.where((r) => r.status == ReorderStatus.cancelled).toList();

    double totalOnOrder = 0;
    for (final r in pending) {
      totalOnOrder += r.total;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.reordersTitle),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(reordersProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(Insets.lg),
        children: [
          Row(
            children: [
              Expanded(
                child: SummaryMetricCard(
                  label: AppStrings.pendingMetric,
                  value: '${pending.length}',
                  trend: AppStrings.awaitingDelivery,
                  icon: Icons.shopping_cart_outlined,
                  accent: context.semantic.warning,
                ),
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: SummaryMetricCard(
                  label: AppStrings.receivedMetric,
                  value: '${received.length}',
                  trend: AppStrings.stockAdded,
                  icon: Icons.check_circle_rounded,
                  accent: context.semantic.success,
                ),
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: SummaryMetricCard(
                  label: AppStrings.onOrderMetric,
                  value: Fmt.moneyCompact(totalOnOrder),
                  trend: AppStrings.totalValueMetric,
                  icon: Icons.attach_money_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.xl),
          if (pending.isNotEmpty) ...[
            Text(
              AppStrings.pendingCount(pending.length),
              style: context.text.titleMedium,
            ),
            const SizedBox(height: Insets.md),
            ...pending.map((r) => _ReorderTile(reorder: r)),
            const SizedBox(height: Insets.xl),
          ],
          if (received.isNotEmpty) ...[
            Text(
              AppStrings.receivedCount(received.length),
              style: context.text.titleMedium,
            ),
            const SizedBox(height: Insets.md),
            ...received.map((r) => _ReorderTile(reorder: r)),
            const SizedBox(height: Insets.xl),
          ],
          if (cancelled.isNotEmpty) ...[
            Text(
              AppStrings.cancelledCount(cancelled.length),
              style: context.text.titleMedium,
            ),
            const SizedBox(height: Insets.md),
            ...cancelled.map((r) => _ReorderTile(reorder: r)),
          ],
          if (reorders.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Insets.xl),
                child: Column(
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 48, color: context.colors.onSurfaceVariant),
                    const SizedBox(height: Insets.md),
                    Text(AppStrings.noReordersYet, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }
}

class _ReorderTile extends ConsumerWidget {
  const _ReorderTile({required this.reorder});
  final Reorder reorder;

  Future<void> _receive(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.receiveReorderTitle),
        content: Text(
          AppStrings.receiveReorderAdds(
            Fmt.quantity(reorder.quantity),
            reorder.unit,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(AppStrings.receiveAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(reordersProvider.notifier).receive(reorder);
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.reorderReceivedMessage)),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.receiveFailed(e))),
      );
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.cancelReorderTitle),
        content: Text(AppStrings.cannotBeUndone),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppStrings.keepIt),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(AppStrings.cancelReorderAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(reordersProvider.notifier).cancel(reorder);
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.reorderCancelledMessage)),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.cancelFailed(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(inventoryItemsListProvider);
    final item = items.where((i) => i.id == reorder.inventoryItemId).firstOrNull;
    final supplier = ref.watch(supplierByIdProvider(reorder.supplierId));
    final canReceive = ref.watch(hasPermissionProvider(AppPermissions.reordersReceive));
    final canCancel = ref.watch(hasPermissionProvider(AppPermissions.reordersCancel));
    final tone = switch (reorder.status) {
      ReorderStatus.pending => StatusTone.warning,
      ReorderStatus.received => StatusTone.positive,
      ReorderStatus.cancelled => StatusTone.neutral,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: Insets.md),
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(border: Border.all(color: context.semantic.hairline), borderRadius: BorderRadius.circular(Insets.md)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item?.name ?? AppStrings.unknown, style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: Insets.xs),
                    Text(
                      AppStrings.reorderTileSubtitle(
                        Fmt.quantity(reorder.quantity),
                        reorder.unit,
                        supplier?.name,
                      ),
                      style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              StatusBadge(label: reorder.status.label, tone: tone, dense: true),
            ],
          ),
          const SizedBox(height: Insets.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(AppStrings.unitCostColumn, style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant)),
                Text(Fmt.money(reorder.unitCost), style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(AppStrings.totalColumn, style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant)),
                Text(Fmt.money(reorder.total), style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: context.colors.primary)),
              ]),
              if (reorder.status == ReorderStatus.pending && reorder.expectedAt != null)
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(AppStrings.expectedLabel, style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant)),
                  Text(Fmt.relativeDateTime(reorder.expectedAt!), style: context.text.bodySmall),
                ]),
              if (reorder.status == ReorderStatus.received && reorder.receivedAt != null)
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(AppStrings.receivedLabel, style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant)),
                  Text(Fmt.relativeDateTime(reorder.receivedAt!), style: context.text.bodySmall),
                ]),
              if (reorder.status == ReorderStatus.cancelled && reorder.cancelledAt != null)
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(AppStrings.cancelledLabel, style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant)),
                  Text(Fmt.relativeDateTime(reorder.cancelledAt!), style: context.text.bodySmall),
                ]),
            ],
          ),
          if (reorder.notes != null) ...[
            const SizedBox(height: Insets.md),
            Text(AppStrings.notesLine(reorder.notes!), style: context.text.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: context.colors.onSurfaceVariant)),
          ],
          if (reorder.status == ReorderStatus.pending && (canReceive || canCancel)) ...[
            const SizedBox(height: Insets.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canCancel)
                  TextButton(
                    onPressed: () => _cancel(context, ref),
                    child: Text(AppStrings.cancel),
                  ),
                if (canReceive) ...[
                  const SizedBox(width: Insets.sm),
                  FilledButton.icon(
                    onPressed: () => _receive(context, ref),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: Text(AppStrings.receiveAction),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
