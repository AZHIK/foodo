import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';

/// A labelled group inside a filter panel.
class FilterSection extends StatelessWidget {
  const FilterSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title.toUpperCase(),
          style: context.text.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
            letterSpacing: 0.9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: Insets.md),
        child,
      ],
    );
  }
}

/// Multi-select as a wrap of toggle chips.
///
/// Generic over the value so a page can select categories, statuses, payment
/// methods or anything else without a bespoke widget each time.
class FilterChipGroup<T> extends StatelessWidget {
  const FilterChipGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onToggle,
    this.iconOf,
  });

  final List<T> options;
  final Set<T> selected;
  final String Function(T value) labelOf;
  final IconData? Function(T value)? iconOf;
  final ValueChanged<T> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Insets.sm,
      runSpacing: Insets.sm,
      children: [
        for (final option in options)
          FilterChip(
            selected: selected.contains(option),
            onSelected: (_) => onToggle(option),
            avatar: iconOf?.call(option) == null
                ? null
                : Icon(iconOf!(option), size: 16),
            label: Text(labelOf(option)),
            showCheckmark: iconOf?.call(option) == null,
          ),
      ],
    );
  }
}

/// A min/max pair for filtering a numeric column.
///
/// Both ends are optional: "at least 10" and "at most 5" are as useful as a
/// closed range, so an empty field means "unbounded" rather than zero.
class NumberRangeField extends StatefulWidget {
  const NumberRangeField({
    super.key,
    required this.min,
    required this.max,
    required this.onChanged,
    this.ceiling,
  });

  final int? min;
  final int? max;
  final void Function(int? min, int? max) onChanged;

  /// Shown as the upper hint, so the user knows the scale of the data.
  final int? ceiling;

  @override
  State<NumberRangeField> createState() => _NumberRangeFieldState();
}

class _NumberRangeFieldState extends State<NumberRangeField> {
  late final TextEditingController _min;
  late final TextEditingController _max;

  @override
  void initState() {
    super.initState();
    _min = TextEditingController(text: widget.min?.toString() ?? '');
    _max = TextEditingController(text: widget.max?.toString() ?? '');
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _emit() {
    final min = int.tryParse(_min.text.trim());
    final max = int.tryParse(_max.text.trim());
    widget.onChanged(min, max);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _field(_min, 'Min', '0')),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: Insets.md),
          child: Text('–'),
        ),
        Expanded(child: _field(_max, 'Max', widget.ceiling?.toString() ?? '')),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label, String hint) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => _emit(),
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}
