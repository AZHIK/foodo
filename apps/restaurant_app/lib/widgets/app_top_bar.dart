import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/notifications_provider.dart';
import '../constants/app_strings.dart';
import '../providers/preferences_provider.dart';
import '../providers/session_provider.dart';
import '../providers/settings_provider.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';
import 'chat_dialog.dart';

abstract final class AppTopBarKeys {
  static const accountMenu = Key('appTopBar.accountMenu');
  static const endShift = Key('appTopBar.endShift');
  static const logout = Key('appTopBar.logout');
}

/// Top app bar with notifications, account, and other actions.
class AppTopBar extends ConsumerWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final staff = ref.watch(currentStaffProvider);
    // Watch the provider (not the static L10n flag) so this bar rebuilds
    // on every toggle. L10n.code is kept in sync by AppLanguageNotifier.
    final language = ref.watch(appLanguageProvider);
    final isSw = language == AppLanguage.swahili;

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
                    SnackBar(content: Text(AppStrings.helpComingSoon)),
                  );
                },
              ),
              const SizedBox(width: Insets.md),
              _IconButton(
                icon: isSw ? Icons.terrain_rounded : Icons.language_rounded,
                tooltip: isSw ? 'Kiingereza' : 'English',
                onPressed: () {
                  final next = isSw
                      ? AppLanguage.english
                      : AppLanguage.swahili;
                  ref.read(appLanguageProvider.notifier).set(next);
                },
              ),
              const SizedBox(width: Insets.md),
              PopupMenuButton<String>(
                key: AppTopBarKeys.accountMenu,
                tooltip: AppStrings.accountAndOptions,
                onSelected: (value) async {
                  if (value == 'end_shift') {
                    // Offline session only: lock the till, keep tokens so a
                    // PIN unlock resumes online access without a new OTP.
                    ref.read(sessionProvider.notifier).endShift();
                  } else if (value == 'logout') {
                    // Online + offline: revoke backend session, clear stored
                    // tokens, drop local session. Guard routes to picker/login.
                    await ref.read(sessionProvider.notifier).logout();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    key: AppTopBarKeys.endShift,
                    value: 'end_shift',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 18),
                        const SizedBox(width: Insets.sm),
                        Text(AppStrings.endShift),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    key: AppTopBarKeys.logout,
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
