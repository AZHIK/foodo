import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';

/// A form control with its label above it rather than floating inside it.
///
/// An external label survives a narrow column: two fields sharing 290px would
/// clip "Low stock alert" as an [InputDecoration.labelText], where a label on
/// its own line simply ellipsises. It also keeps the label readable while the
/// field holds a value, which a floating label does not.
class LabeledFormField extends StatelessWidget {
  const LabeledFormField({
    super.key,
    required this.label,
    required this.child,
    this.helper,
    this.isRequired = false,
    this.enabled = true,
  });

  final String label;

  /// The control itself — usually a [TextFormField], but a dropdown or a
  /// read-only box just as often.
  final Widget child;

  /// Guidance below the control. Validation errors come from the field's own
  /// validator and appear below this.
  final String? helper;

  /// Marks the label with an asterisk. Purely a signpost — the field's
  /// validator is what actually enforces it.
  final bool isRequired;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final labelColor = enabled
        ? colors.onSurface
        : colors.onSurface.withValues(alpha: 0.45);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: label),
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: context.semantic.danger),
                ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.labelLarge?.copyWith(color: labelColor),
        ),
        const SizedBox(height: Insets.xs + 2),
        child,
        if (helper != null) ...[
          const SizedBox(height: Insets.xs),
          Text(
            helper!,
            style: context.text.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
