import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_text_styles.dart';

/// Styled text form field that wraps [TextFormField] with the app's
/// design system tokens.
///
/// Requires no manual `InputDecoration` — all styling comes from
/// [AppTheme] via the inherited [InputDecorationTheme]. Only field-specific
/// attributes (label, hint, icon, etc.) are passed in.
///
/// Usage:
/// ```dart
/// AppTextField(
///   controller: _nameController,
///   label: 'Full name',
///   prefixIcon: Icons.person_outline,
///   validator: (v) => v!.isEmpty ? 'Required' : null,
/// )
/// ```
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixWidget,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.inputFormatters,
    this.counterText,
    this.errorText,
    this.helperText,
    this.autofillHints,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? suffixWidget;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;
  final String? counterText;
  final String? errorText;
  final String? helperText;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLength: maxLength,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      validator: validator,
      style: AppTextStyles.bodyLarge.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon:
            suffixWidget ?? (suffixIcon != null ? Icon(suffixIcon) : null),
        counterText: counterText,
        errorText: errorText,
        helperText: helperText,
      ),
    );
  }
}

/// A read-only display field useful for showing non-editable values.
class AppReadOnlyField extends StatelessWidget {
  const AppReadOnlyField({
    super.key,
    required this.label,
    required this.value,
    this.prefixIcon,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? prefixIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppTextField(
      label: label,
      controller: TextEditingController(text: value),
      prefixIcon: prefixIcon,
      readOnly: true,
      onTap: onTap,
      suffixWidget: onTap != null
          ? Icon(
              Icons.chevron_right,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            )
          : null,
    );
  }
}
