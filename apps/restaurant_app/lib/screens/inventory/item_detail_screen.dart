import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/inventory_item.dart';
import '../../constants/app_limits.dart';
import '../../constants/app_strings.dart';
import '../../models/permission.dart';
import '../../models/stock_movement.dart';
import '../../models/table_query.dart';
import '../../providers/categories_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/permissions_provider.dart';
import '../../providers/production_provider.dart';
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
import '../../widgets/item_photo.dart';
import 'inventory_groceries_screen.dart' show StockStatusTone;
import 'recipe_form_dialog.dart';
import 'record_production_dialog.dart';
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
        .watch(inventoryItemsListProvider)
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
      onRefresh: () => ref.read(inventoryItemsProvider.notifier).refresh(),
      children: [
        _KeyStats(item: item),
        _QuickActions(item: item),
        _StockHistoryPanel(item: item, history: history),
      ],
    );
  }
}

/// Which tab to land on when there is no back-stack to pop to (a deep link
/// straight to an item, say) — a pure menu item's natural home is Menu
/// Items, everything else (raw material or "both") is Groceries.
String _fallbackTabName(InventoryItem item) =>
    item.itemType == 'sellable' ? AppRoute.menuItemsName : AppRoute.groceriesName;

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
          : context.goNamed(_fallbackTabName(item)),
      leading: _Thumbnail(item: item),
      badges: [
        StatusBadge(
          label: item.isArchived
              ? AppStrings.archivedBadge
              : AppStrings.activeBadge,
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
          label: const Text(AppStrings.editAction),
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
      child: ItemPhoto(
        emoji: item.emoji,
        emojiSize: 24,
        bytes: item.image?.bytes,
        imageUrl: item.imageUrl,
        catalogItemId: item.catalogItemId,
      ),
    );
  }
}

class _OverflowMenu extends ConsumerWidget {
  const _OverflowMenu({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: AppStrings.moreActions,
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
              Text(
                item.isArchived
                    ? AppStrings.restoreItem
                    : AppStrings.archiveItem,
              ),
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
                AppStrings.deleteItem,
                style: TextStyle(color: context.semantic.danger),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _toggleArchive(BuildContext context, WidgetRef ref) async {
    final archived = !item.isArchived;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(inventoryItemsProvider.notifier)
          .upsert(item.copyWith(isArchived: archived));
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            archived
                ? AppStrings.itemArchived(item.name)
                : AppStrings.itemRestored(item.name),
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(AppStrings.saveFailed(e))));
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.deleteItemTitle(item.name)),
        content: const Text(AppStrings.deleteItemBodyFull),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.deleteAction),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    // Leave first: this screen is watching the item that is about to stop
    // existing, and popping afterwards would flash the not-found state.
    context.canPop() ? context.pop() : context.goNamed(_fallbackTabName(item));

    try {
      await ref.read(inventoryItemsProvider.notifier).delete(item.id);
      ref.read(stockMovementsProvider.notifier).clearForItem(item.id);
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.itemDeleted(item.name))),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.deleteFailed(e))),
      );
    }
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
    // An untracked item (the common case for a pure menu item — see
    // item_form_provider.dart's `chooseType`) has no real stock count behind
    // it: `stock` is a placeholder, so "Current stock"/"Inventory value"
    // would be prominently showing a fabricated number. Lead with the
    // till-relevant figures instead; a tracked item (every grocery, and a
    // "both" item like a bottled drink) keeps the stock tiles, since those
    // numbers are real for it.
    final tiles = item.trackStock ? _stockTiles(context) : _salesTiles(context);

    return _tileGrid(context, tiles);
  }

  List<Widget> _stockTiles(BuildContext context) {
    final semantic = context.semantic;
    return [
      SummaryMetricCard(
        label: AppStrings.currentStock,
        value: Fmt.quantity(item.stock),
        trend: item.unit,
        icon: Icons.inventory_2_outlined,
        accent: item.status == StockStatus.inStock
            ? semantic.success
            : semantic.warning,
      ),
      SummaryMetricCard(
        label: AppStrings.unitCostLabel,
        value: Fmt.money(item.unitCost),
        trend: AppStrings.perUnit(item.unit),
        icon: Icons.sell_outlined,
      ),
      SummaryMetricCard(
        label: AppStrings.inventoryValue,
        value: Fmt.moneyCompact(item.totalValue),
        trend: AppStrings.atCost,
        icon: Icons.savings_outlined,
        accent: semantic.success,
      ),
      SummaryMetricCard(
        label: AppStrings.lowStockAt,
        value: Fmt.quantity(item.reorderLevel),
        trend: AppStrings.warnAtOrBelow,
        icon: Icons.warning_amber_rounded,
        accent: semantic.warning,
      ),
    ];
  }

  List<Widget> _salesTiles(BuildContext context) {
    final semantic = context.semantic;
    final margin = item.sellingPrice == null
        ? null
        : item.sellingPrice! - item.unitCost;
    final onMenu = item.isSellable && !item.isArchived;

    return [
      SummaryMetricCard(
        label: AppStrings.sellingPrice,
        value: item.sellingPrice == null
            ? AppStrings.emDash
            : Fmt.money(item.sellingPrice!),
        trend: item.sellingPrice == null
            ? AppStrings.notSet
            : AppStrings.atTheTill,
        icon: Icons.point_of_sale_rounded,
      ),
      SummaryMetricCard(
        label: AppStrings.unitCostLabel,
        value: Fmt.money(item.unitCost),
        trend: AppStrings.costBasis,
        icon: Icons.sell_outlined,
      ),
      SummaryMetricCard(
        label: AppStrings.marginLabel,
        value: margin == null ? AppStrings.emDash : Fmt.money(margin),
        trend: margin == null
            ? AppStrings.setPriceForMargin
            : AppStrings.perItemSold,
        icon: Icons.trending_up_rounded,
        accent: margin == null
            ? null
            : (margin >= 0 ? semantic.success : semantic.danger),
      ),
      SummaryMetricCard(
        label: AppStrings.posAvailability,
        value: onMenu ? AppStrings.availableValue : AppStrings.notListed,
        trend: onMenu ? AppStrings.showingAtTill : AppStrings.archivedNoPrice,
        icon: onMenu
            ? Icons.check_circle_rounded
            : Icons.remove_circle_outline_rounded,
        accent: onMenu ? semantic.success : semantic.warning,
      ),
    ];
  }

  Widget _tileGrid(BuildContext context, List<Widget> tiles) {
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

class _QuickActions extends ConsumerWidget {
  const _QuickActions({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Nothing to adjust, waste or move on a line that is not counted —
    // except production and recipe management, which live outside that
    // guard: the items being made are very often untracked
    // prepared-to-order lines, which is exactly what recipes and production
    // events are for.
    final recipeAction = _recipeAction(context, ref);
    if (!item.trackStock && !_canProduce(ref) && recipeAction == null) {
      return const SizedBox.shrink();
    }

    final buttons = <Widget>[
      if (_canProduce(ref)) _RecordProductionButton(item: item),
      if (recipeAction != null) recipeAction,
      // Everything below counts physical stock, so it stays behind the
      // tracked guard — an untracked line with a recipe shows only the
      // production button above.
      if (item.trackStock) ...[
        FilledButton.icon(
          onPressed: () => showStockAdjustDialog(context, item),
          icon: const Icon(Icons.tune_rounded, size: 18),
          label: const Text(AppStrings.adjustStock),
        ),
        // A sellable-only item can never be purchase-received (see
        // `stock_movement_service.py`'s `_COMPATIBILITY_RULES`) — reordering
        // it would always fail at receive time, so the action isn't offered.
        if (item.itemType != 'sellable')
          OutlinedButton.icon(
            onPressed: () => showReorderDialog(context, item),
            icon: const Icon(Icons.shopping_cart_outlined, size: 18),
            label: const Text(AppStrings.createReorder),
          ),
        OutlinedButton.icon(
          onPressed: item.stock == 0
              ? null
              : () => showWasteLogDialog(context, item),
          icon: const Icon(Icons.delete_sweep_outlined, size: 18),
          label: const Text(AppStrings.logWaste),
          style: OutlinedButton.styleFrom(
            foregroundColor: item.stock == 0 ? null : context.semantic.warning,
          ),
        ),
        OutlinedButton.icon(
          onPressed: item.stock == 0
              ? null
              : () => showStockTransferDialog(context, item),
          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
          label: const Text(AppStrings.transferStock),
        ),
      ],
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

  /// Whether the record-production action applies: the line is backed by a
  /// backend item with a defined recipe, and the session may record runs.
  /// Demo-mode rows (no `catalogItemId`) and recipe-less items get nothing.
  bool _canProduce(WidgetRef ref) {
    final catalogId = item.catalogItemId;
    if (catalogId == null) return false;
    if (!ref.watch(hasPermissionProvider(AppPermissions.productionCreate))) {
      return false;
    }
    return ref
            .watch(recipesCatalogProvider)
            .valueOrNull
            ?.any((recipe) => recipe.sellableItemId == catalogId) ??
        false;
  }

  /// The recipe management action for this line, if any applies: "Edit
  /// recipe" where one is defined (needs `recipes.update`), "Add recipe"
  /// where none is (needs `recipes.create`). Demo-mode rows get nothing —
  /// recipes genuinely need the backend's atomic catalog.
  Widget? _recipeAction(BuildContext context, WidgetRef ref) {
    final catalogId = item.catalogItemId;
    if (catalogId == null) return null;
    final recipe = ref
        .watch(recipesCatalogProvider)
        .valueOrNull
        ?.where((r) => r.sellableItemId == catalogId)
        .firstOrNull;
    if (recipe != null &&
        ref.watch(hasPermissionProvider(AppPermissions.recipesUpdate))) {
      return OutlinedButton.icon(
        onPressed: () => showRecipeFormDialog(context, recipe: recipe),
        icon: const Icon(Icons.receipt_long_outlined, size: 18),
        label: const Text(AppStrings.editRecipe),
      );
    }
    if (recipe == null &&
        ref.watch(hasPermissionProvider(AppPermissions.recipesCreate))) {
      return OutlinedButton.icon(
        onPressed: () =>
            showRecipeFormDialog(context, sellable: item),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text(AppStrings.addRecipe),
      );
    }
    return null;
  }
}

/// Opens the record-production dialog for this line's recipe.
///
/// Rendered only when [_QuickActions._canProduce] holds, so the recipe
/// lookup here always succeeds — the `!` documents that invariant rather
/// than hiding a real null case.
class _RecordProductionButton extends ConsumerWidget {
  const _RecordProductionButton({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipe = ref
        .watch(recipesCatalogProvider)
        .valueOrNull
        ?.where((r) => r.sellableItemId == item.catalogItemId)
        .firstOrNull;
    if (recipe == null) return const SizedBox.shrink();

    return FilledButton.icon(
      onPressed: () => showRecordProductionDialog(context, recipe),
      icon: const Icon(Icons.soup_kitchen_outlined, size: 18),
      label: const Text(AppStrings.recordProduction),
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

  @override
  Widget build(BuildContext context) {
    final query =
        TableQuery(page: _page, pageSize: AppLimits.tablePageSizeDense);
    final slice = PageSlice.of(widget.history, query);

    return DetailPanel(
      title: AppStrings.stockHistory,
      trailing: Text(
        AppStrings.movementsCount(widget.history.length),
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
      label: AppStrings.whenColumn,
      field: 'when',
      role: ColumnRole.primary,
      sortable: false,
      flex: 4,
      value: (m) => Fmt.relativeDateTime(m.at),
      cellBuilder: (context, m) => _WhenCell(movement: m),
    ),
    DataColumnSpec(
      label: AppStrings.typeColumn,
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
      label: AppStrings.changeColumn,
      field: 'delta',
      sortable: false,
      numeric: true,
      flex: 2,
      value: (m) => '${m.deltaLabel} ${item.unit}',
      cellBuilder: (context, m) => _DeltaCell(movement: m),
    ),
    DataColumnSpec(
      label: AppStrings.balanceColumn,
      field: 'balance',
      sortable: false,
      numeric: true,
      flex: 2,
      minTableWidth: 560,
      value: (m) => '${Fmt.quantity(m.balance)} ${item.unit}',
    ),
    DataColumnSpec(
      label: AppStrings.byColumn,
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
            AppStrings.noMovementsRecorded,
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
    final onPosMenu = item.isSellable && !item.isArchived;

    return DetailPanel(
      title: AppStrings.aboutThisItem,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hasDescription
                ? item.description
                : AppStrings.noDescription,
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
                label: AppStrings.itemTypeLabel,
                value: switch (item.itemType) {
                  'raw_material' => AppStrings.itemTypeGrocery,
                  'sellable' => AppStrings.itemTypeMenuItem,
                  _ => AppStrings.itemTypeBoth,
                },
                icon: switch (item.itemType) {
                  'raw_material' => Icons.shopping_basket_outlined,
                  'sellable' => Icons.restaurant_menu_rounded,
                  _ => Icons.swap_horiz_rounded,
                },
              ),
              LabeledValue(
                label: AppStrings.categoryLabel,
                value: categoryLabelFrom(
                  ref.watch(categoriesListProvider),
                  item.categoryId,
                ),
                icon: ref.watch(categoryByIdProvider(item.categoryId))?.icon ??
                    Icons.category_outlined,
              ),
              LabeledValue(
                label: AppStrings.skuLabel,
                value: item.sku,
                icon: Icons.qr_code_2_rounded,
              ),
              LabeledValue(
                label: AppStrings.supplierLabel,
                value: item.supplier,
                icon: Icons.local_shipping_outlined,
              ),
              LabeledValue(
                label: AppStrings.countedIn,
                value: item.unit,
                icon: Icons.straighten_rounded,
              ),
              LabeledValue(
                label: AppStrings.stockTracking,
                value: item.trackStock
                    ? AppStrings.onValue
                    : AppStrings.offValue,
                icon: item.trackStock
                    ? Icons.toggle_on_outlined
                    : Icons.toggle_off_outlined,
              ),
              LabeledValue(
                label: AppStrings.lastCounted,
                value: item.lastCountedAt == null
                    ? AppStrings.neverCounted
                    : Fmt.relativeDateTime(item.lastCountedAt!),
                icon: Icons.event_available_outlined,
              ),
              LabeledValue(
                label: AppStrings.posMenu,
                value: onPosMenu
                    ? AppStrings.availableForSale(
                        Fmt.money(item.sellingPrice ?? 0),
                      )
                    : AppStrings.notForSaleTill,
                icon: onPosMenu
                    ? Icons.point_of_sale_rounded
                    : Icons.point_of_sale_outlined,
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
                Text(
                  AppStrings.itemNotFound(itemId),
                  style: context.text.titleMedium,
                ),
                const SizedBox(height: Insets.lg),
                FilledButton.icon(
                  onPressed: () => context.goNamed(AppRoute.groceriesName),
                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                  label: const Text(AppStrings.backToInventory),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
