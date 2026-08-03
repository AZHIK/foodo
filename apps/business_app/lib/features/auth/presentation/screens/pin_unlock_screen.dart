import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/storage/app_database.dart' show LocalUserProfile;
import '../../../auth/application/auth_notifier.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../../shared/widgets/widgets.dart';

/// PIN unlock screen for both profile-picker selection and inactivity re-lock.
class PinUnlockScreen extends ConsumerStatefulWidget {
  const PinUnlockScreen({super.key});

  @override
  ConsumerState<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends ConsumerState<PinUnlockScreen> {
  final _pinPadKey = GlobalKey<AppPinPadState>();
  String _pin = '';
  String? _error;
  bool _isVerifying = false;

  bool _isProfileLocked(LocalUserProfile p) =>
      p.pinLockedUntil != null && p.pinLockedUntil!.isAfter(DateTime.now());

  LocalUserProfile? _pendingProfile(AuthState state) {
    if (state is! ProfilesAvailable) return null;
    final pid = ref.read(authProvider.notifier).pendingProfileId;
    if (pid == null) return null;
    return state.profiles.where((p) => p.userId == pid).firstOrNull;
  }

  Future<void> _submitPin() async {
    if (_pin.isEmpty || _isVerifying) return;
    final state = ref.read(authProvider);
    setState(() {
      _error = null;
      _isVerifying = true;
    });

    Failure? failure;
    if (state is ProfilesAvailable) {
      final pid = ref.read(authProvider.notifier).pendingProfileId;
      if (pid == null) {
        setState(() => _isVerifying = false);
        return;
      }
      failure = await ref.read(authProvider.notifier).activateProfile(pid, pin: _pin);
    } else if (state is SessionActive) {
      failure = await ref.read(authProvider.notifier).unlock(pin: _pin);
    } else {
      setState(() => _isVerifying = false);
      return;
    }
    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (failure != null) {
      setState(() {
        _error = _mapFailure(failure!);
        _pin = '';
      });
      _pinPadKey.currentState?.clear();
    }
  }

  Future<void> _startLockoutResolution() async {
    final state = ref.read(authProvider);
    String? userId;
    if (state is PinLockedOut) {
      userId = state.profile.userId;
    } else {
      userId = _pendingProfile(state)?.userId;
    }
    if (userId == null) return;

    final failure = await ref.read(authProvider.notifier).startLockoutResolution(userId);
    if (!mounted) return;
    if (failure != null) {
      AppSnackBar.showError(context, _mapFailure(failure));
    }
  }

  Future<void> _leaveUnlockScreen() async {
    final state = ref.read(authProvider);
    if (state is ProfilesAvailable) { context.go(AppRoutes.profilePicker); return; }
    await ref.read(authProvider.notifier).endShift();
    if (!mounted) return;
    context.go(AppRoutes.profilePicker);
  }

  String _mapFailure(Failure f) => f.when(
        network: (m, _) => m ?? AppStrings.networkError,
        validation: (m) => m ?? AppStrings.unknownError,
        auth: (m) => m ?? AppStrings.authError,
        unknown: (m, _) => m ?? AppStrings.unknownError,
      );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final pendingProfile = _pendingProfile(state);
    final isLockout = state is PinLockedOut ||
        (pendingProfile != null && _isProfileLocked(pendingProfile));

    return PopScope(
      canPop: false,
      child: AppAuthPage(
        leading: isLockout
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _leaveUnlockScreen,
              ),
        scrollable: false,
        child: isLockout
            ? _LockoutView(onVerify: _startLockoutResolution, onBack: _leaveUnlockScreen)
            : _UnlockView(
                pinPadKey: _pinPadKey,
                error: _error,
                isVerifying: _isVerifying,
                onPinChanged: (pin) => setState(() {
                  _pin = pin;
                  _error = null;
                }),
                onPinCompleted: (pin) {
                  _pin = pin;
                  _submitPin();
                },
                onSubmit: _submitPin,
                onLeave: _leaveUnlockScreen,
                colorScheme: colorScheme,
              ),
      ),
    );
  }
}

class _UnlockView extends StatelessWidget {
  const _UnlockView({
    required this.pinPadKey,
    required this.error,
    required this.isVerifying,
    required this.onPinChanged,
    required this.onPinCompleted,
    required this.onSubmit,
    required this.onLeave,
    required this.colorScheme,
  });

  final GlobalKey<AppPinPadState> pinPadKey;
  final String? error;
  final bool isVerifying;
  final ValueChanged<String> onPinChanged;
  final ValueChanged<String> onPinCompleted;
  final VoidCallback onSubmit;
  final VoidCallback onLeave;
  final ColorScheme colorScheme;

@override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 640;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
      children: [
        // Icon
        Container(
          width: compact ? 56 : 72,
          height: compact ? 56 : 72,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.lock_outline, size: compact ? 28 : 36, color: colorScheme.primary),
        ),

        SizedBox(height: compact ? AppDimensions.spaceMD : AppDimensions.spaceLG),

        Text(
          AppStrings.pinUnlockTitle,
          style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spaceSM),
        Text(
          AppStrings.pinUnlockSubtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: compact ? AppDimensions.spaceMD : AppDimensions.spaceXL),

        AppPinPad(
          key: pinPadKey,
          errorText: error,
          enabled: !isVerifying,
          compact: compact,
          onChanged: onPinChanged,
          onCompleted: onPinCompleted,
        ),

        SizedBox(height: compact ? AppDimensions.spaceSM : AppDimensions.spaceLG),

        AppPrimaryButton(
          label: AppStrings.pinUnlockTitle,
          isLoading: isVerifying,
          onPressed: onSubmit,
        ),

        SizedBox(height: compact ? AppDimensions.spaceXS : AppDimensions.spaceMD),

        AppTextButton(label: 'End shift', onPressed: onLeave),
      ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LockoutView extends StatelessWidget {
  const _LockoutView({required this.onVerify, required this.onBack});
  final VoidCallback onVerify;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.lock, size: 40, color: colorScheme.error),
        ),

        const SizedBox(height: AppDimensions.spaceLG),

        Text(
          AppStrings.pinLockedOutTitle,
          style: AppTextStyles.headlineSmall.copyWith(
            color: colorScheme.error,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppDimensions.spaceMD),

        AppInfoContainer(
          icon: Icons.warning_amber_outlined,
          color: colorScheme.errorContainer,
          child: const Text(AppStrings.pinLockedOutMessage),
        ),

        const SizedBox(height: AppDimensions.spaceXL),

        AppPrimaryButton(
          label: AppStrings.pinLockedOutVerifyPhone,
          icon: Icons.phone_outlined,
          onPressed: onVerify,
        ),

        const SizedBox(height: AppDimensions.spaceMD),

        AppTextButton(label: AppStrings.pinLockedOutBack, onPressed: onBack),
      ],
              ),
            ),
          ),
        );
      },
    );
  }
}
