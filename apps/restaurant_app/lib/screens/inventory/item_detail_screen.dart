import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock_inventory.dart';
import '../../models/inventory_item.dart';
import '../../models/stock_movement.dart';
import '../../models/table_query.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/menu_providers.dart';
import '../../providers/stock_movement_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../../widgets/data_page/data_column_spec.dart';
import '../../widgets/data_page/reusable_data_table.dart';
import '../../widgets/data_page/status_badge.dart';
import '../../widgets/data_page/summary_metric_card.dart';
import '../../widgets/detail_page/detail_page_scaffold.dart';
import '../../widgets/dialogs/item_form_dialog.dart';
import '../../widgets/dialogs/reorder_dialog.dart';
import 'inventory_screen.dart' show StockStatusTone;
import 'stock_adjust_dialog.dart';
import 'stock_transfer_dialog.dart';
import 'waste_log_dialog.dart';

/// Read-only view of one stock line: what it is, what it is worth, and every
/// movement that got it to its current count.
///
/// Reached by tapping a row body in the Inventory table. The row's "Edit"
/// action still opens the form dialog directly — going through a screen to
/// reach a dialog would be a step backwards for the common case.
class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref
        .watch(inventoryItemsProvider)
        .where((i) => i.id == itemId)
        .firstOrNull;

    if (item == null) return _NotFound(itemId: itemId);

    final history = ref.watch(itemStockHistoryProvider(itemId));

    return DetailPageScaffold(
      // The ledger is the point of this screen, so it leads on mobile rather
      // than sitting under a block of reference fields.
      sideFirstOnMobile: false,
      header: _Header(item: item),
      sidePanel: [_AboutPanel(item: item)],
      children: [
        _KeyStats(item: item),
        _QuickActions(item: item),
        _StockHistoryPanel(item: item, history: history),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends ConsumerWidget {
  const _Header({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DetailPageHeader(
      title: item.name,
      subtitle: item.sku,
      onBack: () => context.canPop()
          ? context.pop()
          : context.goNamed(AppRoute.inventoryName),
      leading: _Thumbnail(item: item),
      badges: [
        StatusBadge(
          label: item.isArchived ? 'Archived' : 'Active',
          tone: item.isArchived ? StatusTone.neutral : StatusTone.positive,
          icon: item.isArchived
              ? Icons.archive_outlined
              : Icons.check_circle_rounded,
          dense: true,
        ),
        // Same badge treatment as the Inventory table's status column, so the
        // two screens agree on what "Low stock" looks like.
        StatusBadge(
          label: item.status.label,
          tone: item.status.tone,
          icon: item.status.badgeIcon,
          dense: true,
        ),
      ],
      actions: [
        OutlinedButton.icon(
          onPressed: () => showItemFormDialog(context, existingItem: item),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Edit'),
        ),
        _OverflowMenu(item: item),
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.item});

  final InventoryItem item;

  static const double _size = 48;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _size,
      width: _size,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: context.semantic.hairline),
      ),
      child: item.image != null
          ? Image.memory(
              item.image!.bytes,
              fit: BoxFit.cover,
              width: _size,
              height: _size,
            )
          : Text(item.emoji, style: const TextStyle(fontSize: 24)),
    );
  }
}

class _OverflowMenu extends ConsumerWidget {
  const _OverflowMenu({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'More actions',
      position: PopupMenuPosition.under,
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: (value) => switch (value) {
        'archive' => _toggleArchive(context, ref),
        'delete' => _confirmDelete(context, ref),
        _ => null,
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'archive',
          child: Row(
            children: [
              Icon(
                item.isArchived
                    ? Icons.unarchive_outlined
                    : Icons.archive_outlined,
                size: 17,
                color: context.colors.onSurfaceVariant,
              ),
              const SizedBox(width: Insets.md),
              Text(item.isArchived ? 'Restore item' : 'Archive item'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 17,
                color: context.semantic.danger,
              ),
              const SizedBox(width: Insets.md),
              Text(
                'Delete item',
                style: TextStyle(color: context.semantic.danger),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _toggleArchive(BuildContext context, WidgetRef ref) {
    final archived = !item.isArchived;
    ref
        .read(inventoryItemsProvider.notifier)
        .upsert(item.copyWith(isArchived: archived));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          archived ? '${item.name} archived' : '${item.name} restored',
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${item.name}?'),
        content: const Text(
          'The item, its stock count and its entire movement history will be '
          'removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    // Leave first: this screen is watching the item that is about to stop
    // existing, and popping afterwards would flash the not-found state.
    context.canPop() ? context.pop() : context.goNamed(AppRoute.inventoryName);

    ref.read(inventoryItemsProvider.notifier).delete(item.id);
    ref.read(stockMovementsProvider.notifier).clearForItem(item.id);

    messenger.showSnackBar(SnackBar(content: Text('${item.name} deleted')));
  }
}

// ---------------------------------------------------------------------------
// Key stats
// ---------------------------------------------------------------------------

class _KeyStats extends StatelessWidget {
  const _KeyStats({required this.item});

  final InventoryItem item;

  /// Four across needs this much room; below it the tiles pair up two-by-two
  /// rather than shrinking to an unreadable width.
  static const double _fourAcross = 860;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;

    final tiles = <Widget>[
      SummaryMetricCard(
        label: 'Current stock',
        value: '${item.stock}',
        trend: item.unit,
        icon: Icons.inventory_2_outlined,
        accent: item.status == StockStatus.inStock
            ? semantic.success
            : semantic.warning,
      ),
      SummaryMetricCard(
        label: 'Unit cost',
        value: Fmt.money(item.unitCost),
        trend: 'per ${item.unit}',
        icon: Icons.sell_outlined,
      ),
      SummaryMetricCard(
        label: 'Inventory value',
        value: Fmt.moneyCompact(item.totalValue),
        trend: 'At cost',
        icon: Icons.savings_outlined,
        accent: semantic.success,
      ),
      SummaryMetricCard(
        label: 'Low stock at',
        value: item.trackStock ? '${item.reorderLevel}' : '—',
        trend: item.trackStock ? 'Warn at or below' : 'Not tracked',
        icon: Icons.warning_amber_rounded,
        accent: semantic.warning,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = Insets.md;
        final columns = constraints.maxWidth >= _fourAcross ? 4 : 2;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Quick actions
// ---------------------------------------------------------------------------

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    // Nothing to adjust, waste or move on a line that is not counted.
    if (!item.trackStock) return const SizedBox.shrink();

    final buttons = <Widget>[
      FilledButton.icon(
        onPressed: () => showStockAdjustDialog(context, item),
        icon: const Icon(Icons.tune_rounded, size: 18),
        label: const Text('Adjust stock'),
      ),
      OutlinedButton.icon(
        onPressed: () => showReorderDialog(context, item),
        icon: const Icon(Icons.shopping_cart_outlined, size: 18),
        label: const Text('Create reorder'),
      ),
      OutlinedButton.icon(
        onPressed: item.stock == 0
            ? null
            : () => showWasteLogDialog(context, item),
        icon: const Icon(Icons.delete_sweep_outlined, size: 18),
        label: const Text('Log waste'),
        style: OutlinedButton.styleFrom(
          foregroundColor: item.stock == 0 ? null : context.semantic.warning,
        ),
      ),
      OutlinedButton.icon(
        onPressed: item.stock == 0
            ? null
            : () => showStockTransferDialog(context, item),
        icon: const Icon(Icons.swap_horiz_rounded, size: 18),
        label: const Text('Transfer stock'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Three buttons need roughly this much to sit on one line. Below it
        // they scroll sideways rather than wrapping into a tall stack that
        // pushes the history off a phone screen.
        if (constraints.maxWidth >= 520) {
          return Wrap(
            spacing: Insets.md,
            runSpacing: Insets.md,
            children: buttons,
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (var i = 0; i < buttons.length; i++) ...[
                if (i > 0) const SizedBox(width: Insets.md),
                buttons[i],
              ],
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Stock history
// ---------------------------------------------------------------------------

class _StockHistoryPanel extends StatefulWidget {
  const _StockHistoryPanel({required this.item, required this.history});

  final InventoryItem item;
  final List<StockMovement> history;

  @override
  State<_StockHistoryPanel> createState() => _StockHistoryPanelState();
}

class _StockHistoryPanelState extends State<_StockHistoryPanel> {
  /// The ledger is already newest-first and scoped to one item, so the table is
  /// handed a fixed query: no sort field, and a page size big enough that most
  /// items never paginate at all. Local state rather than a provider because
  /// which page of one item's history you are on is not app state.
  int _page = 0;

  static const _pageSize = 8;

  @override
  Widget build(BuildContext context) {
    final query = TableQuery(page: _page, pageSize: _pageSize);
    final slice = PageSlice.of(widget.history, query);

    return DetailPanel(
      title: 'Stock history',
      trailing: Text(
        '${widget.history.length} movements',
        style: context.text.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
      child: ReusableDataTable<StockMovement>(
        columns: _columns(widget.item),
        slice: slice,
        query: query,
        // Scoped to a single item and already in date order, so re-sorting it
        // would only ever make it harder to read.
        onSort: (_) {},
        onPageChanged: (page) => setState(() => _page = page),
        emptyState: const _NoHistory(),
      ),
    );
  }

  static List<DataColumnSpec<StockMovement>> _columns(InventoryItem item) => [
    DataColumnSpec(
      label: 'When',
      field: 'when',
      role: ColumnRole.primary,
      sortable: false,
      flex: 4,
      value: (m) => Fmt.relativeDateTime(m.at),
      cellBuilder: (context, m) => _WhenCell(movement: m),
    ),
    DataColumnSpec(
      label: 'Type',
      field: 'type',
      role: ColumnRole.status,
      sortable: false,
      width: 132,
      value: (m) => m.type.label,
      cellBuilder: (context, m) => StatusBadge(
        label: m.type.label,
        tone: m.type.tone,
        icon: m.type.icon,
        dense: true,
      ),
    ),
    DataColumnSpec(
      label: 'Change',
      field: 'delta',
      sortable: false,
      numeric: true,
      flex: 2,
      value: (m) => '${m.deltaLabel} ${item.unit}',
      cellBuilder: (context, m) => _DeltaCell(movement: m),
    ),
    DataColumnSpec(
      label: 'Balance',
      field: 'balance',
      sortable: false,
      numeric: true,
      flex: 2,
      minTableWidth: 560,
      value: (m) => '${m.balance} ${item.unit}',
    ),
    DataColumnSpec(
      label: 'By',
      field: 'actor',
      sortable: false,
      flex: 3,
      minTableWidth: 720,
      value: (m) => m.actor,
    ),
  ];
}

class _WhenCell extends StatelessWidget {
  const _WhenCell({required this.movement});

  final StockMovement movement;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          Fmt.relativeDateTime(movement.at),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (movement.note case final note?)
          Text(
            note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _DeltaCell extends StatelessWidget {
  const _DeltaCell({required this.movement});

  final StockMovement movement;

  @override
  Widget build(BuildContext context) {
    final up = movement.delta >= 0;

    return Text(
      movement.deltaLabel,
      maxLines: 1,
      textAlign: TextAlign.right,
      style: context.text.bodyMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: up ? context.semantic.success : context.semantic.danger,
      ),
    );
  }
}

class _NoHistory extends StatelessWidget {
  const _NoHistory();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.xl),
      child: Column(
        children: [
          Icon(
            Icons.history_rounded,
            size: 28,
            color: context.colors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: Insets.sm),
          Text(
            'No movements recorded yet',
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// About / basic info
// ---------------------------------------------------------------------------

class _AboutPanel extends ConsumerWidget {
  const _AboutPanel({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final hasDescription = item.description.trim().isNotEmpty;
    final linkedMenuItems = ref.watch(menuItemsByInventoryIdProvider(item.id));

    return DetailPanel(
      title: 'About this item',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hasDescription
                ? item.description
                : 'No description added yet. Use Edit to add one.',
            style: context.text.bodyMedium?.copyWith(
              color: hasDescription ? null : colors.onSurfaceVariant,
              fontStyle: hasDescription ? null : FontStyle.italic,
            ),
          ),
          const SizedBox(height: Insets.lg),
          const Divider(height: 1),
          const SizedBox(height: Insets.lg),
          // One column in the side panel, more when this folds into the main
          // column on a narrow window.
          LabeledValueGrid(
            maxColumns: 2,
            minColumnWidth: 220,
            children: [
              LabeledValue(
                label: 'Category',
                value: MockInventory.categoryLabel(item.categoryId),
                icon: MockInventory.categoryById(item.categoryId)?.icon ??
                    Icons.category_outlined,
              ),
              LabeledValue(
                label: 'SKU',
                value: item.sku,
                icon: Icons.qr_code_2_rounded,
              ),
              LabeledValue(
                label: 'Supplier',
                value: item.supplier,
                icon: Icons.local_shipping_outlined,
              ),
              LabeledValue(
                label: 'Counted in',
                value: item.unit,
                icon: Icons.straighten_rounded,
              ),
              LabeledValue(
                label: 'Stock tracking',
                value: item.trackStock ? 'On' : 'Off',
                icon: item.trackStock
                    ? Icons.toggle_on_outlined
                    : Icons.toggle_off_outlined,
              ),
              LabeledValue(
                label: 'Last counted',
                value: item.lastCountedAt == null
                    ? 'Never'
                    : Fmt.relativeDateTime(item.lastCountedAt!),
                icon: Icons.event_available_outlined,
              ),
              if (linkedMenuItems.isNotEmpty)
                LabeledValue(
                  label: 'Linked menu item',
                  value: linkedMenuItems.map((m) => m.name).join(', '),
                  icon: Icons.restaurant_menu_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Insets.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 36,
                  color: context.colors.onSurfaceVariant,
                ),
                const SizedBox(height: Insets.md),
                Text('Item $itemId not found', style: context.text.titleMedium),
                const SizedBox(height: Insets.lg),
                FilledButton.icon(
                  onPressed: () => context.goNamed(AppRoute.inventoryName),
                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                  label: const Text('Back to inventory'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
