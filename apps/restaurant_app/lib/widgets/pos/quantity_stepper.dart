import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';

/// − [n] + control used on cart lines.
///
/// Sized off [compact] rather than a breakpoint so the narrowed tablet panel
/// and the roomy desktop one can both ask for what they have space for.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.compact = false,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final side = compact ? 26.0 : 30.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: quantity <= 1
                ? Icons.delete_outline_rounded
                : Icons.remove_rounded,
            onTap: onDecrement,
            side: side,
            // Reaching zero deletes the line, so say so before it happens.
            tooltip: quantity <= 1 ? 'Remove' : 'Decrease',
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: compact ? 20 : 26),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: (compact ? context.text.labelLarge : context.text.titleSmall)
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: onIncrement,
            side: side,
            tooltip: 'Increase',
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.side,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double side;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: side,
          width: side,
          child: Icon(icon, size: side * 0.55, color: context.colors.onSurface),
        ),
      ),
    );
  }
}
