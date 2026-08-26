import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/staff_member.dart';
import '../../providers/roles_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/staff_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/detail_page/detail_page_scaffold.dart';
import '../../widgets/saved_tick.dart';
import '../../widgets/image_upload_field.dart';
import '../../widgets/labeled_form_field.dart';
import '../../widgets/staff/role_badge.dart';
import 'store_settings_screen.dart' show SettingSwitchTile;

abstract final class AccountSettingsKeys {
  static const fullName = Key('account.fullName');
  static const email = Key('account.email');
  static const phone = Key('account.phone');
  static const changePin = Key('account.changePin');
  static const twoFactor = Key('account.twoFactor');
  static const deactivate = Key('account.deactivate');
}

/// The signed-in person's own settings.
///
/// The third of three settings scopes, and the distinction is the point:
/// Business Profile is the business, App Preferences is this device, and this
/// is you. A cashier can change their own phone number here without being able
/// to touch either of the other two.
class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState
    extends ConsumerState<AccountSettingsScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  bool _seeded = false;

  /// Which field last saved, so only that row confirms. Same live-save
  /// treatment App Preferences uses — these are single values with nothing to
  /// validate across, so a Save button would only be a step to forget.
  String? _savedField;
  int _savedToken = 0;
  Timer? _debounce;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;

    final member = ref.read(sessionStaffProvider);
    if (member == null) return;
    _name.text = member.name;
    _email.text = member.email;
    _phone.text = member.phone;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  /// Text fields save on a pause rather than on every keystroke — a "Saved"
  /// tick flashing on each letter is noise, not reassurance.
  void _saveTextSoon(String field) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _commitProfile();
      _confirm(field);
    });
  }

  void _commitProfile() {
    final member = ref.read(sessionStaffProvider);
    if (member == null) return;

    ref
        .read(staffMembersProvider.notifier)
        .upsert(
          member.copyWith(
            name: _name.text.trim().isEmpty ? member.name : _name.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim(),
          ),
        );
  }

  void _confirm(String field) {
    setState(() {
      _savedField = field;
      _savedToken++;
    });
  }

  Widget _tick(String field) =>
      SavedTick(visible: _savedField == field, token: _savedToken);

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(sessionStaffProvider);
    final role = member == null
        ? null
        : ref.watch(roleByIdProvider(member.roleId));

    return DetailPageScaffold(
      // Capped like App Preferences: a form of single fields read badly when
      // stretched across a 1920px monitor.
      maxContentWidth: 680,
      header: DetailPageHeader(
        title: 'Account',
        subtitle: 'Your own details and how you sign in',
        onBack: () => context.canPop()
            ? context.pop()
            : context.goNamed(AppRoute.settingsName),
      ),
      children: [
        _ProfilePanel(
          member: member,
          name: _name,
          email: _email,
          phone: _phone,
          tick: _tick,
          onChanged: _saveTextSoon,
          onAvatarChanged: () => _confirm('avatar'),
        ),
        _SecurityPanel(tick: _tick, onChanged: _confirm),
        _DangerZone(member: member, role: role),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Profile
// ---------------------------------------------------------------------------

class _ProfilePanel extends ConsumerStatefulWidget {
  const _ProfilePanel({
    required this.member,
    required this.name,
    required this.email,
    required this.phone,
    required this.tick,
    required this.onChanged,
    required this.onAvatarChanged,
  });

  final StaffMember? member;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController phone;
  final Widget Function(String field) tick;
  final ValueChanged<String> onChanged;
  final VoidCallback onAvatarChanged;

  @override
  ConsumerState<_ProfilePanel> createState() => _ProfilePanelState();
}

class _ProfilePanelState extends ConsumerState<_ProfilePanel> {
  /// Held on the screen rather than the staff record: [StaffMember] carries no
  /// avatar field, and inventing one would ripple through the staff table, its
  /// exports and its fixtures for a picture only this screen shows. The initials
  /// avatar stays the fallback everywhere else.
  Uint8List? _avatar;

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final role = member == null
        ? null
        : ref.watch(roleByIdProvider(member.roleId));

    return DetailPanel(
      title: 'Profile',
      trailing: widget.tick('avatar'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circular clip over the square uploader, so an avatar reads as
                // an avatar rather than as a product photo.
                ClipOval(
                  child: _avatar == null && member != null
                      ? _AvatarPicker(
                          onPicked: (name, bytes) {
                            setState(() => _avatar = bytes);
                            widget.onAvatarChanged();
                          },
                          fallback: StaffAvatar(
                            initials: member.initials,
                            role: role,
                            size: 96,
                          ),
                        )
                      : ImageUploadField(
                          image: _avatar,
                          size: 96,
                          label: 'Photo',
                          hint: '',
                          onPicked: (name, bytes) {
                            setState(() => _avatar = bytes);
                            widget.onAvatarChanged();
                          },
                          onRemoved: () {
                            setState(() => _avatar = null);
                            widget.onAvatarChanged();
                          },
                        ),
                ),
                const SizedBox(height: Insets.sm),
                if (role != null) RoleBadge(role: role, dense: true),
              ],
            ),
          ),
          const SizedBox(height: Insets.xl),
          LabeledFormField(
            label: 'Full name',
            child: TextField(
              key: AccountSettingsKeys.fullName,
              controller: widget.name,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => widget.onChanged('name'),
            ),
          ),
          const SizedBox(height: Insets.md),
          widget.tick('name'),
          const SizedBox(height: Insets.md),
          LabeledFormField(
            label: 'Email',
            child: TextField(
              key: AccountSettingsKeys.email,
              controller: widget.email,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => widget.onChanged('email'),
            ),
          ),
          const SizedBox(height: Insets.lg),
          LabeledFormField(
            label: 'Phone',
            child: TextField(
              key: AccountSettingsKeys.phone,
              controller: widget.phone,
              keyboardType: TextInputType.phone,
              onChanged: (_) => widget.onChanged('phone'),
            ),
          ),
        ],
      ),
    );
  }
}

/// The initials avatar, tappable to replace it with a photo.
///
/// [ImageUploadField]'s empty state is a dashed upload box, which is right for
/// a product photo and wrong here — someone already has a face in this app, so
/// the empty state should be that face rather than a placeholder.
class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.onPicked, required this.fallback});

  final void Function(String name, Uint8List bytes) onPicked;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        fallback,
        Material(
          color: context.colors.primary,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              // Hands off to the shared uploader by showing it in a sheet: one
              // picker implementation, two presentations.
              showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (sheetContext) => Padding(
                  padding: const EdgeInsets.all(Insets.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Profile photo',
                        style: sheetContext.text.titleMedium,
                      ),
                      const SizedBox(height: Insets.lg),
                      ImageUploadField(
                        image: null,
                        size: 160,
                        label: 'Choose a photo',
                        onPicked: (name, bytes) {
                          Navigator.of(sheetContext).pop();
                          onPicked(name, bytes);
                        },
                        onRemoved: () {},
                      ),
                      const SizedBox(height: Insets.lg),
                    ],
                  ),
                ),
              );
            },
            child: SizedBox(
              height: 30,
              width: 30,
              child: Icon(
                Icons.photo_camera_outlined,
                size: 15,
                color: context.colors.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Security
// ---------------------------------------------------------------------------

class _SecurityPanel extends ConsumerWidget {
  const _SecurityPanel({required this.tick, required this.onChanged});

  final Widget Function(String field) tick;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return DetailPanel(
      title: 'Security',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Unlock PIN',
                      style: context.text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      session.hasPin
                          ? 'Six digits, used to unlock this terminal'
                          : 'No PIN set yet',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Insets.md),
              OutlinedButton(
                key: AccountSettingsKeys.changePin,
                // The same Set PIN screen first-time setup uses, told through
                // the route that it is a change rather than a first run.
                onPressed: () => context.go(AppRoute.setPin(change: true)),
                child: Text(session.hasPin ? 'Change PIN' : 'Set PIN'),
              ),
            ],
          ),
          const SizedBox(height: Insets.lg),
          SettingSwitchTile(
            switchKey: AccountSettingsKeys.twoFactor,
            title: 'Two-factor via OTP',
            subtitle: session.twoFactorEnabled
                ? 'A code is texted to you on top of your PIN'
                : 'Your PIN alone unlocks this terminal',
            value: session.twoFactorEnabled,
            trailing: tick('twoFactor'),
            onChanged: (value) {
              ref.read(sessionProvider.notifier).setTwoFactor(value);
              onChanged('twoFactor');
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Danger zone
// ---------------------------------------------------------------------------

/// Set apart by a tinted border rather than only by a red button, because the
/// action inside it is irreversible and should not look like the rows above.
class _DangerZone extends ConsumerWidget {
  const _DangerZone({required this.member, required this.role});

  final StaffMember? member;
  final dynamic role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final danger = context.semantic.danger;

    return Container(
      decoration: BoxDecoration(
        color: context.semantic.dangerContainer.withValues(alpha: 0.35),
        borderRadius: Radii.card,
        border: Border.all(color: danger.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.all(Insets.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 17, color: danger),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: Text(
                  'DANGER ZONE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelSmall?.copyWith(
                    color: danger,
                    letterSpacing: 0.9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          Text(
            'Deactivating closes your own access to this business. It is not '
            'the same as an owner deactivating someone else from the Staff '
            'screen — only you can do this to your own account, and you will '
            'need an owner to let you back in.',
            style: context.text.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Insets.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: AccountSettingsKeys.deactivate,
              onPressed: () => _confirm(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: danger,
                side: BorderSide(color: danger.withValues(alpha: 0.5)),
              ),
              icon: const Icon(Icons.person_off_outlined, size: 18),
              label: const Text('Deactivate my account'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final name = member?.name ?? 'your account';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Deactivate your account?'),
        content: Text(
          '$name will lose access to this business immediately and be signed '
          'out of every terminal. Sales already recorded stay on the ledger. '
          'Only an owner can reactivate the account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep my account'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: dialogContext.semantic.danger,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final id = member?.id;
    if (id != null) {
      ref
          .read(staffMembersProvider.notifier)
          .setStatus(id, StaffStatus.inactive);
      ref.read(sessionProvider.notifier).forgetProfile(id);
    }
    // Signing out is what makes the deactivation real from here: the guard
    // sees no session and puts the front door back up.
    ref.read(sessionProvider.notifier).signOut();
  }
}
