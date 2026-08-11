import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';

/// Numeric input with increment / decrement stepper buttons.
///
/// Sign constraints are *parameter-driven* via [allowNegative] and
/// [allowZero] — no hardcoded business rules.  The widget always works
/// with [int] values so floating-point precision bugs can't creep in at
/// the value layer (decimals like TZS senti are represented as whole
/// ints, with the format responsibility left to a dedicated
/// [MoneyField] or caller-supplied [formatValue]).
///
/// Usage — POS quantity (positive, non-zero):
/// ```dart
/// AppNumberField(
///   label: 'Qty',
///   initialValue: 1,
///   min: 1,
///   step: 1,
///   allowNegative: false,
///   allowZero: false,
///   onChanged: (q) => _updateQty(line, q),
/// )
/// ```
class AppNumberField extends StatefulWidget {
  const AppNumberField({
    super.key,
    this.label,
    this.hint,
    this.initialValue = 0,
    this.step = 1,
    this.min,
    this.max,
    this.allowNegative = true,
    this.allowZero = true,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
    this.formatValue,
  })  : assert(step > 0, 'step must be positive'),
        assert(
          min == null || allowNegative || min >= 0,
          'min cannot be negative when allowNegative is false',
        );

  final String? label;
  final String? hint;
  final int initialValue;
  final int step;
  final int? min;
  final int? max;
  final bool allowNegative;
  final bool allowZero;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<int>? onChanged;
  final ValueChanged<int>? onSubmitted;
  final String? Function(int?)? validator;
  final bool enabled;
  final IconData? prefixIcon;

  /// Optional override for how the number is displayed inside the
  /// text field (e.g. add thousand separators).  The returned string
  /// must parse back to the same integer when stripped of non-digit /
  /// non-minus characters.
  final String Function(int value)? formatValue;

  @override
  State<AppNumberField> createState() => _AppNumberFieldState();
}

class _AppNumberFieldState extends State<AppNumberField> {
  late final TextEditingController _controller;
  late FocusNode _focusNode;
  late int _value;
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _value = _clamp(widget.initialValue);
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _syncTextFromValue(silent: true);
  }

  @override
  void didUpdateWidget(covariant AppNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      if (oldWidget.focusNode == null) _focusNode.dispose();
      _focusNode = widget.focusNode ?? FocusNode();
    }
    if (oldWidget.initialValue != widget.initialValue &&
        !_isComposing &&
        !_focusNode.hasFocus) {
      _value = _clamp(widget.initialValue);
      _syncTextFromValue(silent: true);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  int _clamp(int v) {
    var out = v;
    if (widget.max != null && out > widget.max!) out = widget.max!;
    if (widget.min != null && out < widget.min!) out = widget.min!;
    if (!widget.allowNegative && out < 0) out = 0;
    if (!widget.allowZero && out == 0) {
      out = widget.step > 0 ? widget.step : 1;
    }
    return out;
  }

  void _syncTextFromValue({required bool silent}) {
    final formatted = widget.formatValue != null
        ? widget.formatValue!(_value)
        : _value.toString();
    if (_controller.text != formatted) {
      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    if (!silent) {
      widget.onChanged?.call(_value);
    }
  }

  void _step(int delta) {
    final next = _clamp(_value + delta);
    final changed = next != _value;
    if (changed) {
      setState(() => _value = next);
    }
    _syncTextFromValue(silent: !changed);
    if (!changed) {
      widget.onChanged?.call(_value);
    }
  }

  void _parseInput(String raw) {
    _isComposing = true;
    try {
      final cleaned = raw.replaceAll(RegExp(r'[^\d\-]'), '');
      if (cleaned.isEmpty || cleaned == '-') {
        if (widget.allowZero) {
          setState(() => _value = 0);
          widget.onChanged?.call(0);
        }
        return;
      }
      final parsed = int.tryParse(cleaned);
      if (parsed == null) {
        _syncTextFromValue(silent: false);
        return;
      }
      final clamped = _clamp(parsed);
      setState(() => _value = clamped);
      widget.onChanged?.call(clamped);
      if (clamped != parsed) _syncTextFromValue(silent: true);
    } finally {
      _isComposing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stepperColor =
        widget.enabled ? cs.primary : cs.onSurface.withValues(alpha: 0.38);

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      borderSide: BorderSide(color: cs.outline),
    );

    final enabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.7)),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      borderSide: BorderSide(color: cs.primary, width: 1.5),
    );

    return FormField<int>(
      initialValue: _value,
      validator: widget.validator == null
          ? null
          : (_) => widget.validator!(_value),
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: false,
            ),
            textInputAction: TextInputAction.done,
            style: AppTextStyles.bodyLarge.copyWith(
              color: widget.enabled
                  ? cs.onSurface
                  : cs.onSurface.withValues(alpha: 0.38),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d\-\,\.\s]')),
            ],
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon)
                  : null,
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: AppDimensions.spaceXS),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _stepperButton(
                      onPressed:
                          widget.enabled ? () => _step(-widget.step) : null,
                      color: stepperColor,
                      icon: Icons.remove,
                    ),
                    const SizedBox(width: AppDimensions.spaceXXS),
                    _stepperButton(
                      onPressed:
                          widget.enabled ? () => _step(widget.step) : null,
                      color: stepperColor,
                      icon: Icons.add,
                    ),
                  ],
                ),
              ),
              border: border,
              enabledBorder: enabledBorder,
              focusedBorder: focusedBorder,
              disabledBorder: enabledBorder,
              errorBorder: border.copyWith(
                borderSide: BorderSide(color: cs.error),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceMD,
                vertical: AppDimensions.spaceMD,
              ),
            ),
            onChanged: _parseInput,
            onSubmitted: (_) => widget.onSubmitted?.call(_value),
          ),
          if (state.hasError) ...[
            const SizedBox(height: AppDimensions.spaceXXS + 2),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceMD,
              ),
              child: Text(
                state.errorText!,
                style: AppTextStyles.bodySmall.copyWith(color: cs.error),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stepperButton({
    required VoidCallback? onPressed,
    required Color color,
    required IconData icon,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spaceXS),
          decoration: BoxDecoration(
            color: color.withValues(alpha: onPressed != null ? 0.10 : 0.04),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
      ),
    );
  }
}
