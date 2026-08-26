import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/session.dart';
import '../../providers/roles_provider.dart';
import '../../providers/session_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/pin_keypad.dart';
import '../../widgets/staff/role_badge.dart';

abstract final class PinUnlockKeys {
  static const dots = Key('pinUnlock.dots');
  static const error = Key('pinUnlock.error');
  static const lockout = Key('pinUnlock.lockout');
  static const otpFallback = Key('pinUnlock.otpFallback');
  static const switchProfile = Key('pinUnlock.switchProfile');
}

/// The lock screen a returning cashier meets at the start of a shift.
///
/// The counting and the lockout live in [SessionNotifier], not here — this
/// screen shows what the session decided. That split is what stops a second
/// entry point (a deep link, a future biometric path) from being able to skip
/// the attempt limit.
class PinUnlockScreen extends ConsumerStatefulWidget {
  const PinUnlockScreen({super.key});

  @override
  ConsumerState<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends ConsumerState<PinUnlockScreen> {
  static const _pinLength = 6;

  String _entered = '';
  bool _error = false;
  bool _success = false;
  int _shakeToken = 0;

  /// Ticks once a second only while a lockout is running, so the countdown is
  /// visibly counting rather than jumping when something else rebuilds.
  Timer? _ticker;

  /// Seconds still to wait, counted down by [_ticker].
  ///
  /// Held here rather than recomputed from `DateTime.now()` on every rebuild.
  /// The session's `lockedUntil` stays the authority on *whether* the terminal
  /// is locked — it has to be, or backgrounding the app would pause the
  /// penalty — but the number on screen is driven by the ticker that is
  /// already firing, which is the thing actually producing the frames.
  int _secondsLeft = 0;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _ensureTicker(bool lockedOut) {
    if (lockedOut && _ticker == null) {
      // Synced from the wall clock once, on the way in: arriving at a lockout
      // that started ten seconds ago has to show twenty, not thirty.
      _secondsLeft = ref
          .read(sessionProvider)
          .lockoutSecondsLeft(DateTime.now());

      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;

        if (_secondsLeft <= 1) {
          _ticker?.cancel();
          _ticker = null;
          // Released here rather than on the next key press, so the keypad
          // comes back on its own while the person is watching.
          ref.read(sessionProvider.notifier).clearLockout();
          setState(() {
            _secondsLeft = 0;
            _error = false;
          });
          return;
        }

        setState(() => _secondsLeft--);
      });
    } else if (!lockedOut && _ticker != null) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _onDigit(String digit) {
    if (_success || _entered.length >= _pinLength) return;
    setState(() {
      _error = false;
      _entered += digit;
    });
    if (_entered.length == _pinLength) _submit();
  }

  void _onBackspace() {
    if (_success || _entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  void _submit() {
    final ok = ref.read(sessionProvider.notifier).submitPin(_entered);

    if (ok) {
      setState(() => _success = true);
      Future<void>.delayed(const Duration(milliseconds: 420), () {
        if (!mounted) return;
        context.go(ref.read(sessionProvider).entryRoute);
      });
      return;
    }

    setState(() {
      _error = true;
      _shakeToken++;
      _entered = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final staff = ref.watch(sessionStaffProvider);
    final role = staff == null
        ? null
        : ref.watch(roleByIdProvider(staff.roleId));

    final lockedOut = session.isLockedOutAt(DateTime.now());
    // Started from build rather than initState: the lockout can begin while
    // this screen is already on screen, which is the usual way it happens.
    _ensureTicker(lockedOut);

    return AuthScaffold(
      showBrand: false,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuthLink(
            key: PinUnlockKeys.otpFallback,
            label: 'Sign in with OTP instead',
            icon: Icons.sms_outlined,
            // Available during a lockout on purpose: someone who has genuinely
            // forgotten their PIN should not be stuck watching a timer with no
            // way through.
            onPressed: () => context.goNamed(AppRoute.loginName),
          ),
          if (session.hasSavedProfiles)
            AuthLink(
              key: PinUnlockKeys.switchProfile,
              label: 'Switch profile',
              onPressed: () => context.goNamed(AppRoute.profilesName),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (staff != null) ...[
            Center(
              child: StaffAvatar(
                initials: staff.initials,
                role: role,
                size: 64,
              ),
            ),
            const SizedBox(height: Insets.md),
            Text(
              staff.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleMedium,
            ),
            const SizedBox(height: Insets.sm),
            Center(child: RoleBadge(role: role, dense: true)),
            const SizedBox(height: Insets.xl),
          ],
          if (lockedOut)
            _LockedOut(secondsLeft: _secondsLeft)
          else
            _Entry(
              entered: _entered.length,
              length: _pinLength,
              error: _error,
              success: _success,
              shakeToken: _shakeToken,
              attemptsLeft:
                  SessionState.maxAttempts - session.failedAttempts,
              onDigit: _onDigit,
              onBackspace: _onBackspace,
            ),
        ],
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.entered,
    required this.length,
    required this.error,
    required this.success,
    required this.shakeToken,
    required this.attemptsLeft,
    required this.onDigit,
    required this.onBackspace,
  });

  final int entered;
  final int length;
  final bool error;
  final bool success;
  final int shakeToken;
  final int attemptsLeft;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PinDots(
          key: PinUnlockKeys.dots,
          length: length,
          filled: entered,
          error: error,
          success: success,
          shakeToken: shakeToken,
        ),
        const SizedBox(height: Insets.md),
        SizedBox(
          height: 34,
          child: Center(
            child: success
                ? Icon(
                    Icons.check_circle_rounded,
                    color: context.semantic.success,
                    size: 22,
                  )
                : !error
                ? Text(
                    'Enter your $length-digit PIN',
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  )
                : Text(
                    // The remaining count only appears once one has been used,
                    // so a first slip is a nudge rather than a warning.
                    attemptsLeft <= 1
                        ? 'Incorrect PIN — last attempt'
                        : 'Incorrect PIN, try again '
                              '($attemptsLeft attempts left)',
                    key: PinUnlockKeys.error,
                    textAlign: TextAlign.center,
                    style: context.text.bodySmall?.copyWith(
                      color: context.semantic.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: Insets.sm),
        PinKeypad(
          enabled: !success,
          onDigit: onDigit,
          onBackspace: onBackspace,
        ),
      ],
    );
  }
}

/// What the card becomes after three wrong PINs.
///
/// The keypad is gone rather than disabled: a greyed-out pad invites more
/// tapping, where an absent one makes it obvious that waiting is the only
/// thing left to do — bar the OTP link, which stays in the footer throughout.
class _LockedOut extends StatelessWidget {
  const _LockedOut({required this.secondsLeft});

  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    final danger = context.semantic.danger;

    return Column(
      key: PinUnlockKeys.lockout,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: context.semantic.dangerContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_outline_rounded, size: 26, color: danger),
          ),
        ),
        const SizedBox(height: Insets.lg),
        Text(
          'Too many attempts',
          textAlign: TextAlign.center,
          style: context.text.titleMedium,
        ),
        const SizedBox(height: Insets.xs),
        Text(
          'For everyone\'s safety the till is locked for a moment.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Insets.xl),
        Center(
          child: Text(
            '$secondsLeft',
            style: context.text.displaySmall?.copyWith(
              color: danger,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        Text(
          secondsLeft == 1 ? 'second remaining' : 'seconds remaining',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Insets.lg),
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.pill),
          child: LinearProgressIndicator(
            value: secondsLeft / SessionState.lockoutDuration.inSeconds,
            minHeight: 4,
            backgroundColor: danger.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(danger),
          ),
        ),
      ],
    );
  }
}
