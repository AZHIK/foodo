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
import '../../../auth/application/auth_notifier.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../../shared/widgets/widgets.dart';

/// Set PIN screen — two-step (enter → confirm) with animated transition.
class SetPinScreen extends ConsumerStatefulWidget {
  const SetPinScreen({super.key});

  @override
  ConsumerState<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends ConsumerState<SetPinScreen>
    with SingleTickerProviderStateMixin {
  final _pinPadKey1 = GlobalKey<AppPinPadState>();
  final _pinPadKey2 = GlobalKey<AppPinPadState>();
  final _nameCtrl = TextEditingController();
  final _nameFocus = FocusNode();

  String _pin = '';
  String _confirm = '';
  String? _pinError;
  String? _confirmError;
  bool _isSetting = false;
  bool _onConfirmStep = false;

  late final AnimationController _stepCtrl;
  late final Animation<double> _stepFade;

  @override
  void initState() {
    super.initState();
    _stepCtrl = AnimationController(vsync: this, duration: AppDurations.normal);
    _stepFade = CurvedAnimation(parent: _stepCtrl, curve: Curves.easeInOut);
    _stepCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    _stepCtrl.dispose();
    super.dispose();
  }

  Future<void> _advanceToConfirm(String pin) async {
    if (pin.length < 4) {
      setState(() => _pinError = AppStrings.pinInvalidLength);
      return;
    }
    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      setState(() => _pinError = AppStrings.pinInvalidFormat);
      return;
    }
    _pin = pin;
    await _stepCtrl.reverse();
    setState(() => _onConfirmStep = true);
    _stepCtrl.forward();
  }

  Future<void> _submit(String confirm) async {
    _confirm = confirm;

    if (_pin != _confirm) {
      setState(() => _confirmError = AppStrings.pinSetMismatch);
      _pinPadKey2.currentState?.clear();
      return;
    }

    setState(() {
      _confirmError = null;
      _isSetting = true;
    });

    final state = ref.read(authProvider);
    if (state is! SettingPin) { setState(() => _isSetting = false); return; }

    final displayName = _nameCtrl.text.trim();
    final failure = await ref.read(authProvider.notifier).setPin(
          phone: state.phone,
          userId: state.userId,
          refreshToken: state.refreshToken,
          pin: _pin,
          displayName: displayName.isEmpty ? null : displayName,
        );
    if (!mounted) return;

    if (failure != null) {
      setState(() {
        _isSetting = false;
        _confirmError = _mapFailure(failure);
      });
      _pinPadKey2.currentState?.clear();
    } else {
      // Invited staff skip onboarding and land on the dashboard exactly as
      // before; a self-registered owner (no business yet) is sent to the
      // onboarding flow instead.
      final resulting = ref.read(authProvider);
      if (resulting is OnboardingRequired) {
        context.go(AppRoutes.businessOnboarding);
      } else {
        context.go(AppRoutes.dashboard);
      }
    }
  }

  String _mapFailure(Failure f) => f.when(
        network: (m, _) => m ?? AppStrings.networkError,
        validation: (m) => m ?? AppStrings.unknownError,
        auth: (m) => m ?? AppStrings.authError,
        unknown: (m, _) => m ?? AppStrings.unknownError,
      );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: AppAuthPage(
        leading: _onConfirmStep
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  await _stepCtrl.reverse();
                  setState(() {
                    _onConfirmStep = false;
                    _confirm = '';
                    _confirmError = null;
                  });
                  _pinPadKey1.currentState?.clear();
                  _stepCtrl.forward();
                },
              )
            : null,
        scrollable: true,
        child: FadeTransition(
          opacity: _stepFade,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Header ───────────────────────────────────────────
              Container(
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
                child: const Icon(Icons.lock_outline, size: 36, color: Colors.white),
              ),

              const SizedBox(height: AppDimensions.spaceLG),

              Text(
                _onConfirmStep ? AppStrings.pinSetConfirm : AppStrings.pinSetTitle,
                style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spaceSM),
              Text(
                _onConfirmStep
                    ? 'Re-enter your PIN to confirm'
                    : AppStrings.pinSetSubtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),

              // ── Display name (first step only) ─────────────────
              if (!_onConfirmStep) ...[
                const SizedBox(height: AppDimensions.spaceXL),
                AppTextField(
                  controller: _nameCtrl,
                  focusNode: _nameFocus,
                  label: AppStrings.pinSetDisplayNameHint,
                  hint: 'John Doe',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.done,
                ),
              ],

              const SizedBox(height: AppDimensions.spaceXL),

              // ── PIN pad ─────────────────────────────────────────
              if (!_onConfirmStep)
                AppPinPad(
                  key: _pinPadKey1,
                  errorText: _pinError,
                  onChanged: (_) => setState(() => _pinError = null),
                  onCompleted: _advanceToConfirm,
                )
              else
                AppPinPad(
                  key: _pinPadKey2,
                  errorText: _confirmError,
                  enabled: !_isSetting,
                  onChanged: (_) => setState(() => _confirmError = null),
                  onCompleted: _submit,
                ),

              // ── Step indicator dots ─────────────────────────────
              const SizedBox(height: AppDimensions.spaceLG),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(2, (i) {
                  final active = _onConfirmStep ? i == 1 : i == 0;
                  return AnimatedContainer(
                    duration: AppDurations.fast,
                    margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceXS),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}