import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/nav_shell_scope.dart';

/// Stands in for the modules the rail advertises but this build does not
/// implement (Reports, Inventory, Settings).
///
/// They exist as real shell branches rather than dead icons so the navigation
/// is honest and each one keeps its own Navigator — dropping a real screen in
/// later is a one-line change in the router.
class ModulePlaceholderScreen extends StatelessWidget {
  const ModulePlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.blurb,
  });

  final String title;
  final IconData icon;
  final String blurb;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.lg,
                Insets.md,
                Insets.lg,
                0,
              ),
              child: Row(
                children: [
                  const NavMenuButton(),
                  Text(title, style: context.text.headlineSmall),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Padding(
                    padding: const EdgeInsets.all(Insets.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 72,
                          width: 72,
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(Radii.lg),
                          ),
                          child: Icon(
                            icon,
                            size: 32,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: Insets.lg),
                        Text(
                          '$title module',
                          style: context.text.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: Insets.sm),
                        Text(
                          blurb,
                          textAlign: TextAlign.center,
                          style: context.text.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
