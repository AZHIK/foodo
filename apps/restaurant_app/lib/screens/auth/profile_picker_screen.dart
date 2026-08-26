import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/staff_member.dart';
import '../../providers/roles_provider.dart';
import '../../providers/session_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/staff/role_badge.dart';

abstract final class ProfilePickerKeys {
  static const addAccount = Key('profilePicker.addAccount');
  static const signInDifferently = Key('profilePicker.signInDifferently');

  static Key profile(String staffId) => Key('profilePicker.$staffId');
}

/// Who is on shift, on a terminal several people share.
///
/// A counter till is not a personal device: the same tablet is used by the
/// owner at 8am and two cashiers by lunch. Picking a face is faster than
/// typing a phone number, and it is what makes a six-digit PIN enough on its
/// own — the identity is already established before the PIN is asked for.
class ProfilePickerScreen extends ConsumerWidget {
  const ProfilePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(savedProfilesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuthBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final pad = Insets.page(context.formFactor);

              return ListView(
                padding: EdgeInsets.fromLTRB(pad, Insets.xxl, pad, pad),
                children: [
                  Center(
                    child: ConstrainedBox(
                      // Wide enough for five tiles across on a desktop
                      // terminal, capped so they do not drift apart on a
                      // 1920px screen.
                      constraints: const BoxConstraints(maxWidth: 940),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: BrandMark(size: 52)),
                          const SizedBox(height: Insets.xl),
                          Text(
                            'Who\'s working?',
                            textAlign: TextAlign.center,
                            style: context.text.headlineSmall,
                          ),
                          const SizedBox(height: Insets.xs),
                          Text(
                            profiles.isEmpty
                                ? 'No one has signed in on this terminal yet'
                                : 'Choose your profile to unlock the till',
                            textAlign: TextAlign.center,
                            style: context.text.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: Insets.xxl),
                          _ProfileGrid(profiles: profiles),
                          const SizedBox(height: Insets.xxl),
                          Center(
                            child: AuthLink(
                              key: ProfilePickerKeys.signInDifferently,
                              label: 'Not your device? Sign in differently',
                              icon: Icons.help_outline_rounded,
                              onPressed: () =>
                                  context.goNamed(AppRoute.loginName),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileGrid extends StatelessWidget {
  const _ProfileGrid({required this.profiles});

  final List<StaffMember> profiles;

  /// A tile has to hold an avatar, a name and a role pill without the name
  /// ellipsising to two letters — below this the grid drops a column instead.
  static const double _minTileWidth = 168;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = Insets.md;

        // Derived from the width the grid actually got rather than the
        // window's, so it stays right inside the capped content column.
        final fits = (constraints.maxWidth / _minTileWidth).floor();
        final columns = fits.clamp(2, 5);
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          alignment: WrapAlignment.center,
          children: [
            for (final member in profiles)
              SizedBox(width: width, child: _ProfileTile(member: member)),
            SizedBox(width: width, child: const _AddAccountTile()),
          ],
        );
      },
    );
  }
}

class _ProfileTile extends ConsumerWidget {
  const _ProfileTile({required this.member});

  final StaffMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(roleByIdProvider(member.roleId));

    return Material(
      color: context.colors.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.card,
        side: BorderSide(color: context.semantic.hairline),
      ),
      child: InkWell(
        key: ProfilePickerKeys.profile(member.id),
        onTap: () {
          // Records who is signing in; the guard is what actually moves us to
          // the PIN screen, so this never navigates by hand.
          ref.read(sessionProvider.notifier).selectProfile(member.id);
          context.goNamed(AppRoute.unlockName);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.md,
            vertical: Insets.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StaffAvatar(initials: member.initials, role: role, size: 60),
              const SizedBox(height: Insets.md),
              Text(
                member.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleSmall,
              ),
              const SizedBox(height: Insets.sm),
              RoleBadge(role: role, dense: true),
              const SizedBox(height: Insets.sm),
              Text(
                member.lastActiveAt == null
                    ? 'Not signed in yet'
                    : Fmt.relativeDateTime(member.lastActiveAt!),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The way onto a shared terminal for someone whose face is not on it yet.
///
/// A dashed outline rather than a filled card, matching [ImageUploadField]'s
/// empty state — in this app a dashed border means "there could be something
/// here", and that is exactly what this slot is.
class _AddAccountTile extends StatelessWidget {
  const _AddAccountTile();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.surfaceContainerHigh.withValues(alpha: 0.4),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.card,
        side: BorderSide(
          color: colors.outlineVariant,
          // Dart draws no dashed borders natively; a lighter, wider rule reads
          // as the same "empty slot" invitation without a custom painter for
          // one tile.
          width: 1.4,
        ),
      ),
      child: InkWell(
        key: ProfilePickerKeys.addAccount,
        onTap: () => context.goNamed(AppRoute.loginName),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.md,
            vertical: Insets.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.outlineVariant, width: 1.4),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 26,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: Insets.md),
              Text(
                'Add account',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleSmall,
              ),
              const SizedBox(height: Insets.sm),
              Text(
                'Sign in with a phone number',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
