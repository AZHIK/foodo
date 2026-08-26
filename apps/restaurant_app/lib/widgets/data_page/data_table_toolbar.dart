import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';

/// One entry in the Sort menu.
@immutable
class SortOption {
  const SortOption({required this.label, required this.field});

  final String label;

  /// Matches the [DataColumnSpec.field] it sorts by.
  final String field;
}

/// Search + Filter + Sort above a data table.
///
/// Filter content is supplied by the page as a builder, so this widget knows
/// nothing about what is being filtered — it only decides *where* that content
/// appears: a popover anchored to the button on desktop, a bottom sheet on
/// mobile where a popover would be unusable.
class DataTableToolbar extends StatefulWidget {
  const DataTableToolbar({
    super.key,
    required this.searchHint,
    required this.searchValue,
    required this.onSearchChanged,
    required this.filterBuilder,
    required this.sortOptions,
    required this.sortField,
    required this.sortAscending,
    required this.onSortChanged,
    this.activeFilterCount = 0,
    this.onClearFilters,
  });

  final String searchHint;
  final String searchValue;
  final ValueChanged<String> onSearchChanged;

  /// Page-specific filter fields. Rendered inside a popover or sheet.
  final WidgetBuilder filterBuilder;

  final List<SortOption> sortOptions;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field, bool ascending) onSortChanged;

  /// Drives the count badge on the Filter button.
  final int activeFilterCount;
  final VoidCallback? onClearFilters;

  @override
  State<DataTableToolbar> createState() => _DataTableToolbarState();
}

class _DataTableToolbarState extends State<DataTableToolbar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final isMobile = context.isMobile;

    if (isMobile) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => _FilterSheet(
          onClear: widget.onClearFilters,
          child: widget.filterBuilder(sheetContext),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      builder: (dialogContext) => _FilterPopover(
        onClear: widget.onClearFilters,
        child: widget.filterBuilder(dialogContext),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep the field in step when something else clears the search.
    if (_controller.text != widget.searchValue) {
      _controller.value = TextEditingValue(
        text: widget.searchValue,
        selection: TextSelection.collapsed(offset: widget.searchValue.length),
      );
    }

    final search = TextField(
      controller: _controller,
      onChanged: widget.onSearchChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.searchHint,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: widget.searchValue.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => widget.onSearchChanged(''),
              ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Below this the three controls stop fitting on one line, so search
        // takes the row and the buttons collapse to icons beneath it.
        final tight = constraints.maxWidth < 560;

        final filterButton = _ToolbarButton(
          icon: Icons.filter_list_rounded,
          label: 'Filter',
          badgeCount: widget.activeFilterCount,
          iconOnly: tight,
          onPressed: _openFilters,
        );

        final sortButton = _SortButton(
          options: widget.sortOptions,
          field: widget.sortField,
          ascending: widget.sortAscending,
          onChanged: widget.onSortChanged,
          iconOnly: tight,
        );

        if (!tight) {
          return Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: Insets.sm),
              filterButton,
              const SizedBox(width: Insets.sm),
              sortButton,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            search,
            const SizedBox(height: Insets.sm),
            Row(children: [filterButton, const SizedBox(width: Insets.sm), sortButton]),
          ],
        );
      },
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.badgeCount = 0,
    this.iconOnly = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final int badgeCount;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final active = badgeCount > 0;
    final colors = context.colors;

    final child = OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: iconOnly
          ? const SizedBox.shrink()
          : Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: iconOnly ? Insets.md : Insets.lg),
        backgroundColor: active ? colors.primaryContainer : null,
        foregroundColor: active ? colors.onPrimaryContainer : null,
        side: BorderSide(
          color: active ? colors.primary : colors.outlineVariant,
        ),
      ),
    );

    if (!active) return child;
    return Badge.count(count: badgeCount, child: child);
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.options,
    required this.field,
    required this.ascending,
    required this.onChanged,
    required this.iconOnly,
  });

  final List<SortOption> options;
  final String? field;
  final bool ascending;
  final void Function(String field, bool ascending) onChanged;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final current = options.where((o) => o.field == field).firstOrNull;

    return PopupMenuButton<({String field, bool ascending})>(
      tooltip: 'Sort',
      position: PopupMenuPosition.under,
      onSelected: (value) => onChanged(value.field, value.ascending),
      itemBuilder: (context) => [
        for (final option in options) ...[
          CheckedPopupMenuItem(
            value: (field: option.field, ascending: true),
            checked: option.field == field && ascending,
            child: Text('${option.label} — ascending'),
          ),
          CheckedPopupMenuItem(
            value: (field: option.field, ascending: false),
            checked: option.field == field && !ascending,
            child: Text('${option.label} — descending'),
          ),
        ],
      ],
      child: Container(
        height: 48,
        padding: EdgeInsets.symmetric(
          horizontal: iconOnly ? Insets.md : Insets.lg,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ascending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 18,
              color: colors.onSurface,
            ),
            if (!iconOnly) ...[
              const SizedBox(width: Insets.sm),
              // The active column is named, so the button reports the current
              // sort rather than just offering to change it.
              Flexible(
                child: Text(
                  current?.label ?? 'Sort',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelLarge,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Desktop/tablet filter container — a small panel floated over the page.
class _FilterPopover extends StatelessWidget {
  const _FilterPopover({required this.child, this.onClear});

  final Widget child;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topRight,
      insetPadding: const EdgeInsets.only(
        top: 140,
        right: Insets.xxl,
        left: Insets.lg,
        bottom: Insets.lg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 560),
        child: _FilterBody(onClear: onClear, child: child),
      ),
    );
  }
}

/// Mobile filter container.
class _FilterSheet extends StatelessWidget {
  const _FilterSheet({required this.child, this.onClear});

  final Widget child;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
        child: SafeArea(
          top: false,
          child: _FilterBody(onClear: onClear, child: child),
        ),
      ),
    );
  }
}

class _FilterBody extends StatelessWidget {
  const _FilterBody({required this.child, this.onClear});

  final Widget child;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.xl,
            Insets.lg,
            Insets.md,
            Insets.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text('Filters', style: context.text.titleMedium),
              ),
              if (onClear != null)
                TextButton(
                  onPressed: () {
                    onClear!();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Clear all'),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Insets.xl),
            child: child,
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(Insets.lg),
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }
}
