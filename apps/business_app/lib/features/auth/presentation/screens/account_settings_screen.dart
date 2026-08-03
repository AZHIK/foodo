import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/storage/app_database.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../../shared/widgets/widgets.dart';

/// Account settings screen — manage profiles and shifts on this device.
class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authProvider);
    return state.maybeWhen(
      profilesAvailable: (profiles) =>
          _AccountSettingsBody(profiles: profiles, activeProfile: null),
      sessionActive: (active, _) =>
          _AccountSettingsBody(profiles: [active], activeProfile: active),
      pinLockedOut: (locked, _) =>
          _AccountSettingsBody(profiles: [locked], activeProfile: locked),
      orElse: () => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.settings)),
        body: const AppLoadingIndicator(),
      ),
    );
  }
}

class _AccountSettingsBody extends ConsumerWidget {
  const _AccountSettingsBody({required this.profiles, this.activeProfile});

  final List<LocalUserProfile> profiles;
  final LocalUserProfile? activeProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppDimensions.breakpointTablet;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? 600 : double.infinity,
            ),
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.spaceMD),
              children: [
                // ── Profiles section ─────────────────────────────
                const AppSectionHeader(
                  title: 'Profiles on this device',
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceXS,
                    vertical: AppDimensions.spaceSM,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXS),

                AppListTileGroup(
                  tiles: [
                    for (final profile in profiles)
                      _ProfileTile(
                        profile: profile,
                        isActive: activeProfile?.userId == profile.userId,
                      ),
                  ],
                ),

                const SizedBox(height: AppDimensions.spaceXL),

                // ── Actions section ───────────────────────────────
                const AppSectionHeader(
                  title: 'Actions',
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceXS,
                    vertical: AppDimensions.spaceSM,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXS),

                AppListTileGroup(
                  tiles: [
                    if (activeProfile != null)
                      AppListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.pendingSync.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                          ),
                          child: const Icon(Icons.logout, color: AppColors.pendingSync, size: 20),
                        ),
                        title: 'End Shift',
                        subtitle: 'Keep profile for next shift · PIN required to resume',
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final confirmed = await AppDialog.showConfirm(
                            context,
                            title: 'End Shift',
                            message:
                                "End your current shift? You'll need to enter your PIN to resume.",
                            confirmLabel: 'End shift',
                          );
                          if (!confirmed || !context.mounted) return;
                          await ref.read(authProvider.notifier).endShift();
                        },
                      ),
                    if (activeProfile != null)
                      AppListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colorScheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: colorScheme.error,
                            size: 20,
                          ),
                        ),
                        title: 'Remove Profile',
                        subtitle: 'Permanently delete this profile and its PIN from this device',
                        trailing: const Icon(Icons.chevron_right),
                        isDestructive: true,
                        onTap: () =>
                            _showRemoveProfileDialog(context, activeProfile!),
                      ),
                  ],
                ),

                const SizedBox(height: AppDimensions.spaceXXL),

                // App version watermark
                Text(
                  AppStrings.appName,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showRemoveProfileDialog(
    BuildContext context,
    LocalUserProfile active,
  ) async {
    final removed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmRemovalDialog(
        displayName: active.displayName,
        phone: active.phone,
      ),
    );
    if (removed == true && context.mounted) {
      AppSnackBar.showSuccess(context, 'Profile removed from this device.');
    }
  }
}

/// Re-authentication step before permanently removing the active profile.
///
/// Refuses to run until the profile's own PIN is freshly verified against
/// its Argon2id hash — the same seriousness as the lockout-resolution flow.
/// Wrong PINs are rejected in place and the dialog stays open, so nothing
/// is deleted until the correct PIN is entered.
class _ConfirmRemovalDialog extends ConsumerStatefulWidget {
  const _ConfirmRemovalDialog({required this.displayName, required this.phone});

  final String displayName;
  final String phone;

  @override
  ConsumerState<_ConfirmRemovalDialog> createState() =>
      _ConfirmRemovalDialogState();
}

class _ConfirmRemovalDialogState extends ConsumerState<_ConfirmRemovalDialog> {
  final _pinPadKey = GlobalKey<AppPinPadState>();
  String? _error;
  bool _isRemoving = false;

  String? _mapFailure(Failure f) => f.when(
        network: (m, _) => m ?? AppStrings.networkError,
        validation: (m) => m ?? AppStrings.unknownError,
        auth: (m) => m ?? AppStrings.pinWrong,
        unknown: (m, _) => m ?? AppStrings.unknownError,
      );

  Future<void> _submit(String pin) async {
    if (_isRemoving) return;
    setState(() {
      _error = null;
      _isRemoving = true;
    });

    final failure = await ref.read(authProvider.notifier).removeFromDevice(pin: pin);
    if (!mounted) return;

    if (failure != null) {
      setState(() {
        _isRemoving = false;
        _error = _mapFailure(failure);
      });
      _pinPadKey.currentState?.clear();
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      ),
      title: const Text('Remove Profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.displayName.isEmpty
                  ? 'This will permanently delete ${widget.phone} and its '
                      'PIN from this device.'
                  : 'This will permanently delete ${widget.displayName} '
                      '(${widget.phone}) and its PIN from this device.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppDimensions.spaceLG),
            AppPinPad(
              key: _pinPadKey,
              errorText: _error,
              compact: true,
              enabled: !_isRemoving,
              onChanged: (_) => setState(() => _error = null),
              onCompleted: _submit,
            ),
            if (_isRemoving) ...[
              const SizedBox(height: AppDimensions.spaceMD),
              const AppLoadingIndicator(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.profile, required this.isActive});

  final LocalUserProfile profile;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLocked =
        profile.pinLockedUntil?.isAfter(DateTime.now()) == true;

    return AppListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isLocked
              ? LinearGradient(
                  colors: [colorScheme.errorContainer, colorScheme.error.withValues(alpha: 0.5)],
                )
              : const LinearGradient(
                  colors: [AppColors.seedTerracotta, AppColors.seedSage],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: Icon(
          isLocked ? Icons.lock : Icons.person,
          size: 20,
          color: isLocked ? colorScheme.onErrorContainer : Colors.white,
        ),
      ),
      title: profile.displayName,
      subtitle: profile.phone,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLocked)
            const AppStatusChip(
              label: 'Locked',
              variant: AppStatusChipVariant.locked,
            )
          else if (isActive)
            const AppStatusChip(
              label: 'Active',
              variant: AppStatusChipVariant.active,
            ),
        ],
      ),
    );
  }
}