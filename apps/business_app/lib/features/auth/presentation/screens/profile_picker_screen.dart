import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/storage/app_database.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../../shared/widgets/widgets.dart';

/// Adaptive profile picker — list on mobile, grid on tablet, 3-col on desktop.
class ProfilePickerScreen extends ConsumerWidget {
  const ProfilePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authProvider);
    return state.maybeWhen(
      profilesAvailable: (profiles) => _ProfilePickerBody(profiles: profiles),
      orElse: () => const Scaffold(
        body: AppLoadingIndicator(),
      ),
    );
  }
}

class _ProfilePickerBody extends StatelessWidget {
  const _ProfilePickerBody({required this.profiles});
  final List<LocalUserProfile> profiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(AppStrings.profilePickerTitle),
        centerTitle: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceMD,
                vertical: AppDimensions.spaceSM,
              ),
              child: Text(
                AppStrings.profilePickerSubtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),

            const AppDivider(),

            Expanded(
              child: profiles.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.person_outline,
                      title: 'No profiles yet',
                      subtitle: AppStrings.profilePickerEmpty,
                    )
                  : _ProfileGrid(profiles: profiles),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceMD),
              child: Consumer(
                builder: (context, ref, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.profilePickerNewStaff,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    AppTextButton(
                      label: AppStrings.profilePickerSignIn,
                      onPressed: () {
                        ref.read(authProvider.notifier).startOtpLogin();
                        context.go(AppRoutes.loginOtp);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileGrid extends ConsumerWidget {
  const _ProfileGrid({required this.profiles});
  final List<LocalUserProfile> profiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= AppDimensions.breakpointTablet;
    final isDesktop = width >= AppDimensions.breakpointDesktop;

    int crossAxisCount = 1;
    if (isDesktop) {
      crossAxisCount = 3;
    } else if (isTablet) {
      crossAxisCount = 2;
    }

    if (!isTablet) {
      // Mobile: vertical list
      return ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceMD,
          vertical: AppDimensions.spaceSM,
        ),
        itemCount: profiles.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spaceMD),
        itemBuilder: (context, i) => _ProfileCard(
          profile: profiles[i],
          compact: true,
          onTap: () => _selectProfile(context, ref, profiles[i]),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppDimensions.spaceLG),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppDimensions.spaceMD,
        crossAxisSpacing: AppDimensions.spaceMD,
        mainAxisExtent: 220,
      ),
      itemCount: profiles.length,
      itemBuilder: (context, i) => _ProfileCard(
        profile: profiles[i],
        compact: false,
        onTap: () => _selectProfile(context, ref, profiles[i]),
      ),
    );
  }
}

void _selectProfile(BuildContext context, WidgetRef ref, LocalUserProfile profile) {
  ref.read(authProvider.notifier).selectProfileForUnlock(profile.userId);
  context.go(AppRoutes.pinUnlock);
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.onTap,
    this.compact = false,
  });

  final LocalUserProfile profile;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLocked = profile.pinLockedUntil?.isAfter(DateTime.now()) == true;
    final isActive = profile.isCurrentlyActive && !isLocked;

    if (compact) {
      // Mobile list row
      return AppCard(
        variant: AppCardVariant.flat,
        onTap: onTap,
        padding: const EdgeInsets.all(AppDimensions.spaceMD),
        child: Row(
          children: [
            _avatar(colorScheme, isLocked, size: 52),
            const SizedBox(width: AppDimensions.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimensions.spaceXXS),
                  Text(
                    profile.phone,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spaceSM),
            if (isLocked)
              const AppStatusChip(
                label: 'Locked',
                variant: AppStatusChipVariant.locked,
                icon: Icons.lock_outline,
              )
            else if (isActive)
              const AppStatusChip(
                label: 'Active',
                variant: AppStatusChipVariant.active,
              ),
            const SizedBox(width: AppDimensions.spaceSM),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      );
    }

    // Tablet / desktop card
    return AppCard(
      variant: AppCardVariant.flat,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _avatar(colorScheme, isLocked, size: 64),
            const SizedBox(height: AppDimensions.spaceMD),
            Text(
              profile.displayName,
              style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppDimensions.spaceXXS),
            Text(
              profile.phone,
              style: AppTextStyles.bodySmall.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isLocked || isActive) ...[
              const SizedBox(height: AppDimensions.spaceSM),
              AppStatusChip(
                label: isLocked ? 'Locked' : 'Active',
                variant: isLocked
                    ? AppStatusChipVariant.locked
                    : AppStatusChipVariant.active,
                icon: isLocked ? Icons.lock_outline : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _avatar(ColorScheme cs, bool isLocked, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isLocked
            ? LinearGradient(colors: [cs.errorContainer, cs.error.withValues(alpha: 0.5)])
            : const LinearGradient(
                colors: [AppColors.seedTerracotta, AppColors.seedSage],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      child: Icon(
        isLocked ? Icons.lock : Icons.person,
        size: size * 0.45,
        color: isLocked ? cs.onErrorContainer : Colors.white,
      ),
    );
  }
}