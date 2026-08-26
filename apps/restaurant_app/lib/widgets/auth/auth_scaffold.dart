import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../brand_mark.dart';
import 'auth_aside.dart';

/// The chrome every auth screen shares.
///
/// Two layouts, one widget:
///
/// * Below [Breakpoints.desktop] — a softly tinted full-bleed background with a
///   centered card, top-anchored on a phone so the keyboard has somewhere to go.
/// * At [Breakpoints.desktop] and above — a brand panel beside the card. A
///   400px card alone on a 1440px display is a form that got lost on the way to
///   a screen; the panel gives the width something to do and says whose till
///   this is while someone is signing in to it.
///
/// One widget rather than five near-identical layouts, because the whole point
/// of the sequence — splash, login, PIN, onboarding — is that it reads as one
/// continuous flow. Anything a single screen needs to vary is a parameter; the
/// background, the card shape and the logo treatment are not among them.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.maxWidth = cardWidth,
    this.footer,
    this.showBrand = true,
    this.scrollable = true,
    this.aside,
    this.showAside = true,
  });

  /// The card's body — the form, keypad or step this screen is about.
  final Widget child;

  /// Heading inside the card, above [child].
  final String? title;

  /// One line under the heading explaining what is being asked and why.
  final String? subtitle;

  /// Card width on tablet and desktop. Onboarding wants considerably more than
  /// a login form does.
  final double maxWidth;

  /// Sits below the card, outside it — "Not your device?", "Change number".
  /// Outside because these are ways *out* of the card's task, and putting them
  /// inside makes them read as part of it.
  final Widget? footer;

  final bool showBrand;

  /// False for a screen that manages its own scrolling — a grid of profiles
  /// scrolls itself rather than riding inside this one.
  final bool scrollable;

  /// What fills the left panel on wide screens. Defaults to the brand pitch;
  /// onboarding passes [AuthAside.steps] instead.
  final Widget? aside;

  /// False for a screen that wants the full width to itself at every size —
  /// the splash, which is already a brand moment and does not need a second one
  /// beside it.
  final bool showAside;

  /// Comfortable for a single column of fields, and the same width at every
  /// breakpoint: a sign-in card has no more to say on a 1920px monitor than on
  /// a phone, and stretching it would only make it harder to read across.
  static const double cardWidth = 400;

  /// The brand panel never grows past this, however wide the display. Past it
  /// the panel starts competing with the form for attention instead of framing
  /// it.
  static const double _asideMaxWidth = 560;

  @override
  Widget build(BuildContext context) {
    final form = context.formFactor;

    final card = Container(
      padding: EdgeInsets.all(form.isMobile ? Insets.xl : Insets.xxl - 4),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: Radii.panel,
        border: Border.all(color: context.semantic.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.theme.brightness == Brightness.dark ? 0.32 : 0.06,
            ),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBrand) ...[
            const Center(child: BrandMark(size: 52)),
            const SizedBox(height: Insets.xl),
          ],
          if (title case final text?) ...[
            Text(
              text,
              textAlign: TextAlign.center,
              style: context.text.headlineSmall,
            ),
            const SizedBox(height: Insets.xs),
          ],
          if (subtitle case final text?) ...[
            Text(
              text,
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Insets.xl),
          ] else if (title != null)
            const SizedBox(height: Insets.lg),
          child,
        ],
      ),
    );

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        if (footer case final widget?) ...[
          const SizedBox(height: Insets.xl),
          widget,
        ],
      ],
    );

    final content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: column,
      ),
    );

    // The card pane, identical at every width — the split adds a panel beside
    // this, it does not reflow what is inside it.
    Widget pane(BoxConstraints constraints) => scrollable
        ? SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: Insets.page(form),
              // Top-anchored with breathing room on a phone, where vertical
              // centering fights the keyboard; centered on anything with room
              // to spare.
              vertical: form.isMobile ? Insets.xxl : Insets.xl,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: form.isMobile
                    ? 0
                    : constraints.maxHeight - Insets.xl * 2,
              ),
              child: content,
            ),
          )
        : Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Insets.page(form),
              vertical: Insets.lg,
            ),
            child: content,
          );

    return Scaffold(
      backgroundColor: Colors.transparent,
      // The card is what moves when the keyboard comes up, and it moves by
      // scrolling rather than by being squeezed — a resized card reflows its
      // whole layout under the user's thumb.
      resizeToAvoidBottomInset: true,
      body: AuthBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Keyed off the width this actually received rather than the
              // window's, so the panel appears when there is room for it.
              final split =
                  showAside && constraints.maxWidth >= Breakpoints.desktop;

              if (!split) return pane(constraints);

              return Padding(
                padding: const EdgeInsets.all(Insets.lg),
                child: Row(
                  // Stretch rather than centre: the panel is a full-height
                  // ground, not a card floating beside the form.
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      // 5:11 rather than an even split — the form is the
                      // errand, the panel is the frame around it — and capped
                      // so it stops growing on an ultrawide.
                      width: math.min(
                        constraints.maxWidth * (5 / 11),
                        _asideMaxWidth,
                      ),
                      child: aside ?? const AuthAside(),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, paneConstraints) =>
                            pane(paneConstraints),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The tinted wash every auth screen sits on.
///
/// A soft radial bloom of the seed colour rather than a solid block: the same
/// restraint the Dashboard's tinted cards use, so arriving at the app does not
/// feel like leaving the brand behind.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dark = context.theme.brightness == Brightness.dark;

    return Container(
      // Expanded rather than sized to the child: on a phone the card is short
      // and the scroll view shrink-wraps it, which left the wash covering only
      // the top of the screen and bare white below it.
      constraints: const BoxConstraints.expand(),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.75),
          radius: 1.1,
          colors: [
            Color.lerp(
              context.theme.scaffoldBackgroundColor,
              colors.primary,
              dark ? 0.16 : 0.10,
            )!,
            context.theme.scaffoldBackgroundColor,
          ],
        ),
      ),
      child: child,
    );
  }
}

/// A quiet text link — the way out of an auth card without competing with the
/// primary action inside it.
class AuthLink extends StatelessWidget {
  const AuthLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: context.colors.onSurfaceVariant,
      ),
      child: icon == null
          ? child
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16),
                const SizedBox(width: Insets.sm),
                Flexible(child: child),
              ],
            ),
    );
  }
}
