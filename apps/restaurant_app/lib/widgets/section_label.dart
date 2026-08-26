import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Uppercase, letter-spaced, muted — the structural signpost above a block of
/// content. Used by the order panel, the payment summary and the receipt, so
/// every section heading in the checkout flow reads the same.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.text.labelSmall?.copyWith(
        color: context.colors.onSurfaceVariant,
        letterSpacing: 0.9,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
