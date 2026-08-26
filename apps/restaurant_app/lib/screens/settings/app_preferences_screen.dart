import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/preferences_provider.dart';
import '../../providers/roles_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/staff_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/detail_page/detail_page_scaffold.dart';
import '../../widgets/labeled_form_field.dart';
import '../../widgets/saved_tick.dart';
import '../../widgets/selectable_option_card.dart';
import 'store_settings_screen.dart' show SettingSwitchTile;

abstract final class AppPreferencesKeys {
  static const themeLight = Key('appPrefs.theme.light');
  static const themeDark = Key('appPrefs.theme.dark');
  static const themeSystem = Key('appPrefs.theme.system');
  static const lowStock = Key('appPrefs.lowStock');
  static const orderSounds = Key('appPrefs.orderSounds');
  static const dailySummary = Key('appPrefs.dailySummary');
  static const language = Key('appPrefs.language');
  static const logOut = Key('appPrefs.logOut');

  static Key density(TableDensity density) =>
      Key('appPrefs.density.${density.name}');
}

/// Preferences that belong to this device and this person, not to the
/// business — which is what separates this screen from Store Settings.
///
/// Everything here saves the moment it changes. There is nothing to validate
/// and nothing that only makes sense applied together, so a Save button would
/// be an extra step between a switch and its effect; a brief confirmation next
/// to the control that moved does the same reassuring job for free.
class AppPreferencesScreen extends ConsumerStatefulWidget {
  const AppPreferencesScreen({super.key});

  @override
  ConsumerState<AppPreferencesScreen> createState() =>
      _AppPreferencesScreenState();
}

class _AppPreferencesScreenState extends ConsumerState<AppPreferencesScreen> {
  /// The control that most recently changed, so only that row shows the
  /// confirmation. Cleared by [_SavedTick] once it has faded out.
  String? _savedField;
  int _savedToken = 0;

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
    return DetailPageScaffold(
      // Capped well below the window: a toggle row stretched across a 1920px
      // monitor puts its label and its switch a foot apart.
      maxContentWidth: 680,
      header: DetailPageHeader(
        title: 'App preferences',
        subtitle: 'How this app looks and behaves on this device',
        onBack: () => context.canPop()
            ? context.pop()
            : context.goNamed(AppRoute.settingsName),
      ),
      children: [
        _AppearancePanel(onChanged: () => _confirm('theme'), tick: _tick),
        _NotificationsPanel(onChanged: _confirm, tick: _tick),
        _DisplayPanel(onChanged: _confirm, tick: _tick),
        const _AccountPanel(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Appearance
// ---------------------------------------------------------------------------

class _AppearancePanel extends ConsumerWidget {
  const _AppearancePanel({required this.onChanged, required this.tick});

  final VoidCallback onChanged;
  final Widget Function(String field) tick;

  static const _options = <(ThemeMode, String, IconData, Key)>[
    (
      ThemeMode.light,
      'Light',
      Icons.light_mode_rounded,
      AppPreferencesKeys.themeLight,
    ),
    (
      ThemeMode.dark,
      'Dark',
      Icons.dark_mode_rounded,
      AppPreferencesKeys.themeDark,
    ),
    (
      ThemeMode.system,
      'System',
      Icons.brightness_auto_rounded,
      AppPreferencesKeys.themeSystem,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return DetailPanel(
      title: 'Appearance',
      trailing: tick('theme'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectableOptionGrid(
            perRow: 3,
            children: [
              for (final (value, label, icon, key) in _options)
                SelectableOptionCard(
                  key: key,
                  label: label,
                  icon: icon,
                  selected: mode == value,
                  onTap: () {
                    ref.read(themeModeProvider.notifier).set(value);
                    onChanged();
                  },
                ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          Text(
            mode == ThemeMode.system
                ? 'Following this device\'s light/dark setting'
                : 'Always ${mode == ThemeMode.light ? 'light' : 'dark'}, '
                      'whatever the device is set to',
            style: context.text.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifications
// ---------------------------------------------------------------------------

class _NotificationsPanel extends ConsumerWidget {
  const _NotificationsPanel({required this.onChanged, required this.tick});

  final ValueChanged<String> onChanged;
  final Widget Function(String field) tick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPrefsProvider);
    final notifier = ref.read(notificationPrefsProvider.notifier);

    return DetailPanel(
      title: 'Notifications',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SettingSwitchTile(
            switchKey: AppPreferencesKeys.lowStock,
            title: 'Low stock alerts',
            subtitle: 'Warn when a line drops below its reorder level',
            value: prefs.lowStock,
            trailing: tick('lowStock'),
            onChanged: (value) {
              notifier.setLowStock(value);
              onChanged('lowStock');
            },
          ),
          const SizedBox(height: Insets.md),
          SettingSwitchTile(
            switchKey: AppPreferencesKeys.orderSounds,
            title: 'New order sounds',
            subtitle: 'Chime when a ticket lands at this terminal',
            value: prefs.orderSounds,
            trailing: tick('orderSounds'),
            onChanged: (value) {
              notifier.setOrderSounds(value);
              onChanged('orderSounds');
            },
          ),
          const SizedBox(height: Insets.md),
          SettingSwitchTile(
            switchKey: AppPreferencesKeys.dailySummary,
            title: 'Daily summary email',
            subtitle: 'Yesterday\'s takings, sent each morning',
            value: prefs.dailySummary,
            trailing: tick('dailySummary'),
            onChanged: (value) {
              notifier.setDailySummary(value);
              onChanged('dailySummary');
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Display
// ---------------------------------------------------------------------------

class _DisplayPanel extends ConsumerWidget {
  const _DisplayPanel({required this.onChanged, required this.tick});

  final ValueChanged<String> onChanged;
  final Widget Function(String field) tick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final density = ref.watch(tableDensityProvider);
    final language = ref.watch(appLanguageProvider);

    return DetailPanel(
      title: 'Display',
      trailing: tick('display'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Table density',
            style: context.text.labelLarge?.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: Insets.sm),
          SelectableOptionGrid(
            perRow: 2,
            children: [
              for (final option in TableDensity.values)
                SelectableOptionCard(
                  key: AppPreferencesKeys.density(option),
                  label: option.label,
                  icon: option == TableDensity.comfortable
                      ? Icons.format_line_spacing_rounded
                      : Icons.density_small_rounded,
                  selected: density == option,
                  onTap: () {
                    ref.read(tableDensityProvider.notifier).set(option);
                    onChanged('display');
                  },
                ),
            ],
          ),
          const SizedBox(height: Insets.xs),
          Text(
            density.description,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Insets.xl),
          LabeledFormField(
            label: 'Language',
            helper: 'More languages are on the way',
            child: DropdownButtonFormField<AppLanguage>(
              key: AppPreferencesKeys.language,
              initialValue: language,
              isExpanded: true,
              items: [
                for (final option in AppLanguage.values)
                  DropdownMenuItem(value: option, child: Text(option.label)),
              ],
              onChanged: (value) {
                if (value == null) return;
                ref.read(appLanguageProvider.notifier).set(value);
                onChanged('display');
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Account
// ---------------------------------------------------------------------------

class _AccountPanel extends ConsumerWidget {
  const _AccountPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final member = ref.watch(currentUserProvider);
    final role = member == null
        ? null
        : ref.watch(roleByIdProvider(member.roleId));

    return DetailPanel(
      title: 'Account',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: colors.primaryContainer,
                child: Text(
                  _initials(member?.name ?? '?'),
                  style: context.text.titleSmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      member?.name ?? 'Not signed in',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall,
                    ),
                    Text(
                      [
                        if (role != null) role.name,
                        if (member != null && member.email.isNotEmpty)
                          member.email,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.lg),
          // Full width and left-aligned rather than a small button in a corner:
          // this is the one destructive control on the screen, and it should be
          // findable without being easy to hit by accident — which the
          // confirmation dialog handles.
          OutlinedButton.icon(
            key: AppPreferencesKeys.logOut,
            onPressed: () => _confirmLogOut(context, member?.name),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.semantic.danger,
              side: BorderSide(
                color: context.semantic.danger.withValues(alpha: 0.5),
              ),
            ),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogOut(BuildContext context, String? name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: Text(
          name == null
              ? 'You will need to sign in again to use this terminal.'
              : '$name will be signed out of this terminal. Any open ticket '
                    'stays on the till.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Stay signed in'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: dialogContext.semantic.danger,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // There is no auth layer to sign out of yet. Saying so is better than a
    // button that silently does nothing; when the Auth screens land, this
    // becomes a call to the session notifier and a redirect to the PIN screen.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sign-out takes effect once accounts are connected'),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}
