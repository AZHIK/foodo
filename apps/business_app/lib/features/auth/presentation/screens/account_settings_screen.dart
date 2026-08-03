import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
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
                      enabled: profiles.length > 1,
                      onTap: profiles.length > 1
                          ? () => _showRemoveProfileDialog(context, ref)
                          : null,
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

  Future<void> _showRemoveProfileDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialog.showConfirm(
      context,
      title: 'Remove Profile',
      message: profiles.length == 1
          ? "This will remove the only profile on this device. You'll need to sign in again."
          : 'This will permanently delete this profile and its PIN from this device.',
      confirmLabel: 'Remove',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    if (profiles.isNotEmpty) {
      await ref.read(authProvider.notifier).removeFromDevice(profiles.last.userId);
    }
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