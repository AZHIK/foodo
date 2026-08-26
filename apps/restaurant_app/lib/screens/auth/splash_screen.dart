import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/session_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/brand_mark.dart';

/// The brand moment the app opens on.
///
/// It decides nothing itself: it plays for as long as it takes to read, then
/// tells the session it is done. The router's redirect reads that flag and
/// sends the user to exactly one of Profile Picker, OTP Login, PIN Unlock or
/// the Dashboard — so the "where do we go" rule lives in one place instead of
/// being re-derived by whichever widget happens to be mounted.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Long enough to register as deliberate, short enough that a cashier
  /// opening the till at 7am does not notice waiting.
  static const _brandMoment = Duration(milliseconds: 1200);

  /// An [AnimationController] rather than a [Timer], and not only because it
  /// drives the progress bar: a pending timer survives `pumpAndSettle` and
  /// fails the test that follows, where an animation is simply run to its end.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _brandMoment,
  )..addStatusListener((status) async {
    if (status == AnimationStatus.completed && mounted) {
      // Load saved profiles from database before completing bootstrap.
      // This ensures the profile picker is shown if users have previously signed in.
      await ref.read(sessionProvider.notifier).loadSavedProfiles();
      if (mounted) {
        ref.read(sessionProvider.notifier).completeBootstrap();
      }
    }
  });

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(storeNameProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuthBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Padding(
                padding: EdgeInsets.all(Insets.page(context.formFactor)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandMark(size: 72),
                    const SizedBox(height: Insets.xl),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.headlineSmall,
                    ),
                    const SizedBox(height: Insets.xs),
                    Text(
                      'Point of sale',
                      textAlign: TextAlign.center,
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: Insets.xxl),
                    _LoadingBar(progress: _controller),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A thin determinate bar that fills over the brand moment.
///
/// Determinate rather than a spinner on purpose: it says how long this will
/// take, and it ends rather than looping — a spinner on a screen that always
/// lasts the same 1.2 seconds is a lie about uncertainty.
class _LoadingBar extends StatelessWidget {
  const _LoadingBar({required this.progress});

  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.pill),
          child: SizedBox(
            height: 3,
            width: 132,
            child: AnimatedBuilder(
              animation: progress,
              builder: (context, _) => LinearProgressIndicator(
                // Eased so it moves off quickly and settles, rather than
                // crawling at a constant rate.
                value: Curves.easeInOutCubic.transform(progress.value),
                backgroundColor: colors.primary.withValues(alpha: 0.14),
                valueColor: AlwaysStoppedAnimation(colors.primary),
              ),
            ),
          ),
        ),
        const SizedBox(height: Insets.md),
        Text(
          'Preparing your terminal',
          style: context.text.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
