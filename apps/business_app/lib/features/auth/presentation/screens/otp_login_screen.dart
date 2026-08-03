import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/sync/connectivity_service.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../../shared/widgets/widgets.dart';

/// OTP login screen — phone entry → verification code.
class OtpLoginScreen extends ConsumerStatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  ConsumerState<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends ConsumerState<OtpLoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _phoneFocus = FocusNode();
  final _codeFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();

  bool _codeSent = false;
  bool _verifying = false;
  int _resendCountdown = 0;
  String? _error;
  String? _pendingPhone;

  late final AnimationController _stepCtrl;
  late final Animation<double> _stepFade;

  @override
  void initState() {
    super.initState();
    _stepCtrl = AnimationController(vsync: this, duration: AppDurations.normal);
    _stepFade = CurvedAnimation(parent: _stepCtrl, curve: Curves.easeInOut);
    _stepCtrl.forward();

    final state = ref.read(authProvider);
    state.maybeWhen(
      otpPending: (phone) {
        _codeSent = true;
        _pendingPhone = phone;
        _phoneCtrl.text = phone;
        _startResendCountdown();
      },
      orElse: () {},
    );
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _phoneFocus.dispose();
    _codeFocus.dispose();
    _stepCtrl.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() => _resendCountdown = 60);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCountdown--);
      return _resendCountdown > 0;
    });
  }

  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final phone = _phoneCtrl.text.trim();

    final failure = await ref.read(authProvider.notifier).requestOtp(phone);
    if (!mounted) return;

    if (failure != null) {
      setState(() => _error = _mapFailure(failure));
    } else {
      _pendingPhone = phone;
      await _stepCtrl.reverse();
      setState(() {
        _codeSent = true;
        _resendCountdown = 60;
      });
      _startResendCountdown();
      _stepCtrl.forward();
      _codeFocus.requestFocus();
    }
  }

  Future<void> _verifyOtp() async {
    if (_verifying || _codeCtrl.text.length != 6) return;
    setState(() {
      _verifying = true;
      _error = null;
    });
    final phone = _pendingPhone ?? _phoneCtrl.text.trim();
    final failure = await ref
        .read(authProvider.notifier)
        .verifyOtp(phone, _codeCtrl.text.trim());
    if (!mounted) return;

    if (failure != null) {
      setState(() {
        _verifying = false;
        _error = _mapFailure(failure);
      });
      _codeCtrl.clear();
    } else {
      setState(() => _verifying = true);
      context.go(AppRoutes.setPin);
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0 || _pendingPhone == null) return;
    setState(() => _error = null);
    final failure = await ref.read(authProvider.notifier).requestOtp(_pendingPhone!);
    if (!mounted) return;
    if (failure != null) {
      setState(() => _error = _mapFailure(failure));
    } else {
      setState(() => _resendCountdown = 60);
      _startResendCountdown();
    }
  }

  String _mapFailure(Failure f) => f.when(
        network: (msg, _) => msg ?? AppStrings.networkError,
        validation: (msg) => msg ?? AppStrings.unknownError,
        auth: (msg) => msg ?? AppStrings.authError,
        unknown: (msg, _) => msg ?? AppStrings.unknownError,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isOffline = ref.watch(connectivityProvider).value == false;

    return AppAuthPage(
      leading: _codeSent
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                await _stepCtrl.reverse();
                setState(() {
                  _codeSent = false;
                  _codeCtrl.clear();
                  _pendingPhone = null;
                  _resendCountdown = 0;
                  _error = null;
                });
                _stepCtrl.forward();
              },
            )
          : null,
      child: Form(
        key: _formKey,
        child: FadeTransition(
          opacity: _stepFade,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Offline banner ──────────────────────────────────
              if (isOffline) ...[
                const AppOfflineBanner(),
                const SizedBox(height: AppDimensions.spaceLG),
              ],

              // ── Hero icon ───────────────────────────────────────
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.seedTerracotta, AppColors.seedSage],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  ),
                  child: Icon(
                    _codeSent ? Icons.lock_open_outlined : Icons.phone_android_outlined,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spaceLG),

              // ── Title / subtitle ────────────────────────────────
              Text(
                _codeSent
                    ? '${AppStrings.loginOtpSent} $_pendingPhone'
                    : AppStrings.loginTitle,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppDimensions.spaceSM),

              Text(
                _codeSent
                    ? AppStrings.loginOtpHint
                    : 'Enter your phone number to receive a verification code',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // ── Phone entry step ────────────────────────────────
              if (!_codeSent) ...[
                AppTextField(
                  controller: _phoneCtrl,
                  focusNode: _phoneFocus,
                  label: 'Phone number',
                  hint: '+254 7XX XXX XXX',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _requestOtp(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Phone number is required';
                    if (!RegExp(r'^\+?[\d\s]{10,15}$').hasMatch(v.trim())) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),

                if (_error != null) ...[
                  const SizedBox(height: AppDimensions.spaceMD),
                  AppInfoContainer(
                    icon: Icons.error_outline,
                    color: colorScheme.errorContainer,
                    child: Text(
                      _error!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppDimensions.spaceLG),

                AppPrimaryButton(
                  label: 'Send Code',
                  icon: Icons.send_outlined,
                  onPressed: _requestOtp,
                ),
              ]

              // ── OTP entry step ──────────────────────────────────
              else ...[
                AppTextField(
                  controller: _codeCtrl,
                  focusNode: _codeFocus,
                  label: 'Verification code',
                  hint: '000000',
                  prefixIcon: Icons.lock_outline,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  counterText: '',
                  autofocus: true,
                  onChanged: (v) {
                    if (v.length == 6) _verifyOtp();
                  },
                ),

                if (_error != null) ...[
                  const SizedBox(height: AppDimensions.spaceMD),
                  AppInfoContainer(
                    icon: Icons.error_outline,
                    color: colorScheme.errorContainer,
                    child: Text(
                      _error!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppDimensions.spaceLG),

                AppPrimaryButton(
                  label: AppStrings.loginOtpVerify,
                  onPressed: _codeCtrl.text.length == 6 ? _verifyOtp : null,
                  isLoading: _verifying,
                ),

                const SizedBox(height: AppDimensions.spaceLG),

                // Resend row
                Center(
                  child: _resendCountdown > 0
                      ? Text(
                          '${AppStrings.loginOtpResend} ${_resendCountdown}s',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppStrings.loginOtpDidntReceive,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spaceXS),
                            AppTextButton(
                              label: 'Resend',
                              onPressed: _resendOtp,
                            ),
                          ],
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}