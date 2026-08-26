import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/orders_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';

/// Today / This week / This month / All time / Custom.
///
/// Takes the primary-action slot on the Sales page, where Inventory has its
/// "Add item" button — a sales ledger has nothing to add, but the period it
/// covers is the single most useful control on the page.
class SalesDateRangeSelector extends ConsumerWidget {
  const SalesDateRangeSelector({super.key, this.filled = true});

  /// Emphasised in the page header; plain inside the filter panel.
  final bool filled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(salesFiltersProvider);
    final notifier = ref.read(salesFiltersProvider.notifier);
    final colors = context.colors;
    final isMobile = context.isMobile;

    Future<void> pickCustom() async {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 2),
        lastDate: now,
        initialDateRange: filters.customRange,
        helpText: 'Select a sales period',
      );
      if (picked != null) notifier.setCustomRange(picked);
    }

    // Icon-only button on mobile
    if (isMobile && filled) {
      return PopupMenuButton<SalesDateRange>(
        tooltip: 'Change period',
        position: PopupMenuPosition.under,
        onSelected: (range) => range == SalesDateRange.custom
            ? pickCustom()
            : notifier.setRange(range),
        itemBuilder: (context) => [
          for (final range in SalesDateRange.values)
            CheckedPopupMenuItem(
              value: range,
              checked: range == filters.range,
              child: Text(
                range == SalesDateRange.custom ? 'Custom…' : range.label,
              ),
            ),
        ],
        child: SizedBox(
          height: 40,
          width: 40,
          child: Icon(
            Icons.calendar_today_rounded,
            size: 20,
            color: colors.onSurface,
          ),
        ),
      );
    }

    return PopupMenuButton<SalesDateRange>(
      tooltip: 'Change period',
      position: PopupMenuPosition.under,
      onSelected: (range) => range == SalesDateRange.custom
          ? pickCustom()
          : notifier.setRange(range),
      itemBuilder: (context) => [
        for (final range in SalesDateRange.values)
          CheckedPopupMenuItem(
            value: range,
            checked: range == filters.range,
            child: Text(
              range == SalesDateRange.custom ? 'Custom…' : range.label,
            ),
          ),
      ],
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
        decoration: BoxDecoration(
          color: filled ? colors.primaryContainer : null,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
            color: filled ? colors.primary : colors.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 17,
              color: filled ? colors.onPrimaryContainer : colors.onSurface,
            ),
            const SizedBox(width: Insets.sm),
            Flexible(
              child: Text(
                labelFor(filters),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelLarge?.copyWith(
                  color: filled ? colors.onPrimaryContainer : colors.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 20,
              color: filled ? colors.onPrimaryContainer : colors.onSurface,
            ),
          ],
        ),
      ),
    );
  }

  /// A custom window names its dates — "Custom" alone would leave the user
  /// unable to tell what the table is showing. Public so the exporters can
  /// stamp the same period onto the file they produce.
  static String labelFor(SalesFilters filters) {
    if (filters.range != SalesDateRange.custom) return filters.range.label;
    final range = filters.customRange;
    if (range == null) return 'Custom';
    return '${Fmt.dayMonth(range.start)} – ${Fmt.dayMonth(range.end)}';
  }
}
