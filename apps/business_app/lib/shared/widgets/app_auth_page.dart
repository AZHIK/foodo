import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';
import 'app_responsive_layout.dart';

/// Centred auth-flow scaffold.
///
/// On **mobile** the content fills the viewport with safe-area padding.
/// On **tablet / desktop** it is centred in a card of max-width
/// [AppDimensions.breakpointTablet] * 0.75 (~440 dp).
///
/// Usage:
/// ```dart
/// AppAuthPage(
///   title: 'Sign in',
///   child: Column(children: [...]),
/// )
/// ```
class AppAuthPage extends StatelessWidget {
  const AppAuthPage({
    super.key,
    this.title,
    this.leading,
    this.actions,
    required this.child,
    this.scrollable = true,
  });

  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget child;

  /// If `true` the content area is wrapped in a [SingleChildScrollView].
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: (title != null || leading != null || actions != null)
          ? AppBar(
              title: title != null ? Text(title!) : null,
              leading: leading,
              actions: actions,
              backgroundColor: Colors.transparent,
              elevation: 0,
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isNarrow = AppResponsiveLayout.isMobileWidth(w);

            final content = scrollable
                ? SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isNarrow
                          ? AppDimensions.spaceMD
                          : AppDimensions.spaceLG,
                      vertical: AppDimensions.spaceLG,
                    ),
                    child: child,
                  )
                : Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isNarrow
                          ? AppDimensions.spaceMD
                          : AppDimensions.spaceLG,
                      vertical: AppDimensions.spaceLG,
                    ),
                    child: child,
                  );

            if (isNarrow) return content;

            // Tablet / desktop: centre in a constrained card
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppResponsiveLayout.contentMaxWidthFor(w),
                ),
                child: Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceLG,
                    vertical: AppDimensions.spaceXL,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                    side: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.15),
                    ),
                  ),
                  child: content,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
