import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/phone_validation.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/otp_input.dart';
import '../../widgets/labeled_form_field.dart';

abstract final class OtpLoginKeys {
  static const phone = Key('otpLogin.phone');
  static const sendCode = Key('otpLogin.sendCode');
  static const resend = Key('otpLogin.resend');
  static const changeNumber = Key('otpLogin.changeNumber');

  static Key digit(int index) => Key('otpLogin.digit.$index');
}

/// Sign in by phone number and a six-digit code sent by SMS.
class OtpLoginScreen extends ConsumerStatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  ConsumerState<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends ConsumerState<OtpLoginScreen> {
  static const _codeLength = 6;
  static const _resendCooldown = Duration(seconds: 30);
  static const _verifyDelay = Duration(milliseconds: 800);

  final _phone = TextEditingController();
  final _phoneFocus = FocusNode();

  /// One controller and one focus node per box. Six separate fields rather
  /// than one masked field because that is what makes each digit individually
  /// correctable — the thing people actually do when they mistype a code.
  late final List<TextEditingController> _digits = List.generate(
    _codeLength,
    (_) => TextEditingController(),
  );
  late final List<FocusNode> _digitFocus = List.generate(
    _codeLength,
    (_) => FocusNode(),
  );

  bool _codeSent = false;
  bool _verifying = false;
  String? _phoneError;
  String? _codeError;
  int _shakeToken = 0;

  Timer? _cooldown;
  int _secondsLeft = 0;

  @override
  void dispose() {
    _cooldown?.cancel();
    _phone.dispose();
    _phoneFocus.dispose();
    for (final controller in _digits) {
      controller.dispose();
    }
    for (final node in _digitFocus) {
      node.dispose();
    }
    super.dispose();
  }

  String get _code => _digits.map((c) => c.text).join();

  // -------------------------------------------------------------------------
  // Phone step
  // -------------------------------------------------------------------------

  Future<void> _sendCode() async {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      setState(() => _phoneError = 'Enter your phone number');
      return;
    }
    if (!isValidTanzanianPhone(digits)) {
      setState(() => _phoneError = tanzanianPhoneHint);
      return;
    }

    try {
      // Request OTP from the auth provider.
      await ref.read(sessionProvider.notifier).requestOtp('+255$digits');
    } catch (e) {
      if (!mounted) return;
      setState(() => _phoneError = 'Failed to send code: $e');
      return;
    }

    setState(() {
      _phoneError = null;
      _codeSent = true;
    });
    _startCooldown();
    // The first box takes focus so the code can be typed without a tap.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _digitFocus.first.requestFocus();
    });
  }

  void _startCooldown() {
    _cooldown?.cancel();
    setState(() => _secondsLeft = _resendCooldown.inSeconds);

    _cooldown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  void _changeNumber() {
    _cooldown?.cancel();
    setState(() {
      _codeSent = false;
      _codeError = null;
      _secondsLeft = 0;
      for (final controller in _digits) {
        controller.clear();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _phoneFocus.requestFocus();
    });
  }

  // -------------------------------------------------------------------------
  // Code step
  // -------------------------------------------------------------------------

  void _onDigitChanged(int index, String value) {
    // A paste lands the whole code in one box; spread it across the row rather
    // than truncating it to one character.
    if (value.length > 1) {
      final pasted = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < _codeLength; i++) {
        _digits[i].text = i < pasted.length ? pasted[i] : '';
      }
      _digitFocus[(pasted.length - 1).clamp(0, _codeLength - 1)]
          .requestFocus();
    } else if (value.isNotEmpty && index < _codeLength - 1) {
      _digitFocus[index + 1].requestFocus();
    }

    // Clearing a box steps focus back to the one before it, which is what
    // deleting a mistyped digit is actually trying to do.
    if (value.isEmpty && index > 0) _digitFocus[index - 1].requestFocus();

    if (_codeError != null) setState(() => _codeError = null);
    if (_code.length == _codeLength) _verify();
  }


  Future<void> _verify() async {
    final entered = _code;
    setState(() => _verifying = true);
    FocusScope.of(context).unfocus();

    await Future<void>.delayed(_verifyDelay);
    if (!mounted) return;

    try {
      // Verify OTP code via the auth provider.
      await ref.read(sessionProvider.notifier).completeOtpLogin(entered);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _codeError = 'That code is not right. Check your messages.';
        _shakeToken++;
        for (final controller in _digits) {
          controller.clear();
        }
      });
      _digitFocus.first.requestFocus();
      return;
    }

    if (!mounted) return;
    // A brand-new (phone-first, OTP-only) account has no name on file yet —
    // collect it before anything else. Otherwise where this lands — Set PIN
    // for a first-time device, Dashboard for a returning one — is the
    // guard's decision, read off the session it just wrote to.
    if (ref.read(authProvider).needsProfile) {
      context.go(AppRoute.completeProfilePath);
      return;
    }
    context.go(ref.read(sessionProvider).entryRoute);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: _codeSent ? 'Enter your code' : 'Sign in',
      subtitle: _codeSent
          ? 'We sent a 6-digit code to ${_formattedPhone()}'
          : 'Use the phone number your manager registered',
      footer: _codeSent
          ? null
          : AuthLink(
              label: 'Back to profiles',
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.goNamed(AppRoute.profilesName),
            ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: _codeSent ? _buildCodeStep(context) : _buildPhoneStep(context),
      ),
    );
  }

  String _formattedPhone() {
    final text = _phone.text.trim();
    return text.isEmpty ? 'your phone' : '+255 $text';
  }

  Widget _buildPhoneStep(BuildContext context) {
    return Column(
      key: const ValueKey('phone'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LabeledFormField(
          label: 'Phone number',
          isRequired: true,
          child: TextField(
            key: OtpLoginKeys.phone,
            controller: _phone,
            focusNode: _phoneFocus,
            autofocus: true,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ],
            onChanged: (value) {
              final digits = value.replaceAll(RegExp(r'\D'), '');
              if (digits.isEmpty) {
                setState(() => _phoneError = null);
              } else if (!isValidTanzanianPhone(digits)) {
                setState(() => _phoneError = tanzanianPhoneHint);
              } else {
                setState(() => _phoneError = null);
              }
            },
            onSubmitted: (_) => _sendCode(),
            decoration: InputDecoration(
              hintText: '6XXXXXXXX or 7XXXXXXXX',
              errorText: _phoneError,
              // A fixed dial code rather than a country picker: this build
              // serves one market, and a picker with one entry is a control
              // that only costs a tap.
              prefixIcon: Padding(
                padding: const EdgeInsets.only(
                  left: Insets.lg,
                  right: Insets.sm,
                ),
                child: Text(
                  '+255',
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0),
            ),
          ),
        ),
        const SizedBox(height: Insets.xl),
        FilledButton(
          key: OtpLoginKeys.sendCode,
          onPressed: _sendCode,
          child: const Text('Send code'),
        ),
      ],
    );
  }

  Widget _buildCodeStep(BuildContext context) {
    return Column(
      key: const ValueKey('code'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        OtpInput(
          controllers: _digits,
          focusNodes: _digitFocus,
          hasError: _codeError != null,
          enabled: !_verifying,
          shakeToken: _shakeToken,
          onChanged: _onDigitChanged,
          keyBuilder: OtpLoginKeys.digit,
        ),
        const SizedBox(height: Insets.md),
        // The error takes the hint's place rather than appearing under it —
        // two lines of small print where one was is how a layout jumps.
        _CodeHint(error: _codeError),
        const SizedBox(height: Insets.lg),
        SizedBox(
          height: 24,
          child: Center(
            child: _verifying
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 15,
                        width: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.colors.primary,
                        ),
                      ),
                      const SizedBox(width: Insets.md),
                      Text('Verifying', style: context.text.bodySmall),
                    ],
                  )
                : _secondsLeft > 0
                ? Text(
                    'Resend code in ${_secondsLeft}s',
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  )
                : TextButton(
                    key: OtpLoginKeys.resend,
                    onPressed: _startCooldown,
                    child: const Text('Resend code'),
                  ),
          ),
        ),
        const SizedBox(height: Insets.sm),
        AuthLink(
          key: OtpLoginKeys.changeNumber,
          label: 'Change number',
          onPressed: _verifying ? null : _changeNumber,
        ),
      ],
    );
  }
}

/// The demo code, or the reason the last one was refused.
///
/// One slot for both so the card does not grow a line when a code is rejected.
class _CodeHint extends StatelessWidget {
  const _CodeHint({required this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final rejected = error != null;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: rejected
          ? Text(
              error!,
              key: const ValueKey('error'),
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(
                color: context.semantic.danger,
              ),
            )
          : Row(
              key: const ValueKey('hint'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: context.colors.onSurfaceVariant,
                ),
                const SizedBox(width: Insets.sm - 2),
                Text(
                  'We texted you a 6-digit code',
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
    );
  }
}
