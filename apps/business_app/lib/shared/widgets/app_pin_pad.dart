import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_durations.dart';
import '../../core/constants/app_text_styles.dart';

/// Visual PIN entry widget composed of a dot-indicator row and a
/// 3×4 numeric keypad.
///
/// - [minLength] / [maxLength] control validation (mirrors [AppDurations] policy).
/// - Calls [onCompleted] when the entered PIN reaches [maxLength].
/// - Calls [onChanged] on every keystroke.
///
/// The widget is purely presentation: the PIN string is owned by the parent.
class AppPinPad extends StatefulWidget {
  const AppPinPad({
    super.key,
    this.minLength = 4,
    this.maxLength = 6,
    this.errorText,
    this.onChanged,
    this.onCompleted,
    this.label,
    this.enabled = true,
  });

  final int minLength;
  final int maxLength;
  final String? errorText;
  final String? label;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  /// Called once when the PIN length reaches [maxLength].
  final ValueChanged<String>? onCompleted;

  @override
  State<AppPinPad> createState() => AppPinPadState();

  /// Exposed so parents can call [AppPinPadState.clear].
  static AppPinPadState? of(BuildContext context) =>
      context.findAncestorStateOfType<AppPinPadState>();
}

class AppPinPadState extends State<AppPinPad> {
  String _pin = '';

  /// Clears the current PIN entry.
  void clear() => setState(() => _pin = '');

  /// Returns the current PIN string.
  String get value => _pin;

  void _tap(String digit) {
    if (!widget.enabled) return;
    if (_pin.length >= widget.maxLength) return;
    HapticFeedback.lightImpact();
    setState(() => _pin += digit);
    widget.onChanged?.call(_pin);
    if (_pin.length == widget.maxLength) {
      widget.onCompleted?.call(_pin);
    }
  }

  void _delete() {
    if (_pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
    widget.onChanged?.call(_pin);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasError = widget.errorText != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTextStyles.titleSmall.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMD),
        ],

        // ── Dot indicators ───────────────────────────────────────
        _DotIndicator(
          filled: _pin.length,
          total: widget.maxLength,
          minFilled: widget.minLength,
          hasError: hasError,
          colorScheme: colorScheme,
        ),

        // ── Error text ───────────────────────────────────────────
        AnimatedSize(
          duration: AppDurations.fast,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: AppDimensions.spaceSM),
                  child: Text(
                    widget.errorText!,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: AppDimensions.spaceXL),

        // ── Numeric keyboard ─────────────────────────────────────
        _NumericKeypad(
          onDigit: _tap,
          onDelete: _delete,
          enabled: widget.enabled,
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

// ── Internal widgets ───────────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({
    required this.filled,
    required this.total,
    required this.minFilled,
    required this.hasError,
    required this.colorScheme,
  });

  final int filled;
  final int total;
  final int minFilled;
  final bool hasError;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isFilled = i < filled;
        final color = hasError
            ? colorScheme.error
            : isFilled
                ? AppColors.lightPrimary
                : colorScheme.outline.withValues(alpha: 0.3);

        return AnimatedContainer(
          duration: AppDurations.fast,
          margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceSM),
          width: isFilled ? 16 : 14,
          height: isFilled ? 16 : 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
          ),
        );
      }),
    );
  }
}

class _NumericKeypad extends StatelessWidget {
  const _NumericKeypad({
    required this.onDigit,
    required this.onDelete,
    required this.enabled,
    required this.colorScheme,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final bool enabled;
  final ColorScheme colorScheme;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', 'del'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spaceSM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              if (key.isEmpty) {
                return const SizedBox(width: 80, height: 64);
              }
              if (key == 'del') {
                return _KeypadButton(
                  onTap: enabled ? onDelete : null,
                  colorScheme: colorScheme,
                  child: Icon(
                    Icons.backspace_outlined,
                    size: 22,
                    color: enabled
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                );
              }
              return _KeypadButton(
                onTap: enabled ? () => onDigit(key) : null,
                colorScheme: colorScheme,
                child: Text(
                  key,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: enabled
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withValues(alpha: 0.38),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    required this.onTap,
    required this.colorScheme,
    required this.child,
  });

  final VoidCallback? onTap;
  final ColorScheme colorScheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceSM),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          splashColor: colorScheme.primary.withValues(alpha: 0.12),
          highlightColor: colorScheme.primary.withValues(alpha: 0.08),
          child: Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surfaceContainerHighest,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
