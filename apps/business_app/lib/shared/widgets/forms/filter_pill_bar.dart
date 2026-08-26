import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';

/// Horizontally-scrollable row of filter pills — one filled/active pill
/// (accent background, light text) and the rest outlined (white
/// background, hairline border, dark text).
///
/// Generic over label strings so any single-select filter (category,
/// status, etc.) can reuse it instead of a bespoke [ChoiceChip] row.
///
/// Usage:
/// ```dart
/// FilterPillBar(
///   labels: const ['All', 'Rice', 'Drinks', 'Grills'],
///   selectedLabel: _category,
///   onSelected: (label) => setState(() => _category = label),
///   displayLabel: (label) => label == 'All' ? 'Show All' : label,
/// )
/// ```
class FilterPillBar extends StatelessWidget {
  const FilterPillBar({
    super.key,
    required this.labels,
    required this.selectedLabel,
    required this.onSelected,
    this.displayLabel,
  });

  /// The underlying filter values, in display order.
  final List<String> labels;

  /// The currently-active value — must match one entry in [labels].
  final String selectedLabel;
  final ValueChanged<String> onSelected;

  /// Optional override for the text shown per pill, keyed by the
  /// underlying value (e.g. render `'All'` as `'Show All'` without
  /// changing the value callers filter on).
  final String Function(String label)? displayLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.spaceXS),
        itemBuilder: (context, index) {
          final label = labels[index];
          final selected = label == selectedLabel;
          return _FilterPill(
            label: displayLabel?.call(label) ?? label,
            selected: selected,
            onTap: () => onSelected(label),
          );
        },
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppDimensions.radiusFull);
    return Material(
      color: selected ? cs.primary : cs.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceMD,
            vertical: AppDimensions.spaceXS,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: selected
                ? null
                : Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.9),
                    width: 0.8,
                  ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
              color: selected ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),
    );
  }
}
