import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';

/// One stage of a multi-step flow.
///
/// Shared by the compact [StepBar] the card carries and the named list the
/// wide-screen aside shows, so a step cannot be renamed in one and not in the
/// other.
@immutable
class AuthStep {
  const AuthStep({
    required this.label,
    required this.blurb,
    required this.icon,
  });

  /// Two or three words. This is a waypoint, not a heading.
  final String label;

  /// One short line under the label in the aside. Never shown in [StepBar],
  /// which has no room for it.
  final String blurb;

  final IconData icon;
}

/// A thin segmented progress bar.
///
/// Shown inside the card at every width: on a phone it is the only progress
/// indicator there is, and on a desktop it echoes the aside's list so there is
/// something near the form confirming where you are.
class StepBar extends StatelessWidget {
  const StepBar({super.key, required this.step, required this.count});

  final int step;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: Insets.sm),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              height: 4,
              decoration: BoxDecoration(
                color: i <= step
                    ? colors.primary
                    : colors.primary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
            ),
          ),
        ],
        const SizedBox(width: Insets.md),
        Text(
          '${step + 1} of $count',
          style: context.text.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
