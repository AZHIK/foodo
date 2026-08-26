import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/session_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/pin_keypad.dart';

abstract final class SetPinKeys {
  static const dots = Key('setPin.dots');
  static const error = Key('setPin.error');

  static Key key(String digit) => Key('setPin.key.$digit');
}

/// Chooses the PIN that unlocks the till.
///
/// Six digits rather than four: a four-digit PIN has ten thousand
/// combinations, and this one guards the takings on a device that sits on a
/// counter all day. Six costs the cashier two extra taps and buys a hundredfold
/// larger space, which is the right trade here.
///
/// Two passes in one screen — enter, then confirm. A mismatch clears both and
/// says so, rather than silently keeping the first entry and leaving the person
/// wondering which of the two the terminal believed.
class SetPinScreen extends ConsumerStatefulWidget {
  const SetPinScreen({super.key, this.isChangingPin = false});

  /// True when this was reached from Account Settings rather than first-time
  /// setup. Changes the wording and where finishing sends you — the flow
  /// itself is identical, which is why it is one screen.
  final bool isChangingPin;

  @override
  ConsumerState<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends ConsumerState<SetPinScreen> {
  static const _pinLength = 6;

  String _first = '';
  String _confirm = '';
  bool _confirming = false;
  String? _error;
  int _shakeToken = 0;
  bool _saved = false;

  String get _current => _confirming ? _confirm : _first;

  void _onDigit(String digit) {
    if (_saved || _current.length >= _pinLength) return;

    setState(() {
      _error = null;
      if (_confirming) {
        _confirm += digit;
      } else {
        _first += digit;
      }
    });

    if (_current.length == _pinLength) _advance();
  }

  void _onBackspace() {
    if (_saved || _current.isEmpty) return;
    setState(() {
      if (_confirming) {
        _confirm = _confirm.substring(0, _confirm.length - 1);
      } else {
        _first = _first.substring(0, _first.length - 1);
      }
    });
  }

  void _advance() {
    if (!_confirming) {
      // A beat before the second pass, so the last dot is seen filling rather
      // than the screen appearing to change on its own.
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (mounted) setState(() => _confirming = true);
      });
      return;
    }

    if (_confirm != _first) {
      setState(() {
        _error = 'Those PINs did not match. Start again.';
        _shakeToken++;
        _first = '';
        _confirm = '';
        _confirming = false;
      });
      return;
    }

    setState(() => _saved = true);
    ref.read(sessionProvider.notifier).setPin(_first);

    Future<void>.delayed(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      // Changing a PIN returns you to where you asked from; setting the first
      // one hands back to the guard, which knows whether onboarding is next.
      context.go(
        widget.isChangingPin
            ? AppRoute.account()
            : ref.read(sessionProvider).entryRoute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: widget.isChangingPin
          ? 'Choose a new PIN'
          : _confirming
          ? 'Confirm your PIN'
          : 'Create your PIN',
      subtitle: _confirming
          ? 'Enter the same six digits again'
          : 'You\'ll use this to unlock the POS quickly',
      footer: widget.isChangingPin
          ? AuthLink(
              label: 'Cancel',
              onPressed: () => context.go(AppRoute.account()),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PinDots(
            key: SetPinKeys.dots,
            length: _pinLength,
            filled: _current.length,
            error: _error != null,
            success: _saved,
            shakeToken: _shakeToken,
          ),
          const SizedBox(height: Insets.md),
          // Reserved whether or not there is a message, so the keypad does not
          // jump up the screen the moment an error clears.
          SizedBox(
            height: 34,
            child: Center(
              child: _saved
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: context.semantic.success,
                        ),
                        const SizedBox(width: Insets.sm),
                        Text(
                          'PIN saved',
                          style: context.text.bodySmall?.copyWith(
                            color: context.semantic.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : _error == null
                  ? null
                  : Text(
                      _error!,
                      key: SetPinKeys.error,
                      textAlign: TextAlign.center,
                      style: context.text.bodySmall?.copyWith(
                        color: context.semantic.danger,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: Insets.sm),
          PinKeypad(
            enabled: !_saved,
            onDigit: _onDigit,
            onBackspace: _onBackspace,
          ),
        ],
      ),
    );
  }
}
