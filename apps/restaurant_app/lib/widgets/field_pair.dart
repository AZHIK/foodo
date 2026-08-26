import 'package:flutter/material.dart';

import '../theme/breakpoints.dart';

/// Two form controls side by side when there is room, stacked when there is
/// not.
///
/// Keyed to the width the pair actually received rather than the window's, so
/// it stacks correctly inside a 320px side panel on a 1920px screen. Extracted
/// from the Business Profile form once Store Settings needed the same
/// behaviour — city/postcode, tax rate/service charge and open/close times are
/// all the same layout problem.
class FieldPair extends StatelessWidget {
  const FieldPair({
    super.key,
    required this.left,
    required this.right,
    this.stackBelow = 380,
    this.spacing = Insets.md,
  });

  final Widget left;
  final Widget right;

  /// Below this each half would be narrower than a usable input.
  final double stackBelow;

  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < stackBelow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, SizedBox(height: Insets.lg), right],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            SizedBox(width: spacing),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}
