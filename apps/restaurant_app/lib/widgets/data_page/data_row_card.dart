import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import 'data_column_spec.dart';

/// A table row restacked as a card, for widths where columns stop working.
///
/// Built from the same [DataColumnSpec] list the table uses: the
/// [ColumnRole.primary] column becomes the title, [ColumnRole.status] the
/// corner badge, and [ColumnRole.secondary] columns the label/value pairs
/// underneath. Pages get this for free by declaring roles on their columns.
class DataRowCard<T> extends StatelessWidget {
  const DataRowCard({
    super.key,
    required this.row,
    required this.columns,
    this.onTap,
    this.actions = const [],
  });

  final T row;
  final List<DataColumnSpec<T>> columns;
  final VoidCallback? onTap;
  final List<DataRowAction<T>> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final primary = columns.where((c) => c.role == ColumnRole.primary).firstOrNull;
    final status = columns.where((c) => c.role == ColumnRole.status).firstOrNull;
    final details = columns
        .where((c) => c.role == ColumnRole.secondary)
        .toList();

    return Material(
      color: colors.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.card,
        side: BorderSide(color: context.semantic.hairline),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Insets.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: primary == null
                        ? const SizedBox.shrink()
                        : primary.hasCustomCell
                        ? primary.build(context, row)
                        : Text(
                            primary.value(row),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  if (status != null) ...[
                    const SizedBox(width: Insets.sm),
                    // Flexible so a long status ("Out of stock", "Pending
                    // invite") gives way to the title instead of pushing the
                    // row past the card's edge on a 240px phone.
                    Flexible(child: status.build(context, row)),
                  ],
                  if (actions.isNotEmpty)
                    _CardActionsMenu<T>(row: row, actions: actions),
                ],
              ),
              if (details.isNotEmpty) ...[
                const SizedBox(height: Insets.md),
                Wrap(
                  spacing: Insets.lg,
                  runSpacing: Insets.sm,
                  children: [
                    for (final column in details)
                      _Detail(label: column.label, value: column.value(row)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            letterSpacing: 0.7,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CardActionsMenu<T> extends StatelessWidget {
  const _CardActionsMenu({required this.row, required this.actions});

  final T row;
  final List<DataRowAction<T>> actions;

  @override
  Widget build(BuildContext context) {
    return RowActionsMenu<T>(row: row, actions: actions);
  }
}

/// The trailing "…" overflow menu, shared by table rows and cards.
class RowActionsMenu<T> extends StatelessWidget {
  const RowActionsMenu({super.key, required this.row, required this.actions});

  final T row;
  final List<DataRowAction<T>> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PopupMenuButton<DataRowAction<T>>(
      tooltip: 'Row actions',
      icon: Icon(
        Icons.more_horiz_rounded,
        size: 18,
        color: colors.onSurfaceVariant,
      ),
      padding: EdgeInsets.zero,
      // Captured before the menu route pops, so the callback runs against the
      // page's context rather than a dead one.
      onSelected: (action) => action.onSelected(context, row),
      itemBuilder: (context) => [
        for (final action in actions)
          PopupMenuItem(
            value: action,
            enabled: action.enabledFor(row),
            child: Row(
              children: [
                Icon(
                  action.icon,
                  size: 17,
                  color: action.isDestructive
                      ? context.semantic.danger
                      : colors.onSurfaceVariant,
                ),
                const SizedBox(width: Insets.md),
                Text(
                  action.label,
                  style: action.isDestructive
                      ? TextStyle(color: context.semantic.danger)
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
