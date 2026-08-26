import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import 'shake.dart';

/// A row of boxed digits that advance themselves.
///
/// Separate fields rather than one masked field because that is what makes each
/// digit individually correctable — the thing people actually do when they
/// mistype a code.
///
/// The controllers and focus nodes are owned by the caller: the screen has to
/// read the assembled code and clear it on rejection, and passing them in beats
/// handing a value back out through a callback on every keystroke.
class OtpInput extends StatelessWidget {
  const OtpInput({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    this.hasError = false,
    this.enabled = true,
    this.shakeToken = 0,
    this.keyBuilder,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;

  /// Called with the box index and its new raw value. A value longer than one
  /// character is a paste, and the caller is expected to spread it.
  final void Function(int index, String value) onChanged;

  final bool hasError;
  final bool enabled;

  /// Bumped by the caller to trigger the rejection shake.
  final int shakeToken;

  /// Supplies a widget key per box so tests can address individual digits.
  final Key Function(int index)? keyBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = Insets.sm;
        // Six boxes have to fit a 360px phone inside a padded card, so the box
        // is sized from the row rather than fixed and hoped for.
        final width =
            ((constraints.maxWidth - gap * (controllers.length - 1)) /
                    controllers.length)
                .clamp(34.0, 56.0);

        return Shake(
          token: shakeToken,
          amplitude: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < controllers.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                SizedBox(
                  width: width,
                  height: width * 1.25,
                  child: _DigitBox(
                    key: keyBuilder?.call(i),
                    controller: controllers[i],
                    focusNode: focusNodes[i],
                    enabled: enabled,
                    hasError: hasError,
                    onChanged: (value) => onChanged(i, value),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// One box. Split out so it can watch its own focus and light up without
/// rebuilding the other five.
class _DigitBox extends StatefulWidget {
  const _DigitBox({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.hasError,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool hasError;
  final ValueChanged<String> onChanged;

  @override
  State<_DigitBox> createState() => _DigitBoxState();
}

class _DigitBoxState extends State<_DigitBox> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted) return;
    if (widget.focusNode.hasFocus != _focused) {
      setState(() => _focused = widget.focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filled = widget.controller.text.isNotEmpty;

    final borderColor = widget.hasError
        ? context.semantic.danger
        : _focused
        ? colors.primary
        : filled
        ? colors.outlineVariant
        : context.semantic.hairline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        // A filled box reads as done before you look at the digit in it, which
        // is what lets someone check their progress at a glance mid-entry.
        color: filled && !widget.hasError
            ? colors.primary.withValues(alpha: 0.06)
            : colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(
          color: borderColor,
          width: _focused || widget.hasError ? 1.8 : 1,
        ),
      ),
      // The border is drawn by the container above so it can animate, so the
      // field itself contributes nothing but the glyph.
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        enabled: widget.enabled,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        decoration: const InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}
