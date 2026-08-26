import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import 'step_bar.dart';

/// The panel beside the card on wide screens.
///
/// Built entirely from the colour scheme — the gradient is the same pair
/// [BrandMark] uses (`primary` → 55% of the way to `tertiary`), so the panel,
/// the logo tile and the nav rail all read as one brand rather than three
/// approximations of it. Nothing here is a fixed colour, which is what lets the
/// whole panel follow a reseeded theme and both brightnesses for free.
///
/// Only built at [Breakpoints.desktop] and above, so none of it costs layout on
/// a phone.
class AuthAside extends ConsumerWidget {
  const AuthAside({super.key, this.headline, this.supporting})
    : steps = null,
      current = 0;

  /// The wayfinding variant: the named step list, with completed steps ticked.
  /// Worth the space once a flow is more than two or three steps deep.
  const AuthAside.steps({
    super.key,
    required List<AuthStep> this.steps,
    required this.current,
  }) : headline = null,
       supporting = null;

  final String? headline;
  final String? supporting;
  final List<AuthStep>? steps;
  final int current;

  /// What the product does, in the till's own terms. Only shown on the brand
  /// variant — during onboarding the step list has more to say than a pitch.
  static const _features = <({IconData icon, String label})>[
    (icon: Icons.bolt_rounded, label: 'Take an order in three taps'),
    (icon: Icons.call_split_rounded, label: 'Split a bill without the maths'),
    (icon: Icons.nightlight_round, label: 'Cash up in under a minute'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isDark = context.theme.brightness == Brightness.dark;

    // M3 makes `primary` a *light* tint in a dark scheme, so painting the panel
    // with it would put the brightest surface on screen next to a near-black
    // card. The container pair is the same hue held at a dark tone, which keeps
    // the panel reading as the deep ground it is in both brightnesses.
    final ground = isDark ? colors.primaryContainer : colors.primary;
    final groundEnd = Color.lerp(
      ground,
      isDark ? colors.tertiaryContainer : colors.tertiary,
      .55,
    )!;
    final onBrand = isDark ? colors.onPrimaryContainer : colors.onPrimary;

    return ClipRRect(
      borderRadius: Radii.panel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ground, groundEnd],
          ),
        ),
        child: Stack(
          children: [
            // A soft bloom behind the lockup rather than a cropped glyph: an
            // icon large enough to read as texture gets sliced by the panel
            // edge and reads as a rendering fault instead.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.7, -0.9),
                    radius: 1.3,
                    colors: [
                      onBrand.withValues(alpha: 0.13),
                      onBrand.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Insets.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AsideBrand(onBrand: onBrand),
                  const SizedBox(height: Insets.xxl),
                  // Centred when the window is tall enough and scrollable when
                  // it is not — a short laptop window is the one case where a
                  // fixed panel would clip its own copy.
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: steps == null
                              ? _buildPitch(context, onBrand)
                              : _AsideSteps(
                                  steps: steps!,
                                  current: current,
                                  onBrand: onBrand,
                                ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    '© ${DateTime.now().year} ${ref.watch(storeNameProvider)}',
                    style: context.text.labelSmall?.copyWith(
                      color: onBrand.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPitch(BuildContext context, Color onBrand) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          headline ?? 'The till your\nfloor staff\nactually like.',
          style: context.text.displaySmall?.copyWith(
            color: onBrand,
            height: 1.12,
          ),
        ),
        const SizedBox(height: Insets.lg),
        Text(
          supporting ??
              'Orders, payments and takings in one place — on the counter, '
                  'on a tablet, or behind the bar.',
          style: context.text.bodyMedium?.copyWith(
            color: onBrand.withValues(alpha: 0.78),
          ),
        ),
        const SizedBox(height: Insets.xxl),
        for (final feature in _features) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: Insets.md),
            child: Row(
              children: [
                Icon(feature.icon, size: 18, color: onBrand),
                const SizedBox(width: Insets.md),
                Flexible(
                  child: Text(
                    feature.label,
                    style: context.text.bodyMedium?.copyWith(
                      color: onBrand.withValues(alpha: 0.88),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// The logo and venue name as they read on a saturated ground.
///
/// Not [BrandLockup]: that one is tuned for a surface background — its gradient
/// tile would sit on a gradient, and its `onSurface` text would all but
/// disappear here.
class _AsideBrand extends ConsumerWidget {
  const _AsideBrand({required this.onBrand});

  final Color onBrand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logo = ref.watch(
      businessProfileProvider.select((profile) => profile.logoBytes),
    );
    const size = 44.0;

    return Row(
      children: [
        Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            color: onBrand.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(size * 0.35),
          ),
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          child: logo == null
              ? Icon(
                  Icons.restaurant_rounded,
                  size: size * 0.55,
                  color: onBrand,
                )
              : Image.memory(
                  logo,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                ),
        ),
        const SizedBox(width: Insets.md),
        Expanded(
          child: Text(
            ref.watch(storeNameProvider),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.titleMedium?.copyWith(color: onBrand),
          ),
        ),
      ],
    );
  }
}

/// The named step list. Completed steps tick, the current one fills.
class _AsideSteps extends StatelessWidget {
  const _AsideSteps({
    required this.steps,
    required this.current,
    required this.onBrand,
  });

  final List<AuthStep> steps;
  final int current;
  final Color onBrand;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < steps.length; i++)
          _AsideStepTile(
            step: steps[i],
            index: i,
            state: i < current
                ? _StepState.done
                : i == current
                ? _StepState.active
                : _StepState.todo,
            isLast: i == steps.length - 1,
            onBrand: onBrand,
          ),
      ],
    );
  }
}

enum _StepState { done, active, todo }

class _AsideStepTile extends StatelessWidget {
  const _AsideStepTile({
    required this.step,
    required this.index,
    required this.state,
    required this.isLast,
    required this.onBrand,
  });

  final AuthStep step;
  final int index;
  final _StepState state;
  final bool isLast;
  final Color onBrand;

  @override
  Widget build(BuildContext context) {
    final active = state == _StepState.active;
    final done = state == _StepState.done;
    // Three tiers of prominence rather than two: a finished step should recede
    // without vanishing, or the list stops showing how far you have come.
    final alpha = active
        ? 1.0
        : done
        ? 0.72
        : 0.42;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOut,
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active || done
                      ? onBrand.withValues(alpha: done ? 0.22 : 1)
                      : Colors.transparent,
                  border: Border.all(
                    color: onBrand.withValues(alpha: active || done ? 0 : 0.4),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: done
                    ? Icon(Icons.check_rounded, size: 16, color: onBrand)
                    : Text(
                        '${index + 1}',
                        style: context.text.labelMedium?.copyWith(
                          color: active
                              ? context.colors.primary
                              : onBrand.withValues(alpha: alpha),
                        ),
                      ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    margin: const EdgeInsets.symmetric(vertical: Insets.xs),
                    color: onBrand.withValues(alpha: done ? 0.35 : 0.18),
                  ),
                ),
            ],
          ),
          const SizedBox(width: Insets.lg),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : Insets.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: Insets.xs),
                  Text(
                    step.label,
                    style: context.text.titleSmall?.copyWith(
                      color: onBrand.withValues(alpha: alpha),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.blurb,
                    style: context.text.bodySmall?.copyWith(
                      color: onBrand.withValues(alpha: alpha * 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
