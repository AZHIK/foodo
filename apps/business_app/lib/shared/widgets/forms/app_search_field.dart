import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';

/// Dedicated standalone search input, separate from the one bundled
/// inside [AppDataTable].
///
/// Includes a 250 ms debounce (configurable) before [onChanged] fires,
/// a clear button that appears when the field is non-empty, and a
/// built-in leading search icon — so callers can drop it in without
/// wiring up decoration.
///
/// Usage (POS item-picker search):
/// ```dart
/// AppSearchField(
///   hintText: 'Search dishes, drinks, SKUs…',
///   onChanged: (q) => ref.read(searchProvider.notifier).query(q),
/// )
/// ```
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    this.hintText = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.focusNode,
    this.debounce = const Duration(milliseconds: 250),
    this.autoFocus = false,
    this.enabled = true,
  });

  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Duration debounce;
  final bool autoFocus;
  final bool enabled;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounce;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller.addListener(_onTextChanged);
    _hasText = _controller.text.isNotEmpty;
  }

  @override
  void didUpdateWidget(covariant AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onTextChanged);
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _debounce?.cancel();
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final nonEmpty = _controller.text.isNotEmpty;
    if (nonEmpty != _hasText) {
      setState(() => _hasText = nonEmpty);
    }
    if (widget.onChanged == null) return;
    _debounce?.cancel();
    final text = _controller.text;
    if (widget.debounce == Duration.zero) {
      widget.onChanged!(text);
    } else {
      _debounce = Timer(widget.debounce, () => widget.onChanged!(text));
    }
  }

  void _clear() {
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.6)),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      borderSide: BorderSide(color: cs.primary, width: 1.5),
    );

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      autofocus: widget.autoFocus,
      style: AppTextStyles.bodyLarge.copyWith(color: cs.onSurface),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: AppTextStyles.bodyLarge.copyWith(
          color: cs.onSurface.withValues(alpha: 0.45),
        ),
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: cs.onSurface.withValues(alpha: 0.6),
          size: 22,
        ),
        suffixIcon: _hasText
            ? IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: cs.onSurface.withValues(alpha: 0.6),
                  size: 20,
                ),
                onPressed: _clear,
                tooltip: 'Clear',
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceMD,
          vertical: AppDimensions.spaceSM,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: focusedBorder,
      ),
      onSubmitted: widget.onSubmitted,
    );
  }
}
