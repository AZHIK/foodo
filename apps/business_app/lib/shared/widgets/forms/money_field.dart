import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';

/// Currency-formatted input for Tanzanian Shillings (TZS).
///
/// **Internal value is `int` senti** (hundredths of a TZS).  The widget
/// never works with `double` so floating-point precision bugs cannot
/// exist at the value layer.  Display formatting (thousand separators,
/// "TZS" prefix) is applied on the fly as the user types, and stripped
/// back out before [onChanged] fires with a clean senti `int`.
///
/// Conversion boundary note (for real-backend integration later): the
/// senti ↔ backend Decimal/numeric conversion must be a single,
/// well-tested function in the data layer — no inline `~/ 100` math
/// scattered across screens.
///
/// Usage:
/// ```dart
/// MoneyField(
///   label: 'Unit price',
///   initialSenti: 850000,        // 8,500 TZS
///   allowZero: false,
///   onChanged: (senti) => _priceSenti = senti,
/// )
/// ```
class MoneyField extends StatefulWidget {
  const MoneyField({
    super.key,
    this.label,
    this.hint,
    this.initialSenti = 0,
    this.minSenti,
    this.maxSenti,
    this.allowZero = true,
    this.allowNegative = false,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.enabled = true,
    this.prefixIcon = Icons.monetization_on_outlined,
  })  : assert(
          minSenti == null || allowNegative || minSenti >= 0,
          'minSenti cannot be negative when allowNegative is false',
        ),
        assert(allowZero || initialSenti != 0, 'initialSenti must be non-zero');

  final String? label;
  final String? hint;

  /// Initial value in **senti** (1 TZS = 100 senti).
  final int initialSenti;
  final int? minSenti;
  final int? maxSenti;
  final bool allowZero;
  final bool allowNegative;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<int>? onChanged;
  final ValueChanged<int>? onSubmitted;
  final String? Function(int? senti)? validator;
  final bool enabled;
  final IconData? prefixIcon;

  /// Formats senti as a TZS display string (e.g. `850000` → `TZS 8,500`).
  static String formatDisplay(int senti) {
    final sign = senti < 0 ? '-' : '';
    final whole = senti.abs() ~/ 100;
    final digits = whole.toString();
    final buf = StringBuffer();
    final len = digits.length;
    for (var i = 0; i < len; i++) {
      final fromRight = len - i - 1;
      if (i > 0 && fromRight % 3 == 2 && len > 3) {
        buf.write(',');
      }
      buf.write(digits[i]);
    }
    return '$sign TZS $buf';
  }

  /// Parses a user-entered string back to senti.
  /// Returns null when the input is empty / incomplete.
  static int? parseSenti(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d\-]'), '');
    if (cleaned.isEmpty || cleaned == '-') return null;
    final whole = int.tryParse(cleaned);
    if (whole == null) return null;
    return whole * 100; // user-entered whole TZS → senti
  }

  @override
  State<MoneyField> createState() => _MoneyFieldState();
}

class _MoneyFieldState extends State<MoneyField> {
  late final TextEditingController _controller;
  late FocusNode _focusNode;
  late int _senti;

  @override
  void initState() {
    super.initState();
    _senti = _clamp(widget.initialSenti);
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _syncText(silent: true);
  }

  @override
  void didUpdateWidget(covariant MoneyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      if (oldWidget.focusNode == null) _focusNode.dispose();
      _focusNode = widget.focusNode ?? FocusNode();
    }
    if (oldWidget.initialSenti != widget.initialSenti &&
        !_focusNode.hasFocus) {
      _senti = _clamp(widget.initialSenti);
      _syncText(silent: true);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  int _clamp(int s) {
    var out = s;
    if (widget.maxSenti != null && out > widget.maxSenti!) {
      out = widget.maxSenti!;
    }
    if (widget.minSenti != null && out < widget.minSenti!) {
      out = widget.minSenti!;
    }
    if (!widget.allowNegative && out < 0) out = 0;
    if (!widget.allowZero && out == 0) out = 100; // 1 TZS minimum
    return out;
  }

  void _syncText({required bool silent}) {
    final text = MoneyField.formatDisplay(_senti);
    if (_controller.text != text) {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    if (!silent) widget.onChanged?.call(_senti);
  }

  void _onInputChanged(String raw) {
    final parsed = MoneyField.parseSenti(raw);
    if (parsed == null) {
      if (widget.allowZero) {
        _senti = 0;
        widget.onChanged?.call(0);
      }
      return;
    }
    final clamped = _clamp(parsed);
    if (clamped != parsed) {
      // Out of range — snap the text back so the user sees the clamp.
      _senti = clamped;
      _syncText(silent: false);
      return;
    }
    _senti = clamped;
    // Update the visual formatting (commas, prefix) without re-issuing
    // onChanged (would be the same value anyway).
    _syncText(silent: true);
    widget.onChanged?.call(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
      initialValue: _senti,
      validator:
          widget.validator == null ? null : (_) => widget.validator!(_senti),
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            keyboardType: const TextInputType.numberWithOptions(
              signed: false,
              decimal: false,
            ),
            textInputAction: TextInputAction.done,
            style: AppTextStyles.titleMedium.copyWith(
              color: widget.enabled
                  ? cs.onSurface
                  : cs.onSurface.withValues(alpha: 0.38),
              fontWeight: FontWeight.w700,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d\,\s\-]')),
            ],
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon)
                  : null,
              border: border,
              enabledBorder: enabledBorder,
              focusedBorder: focusedBorder,
              errorBorder: border.copyWith(
                borderSide: BorderSide(color: cs.error),
              ),
              errorText: state.errorText,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceMD,
                vertical: AppDimensions.spaceMD,
              ),
            ),
            onChanged: _onInputChanged,
            onSubmitted: (_) => widget.onSubmitted?.call(_senti),
          ),
        ],
      ),
    );
  }
}
