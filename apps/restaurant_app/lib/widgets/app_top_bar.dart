import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/notifications_provider.dart';
import '../constants/app_strings.dart';
import '../providers/settings_provider.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';
import 'chat_dialog.dart';

/// Top app bar with notifications, account, and other actions.
class AppTopBar extends ConsumerWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final themeMode = ref.watch(themeModeProvider);
    final staff = ref.watch(currentStaffProvider);

    return Material(
      color: colors.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.semantic.hairline)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Insets.lg, vertical: Insets.md),
          child: Row(
            children: [
              // Spacer for alignment with nav rail/drawer on larger screens
              const SizedBox.shrink(),
              const Spacer(),
              // Actions on the right
              _IconButton(
                icon: Icons.chat_outlined,
                tooltip: AppStrings.chatWithAssistant,
                onPressed: () => ChatDialog.show(context),
              ),
              const SizedBox(width: Insets.md),
              _NotificationButton(
                onPressed: () => context.goNamed(AppRoute.notificationsName),
              ),
              const SizedBox(width: Insets.md),
              _IconButton(
                icon: Icons.help_outline_rounded,
                tooltip: AppStrings.help,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text(AppStrings.helpComingSoon)),
                  );
                },
              ),
              const SizedBox(width: Insets.md),
              PopupMenuButton<String>(
                tooltip: AppStrings.accountAndOptions,
                onSelected: (value) {
                  if (value == 'theme') {
                    ref.read(themeModeProvider.notifier).cycle();
                  } else if (value.startsWith('auth_')) {
                    final paths = <String, String>{
                      'auth_splash': '/',
                      'auth_login': '/auth/login',
                      'auth_onboarding': '/auth/onboarding',
                      'auth_pin': '/auth/set-pin',
                      'auth_unlock': '/auth/unlock',
                      'auth_profile': '/auth/profiles',
                    };
                    final path = paths[value];
                    if (path != null) context.go(path);
                  }
                },
                itemBuilder: (context) => [
                  // Theme selection
                  PopupMenuItem(
                    value: 'theme',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          switch (themeMode) {
                            ThemeMode.system => Icons.brightness_auto_rounded,
                            ThemeMode.light => Icons.light_mode_rounded,
                            ThemeMode.dark => Icons.dark_mode_rounded,
                          },
                          size: 18,
                        ),
                        const SizedBox(width: Insets.sm),
                        Text(
                          switch (themeMode) {
                            ThemeMode.system => AppStrings.followSystem,
                            ThemeMode.light => AppStrings.lightTheme,
                            ThemeMode.dark => AppStrings.darkTheme,
                          },
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  // Auth screens for testing
                  PopupMenuItem(
                    value: 'auth_splash',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.start_rounded, size: 18),
                        const SizedBox(width: Insets.sm),
                        const Text(AppStrings.authTestSplash),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'auth_login',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.login_rounded, size: 18),
                        const SizedBox(width: Insets.sm),
                        const Text(AppStrings.authTestOtp),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'auth_onboarding',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_rounded, size: 18),
                        const SizedBox(width: Insets.sm),
                        const Text(AppStrings.authTestOnboarding),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'auth_pin',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded, size: 18),
                        const SizedBox(width: Insets.sm),
                        const Text(AppStrings.authTestSetPin),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'auth_unlock',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_open_rounded, size: 18),
                        const SizedBox(width: Insets.sm),
                        const Text(AppStrings.authTestPinUnlock),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'auth_profile',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_rounded, size: 18),
                        const SizedBox(width: Insets.sm),
                        const Text(AppStrings.authTestProfiles),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: colors.error,
                        ),
                        const SizedBox(width: Insets.sm),
                        Text(
                          AppStrings.logout,
                          style: TextStyle(color: colors.error),
                        ),
                      ],
                    ),
                  ),
                ],
                child: SizedBox(
                  height: 40,
                  width: 40,
                  child: Material(
                    color: colors.primaryContainer,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        staff.characters.first.toUpperCase(),
                        style: context.text.titleSmall?.copyWith(
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends ConsumerWidget {
  const _NotificationButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(notificationsUnreadCountProvider);

    return _IconButton(
      icon: Icons.notifications_outlined,
      tooltip: AppStrings.notifications,
      badgeCount: unreadCount,
      onPressed: onPressed,
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        height: 40,
        width: 40,
        child: Material(
          color: colors.surfaceContainerLowest,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: context.semantic.hairline),
          ),
          child: badgeCount > 0
              ? Badge.count(
                  count: badgeCount,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    onPressed: onPressed,
                    icon: Icon(icon),
                    color: colors.onSurface,
                  ),
                )
              : IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                  onPressed: onPressed,
                  icon: Icon(icon),
                  color: colors.onSurface,
                ),
        ),
      ),
    );
  }
}
