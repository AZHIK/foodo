import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/business_profile.dart';
import '../../models/business_role.dart';
import '../../models/order.dart';
import '../../models/store_location.dart';
import '../../models/store_settings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/roles_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/staff_provider.dart';
import '../../providers/store_locations_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../../widgets/auth/auth_aside.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/step_bar.dart';
import '../../widgets/field_pair.dart';
import '../../widgets/image_upload_field.dart';
import '../../widgets/labeled_form_field.dart';

abstract final class OnboardingKeys {
  static const businessName = Key('onboarding.businessName');
  static const businessType = Key('onboarding.businessType');
  static const locationName = Key('onboarding.locationName');
  static const address = Key('onboarding.address');
  static const phone = Key('onboarding.phone');
  static const currency = Key('onboarding.currency');
  static const taxRate = Key('onboarding.taxRate');
  static const orderType = Key('onboarding.orderType');
  static const back = Key('onboarding.back');
  static const next = Key('onboarding.next');
  static const addTeammate = Key('onboarding.addTeammate');

  static Key teammateName(int index) => Key('onboarding.teammate.$index.name');
  static Key teammateEmail(int index) => Key('onboarding.teammate.$index.email');
  static Key removeTeammate(int index) =>
      Key('onboarding.teammate.$index.remove');
}

/// The steps, named once. Drives both the aside's list and the count the bar
/// divides itself into, so adding a step here is the only edit needed.
const _steps = <AuthStep>[
  AuthStep(
    label: 'Your business',
    blurb: 'Name, type and logo',
    icon: Icons.storefront_rounded,
  ),
  AuthStep(
    label: 'Where you trade',
    blurb: 'Address and contact',
    icon: Icons.place_outlined,
  ),
  AuthStep(
    label: 'How you charge',
    blurb: 'Currency, tax and orders',
    icon: Icons.percent_rounded,
  ),
  AuthStep(
    label: 'Your team',
    blurb: 'Invite the people who work here',
    icon: Icons.group_outlined,
  ),
];

/// One row of the team step, before it becomes a real invite.
class _Teammate {
  _Teammate({this.roleId});

  final TextEditingController name = TextEditingController();
  final TextEditingController email = TextEditingController();
  String? roleId;

  /// A row with a name is worth sending. Email is optional here — chasing a
  /// missing address is a better problem than blocking setup over one.
  bool get isComplete => name.text.trim().isNotEmpty;

  void dispose() {
    name.dispose();
    email.dispose();
  }
}

/// The one-time setup a brand-new business walks through before it sees the
/// Dashboard.
///
/// Every field here writes to a provider that already existed — Business
/// Profile, Store Locations, Store Settings — rather than to an onboarding
/// store of its own. That is the whole point: what is typed here is the same
/// data the Settings screens edit later, so there is nothing to migrate and
/// nothing that can disagree.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static final _stepCount = _steps.length;

  int _step = 0;

  // Step 1
  final _businessName = TextEditingController();
  BusinessType _businessType = BusinessType.restaurant;
  String? _logoName;
  Uint8List? _logoBytes;

  // Step 2
  final _locationName = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();

  // Step 3
  final _taxRate = TextEditingController(text: '8.25');
  Currency _currency = Currency.usd;
  OrderType _orderType = OrderType.dineIn;

  // Step 4
  final List<_Teammate> _team = [];

  @override
  void initState() {
    super.initState();
    // Seeded from whatever the providers already hold, so someone re-running
    // onboarding is correcting real values rather than retyping them. Every
    // step seeds, not just the first — a half-seeded wizard is worse than an
    // empty one, because the empty fields read as "we lost this".
    final profile = ref.read(businessProfileProvider);
    _businessName.text = profile.name;
    _businessType = profile.type;
    _logoBytes = profile.logoBytes;
    _logoName = profile.logoName;

    final store = ref.read(currentStoreProvider);
    if (store != null) {
      _locationName.text = store.name;
      _address.text = store.address;
      _phone.text = store.phone;
    }

    final settings = ref.read(storeSettingsProvider);
    _currency = settings.currency;
    _orderType = settings.defaultOrderType;
    _taxRate.text = (settings.taxRate * 100).toStringAsFixed(2);

    _team.add(_Teammate(roleId: _defaultRoleId));
  }

  @override
  void dispose() {
    for (final controller in [
      _businessName,
      _locationName,
      _address,
      _phone,
      _taxRate,
    ]) {
      controller.dispose();
    }
    for (final member in _team) {
      member.dispose();
    }
    super.dispose();
  }

  /// The role a new row starts on. Whichever role the business already treats
  /// as front-of-house, falling back to the first one defined.
  String? get _defaultRoleId {
    final roles = ref.read(rolesProvider);
    if (roles.isEmpty) return null;
    for (final role in roles) {
      if (role.hasPosAccess) return role.id;
    }
    return roles.first.id;
  }

  /// Whether the current step has enough to move on. Checked on every keystroke
  /// rather than on submit, because a disabled Continue with no explanation is
  /// only acceptable when the missing field is obvious.
  bool get _canContinue => switch (_step) {
    0 => _businessName.text.trim().isNotEmpty,
    1 => _locationName.text.trim().isNotEmpty,
    2 => _parsedRate != null,
    // The team step never blocks: an owner opening alone on a Tuesday has
    // nobody to invite yet, and hiring is not a setup task.
    3 => true,
    _ => false,
  };

  double? get _parsedRate {
    final parsed = double.tryParse(_taxRate.text.trim());
    if (parsed == null || parsed < 0 || parsed > 100) return null;
    return parsed / 100;
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
  }

  Future<void> _next() async {
    if (!_canContinue) return;

    // Each step commits as it is left, so backing up shows what was saved
    // rather than an empty form.
    switch (_step) {
      case 0:
        final profile = ref.read(businessProfileProvider);
        ref
            .read(businessProfileProvider.notifier)
            .save(
              profile.copyWith(
                name: _businessName.text.trim(),
                type: _businessType,
                logoName: _logoName,
                logoBytes: _logoBytes,
              ),
            );
      case 1:
        _saveFirstLocation();
      case 2:
        ref
            .read(storeSettingsProvider.notifier)
            .save(
              ref
                  .read(storeSettingsProvider)
                  .copyWith(
                    currency: _currency,
                    taxRate: _parsedRate,
                    defaultOrderType: _orderType,
                  ),
            );
      case 3:
        _sendInvites();
        await _finish();
        return;
    }

    setState(() => _step++);
  }

  /// Files each filled-in row as a real pending invite, through the same
  /// notifier the Staff screen's invite dialog uses — so the new names are
  /// already on the Staff list, marked pending, by the time onboarding closes.
  void _sendInvites() {
    final notifier = ref.read(staffMembersProvider.notifier);

    for (final member in _team) {
      if (!member.isComplete) continue;
      notifier.invite(
        name: member.name.text,
        email: member.email.text,
        phone: '',
        roleId: member.roleId ?? _defaultRoleId ?? '',
      );
    }
  }

  /// Writes the business's first site into the same list Store Management
  /// edits — updating the terminal's own location rather than adding a second
  /// one beside it.
  void _saveFirstLocation() {
    final notifier = ref.read(storeLocationsProvider.notifier);
    final current = ref.read(currentStoreProvider);

    final location =
        (current ??
                StoreLocation(
                  id: notifier.nextId(),
                  name: '',
                  isCurrent: true,
                ))
            .copyWith(
              name: _locationName.text.trim(),
              address: _address.text.trim(),
              phone: _phone.text.trim(),
            );

    notifier.upsert(location);
  }

  Future<void> _finish() async {
    try {
      // Create the business with the form data and lock device to it.
      await ref.read(authProvider.notifier).createBusinessAndOnboard(
            name: _businessName.text.trim(),
            address: _address.text.trim(),
            phone: _phone.text.trim(),
            city: _address.text.isNotEmpty ? _address.text.split(',').last.trim() : null,
            countryCode: 'TZ', // Hardcoded per the .env default
            timezone: 'Africa/Dar_es_Salaam',
          );

      // Mark onboarding complete in the session.
      ref.read(sessionProvider.notifier).completeOnboarding();

      if (!mounted) return;
      // Straight to the Dashboard, where the name and logo just entered are
      // already in the nav rail and the greeting — the payoff for having filled
      // this in.
      context.go(ref.read(sessionProvider).entryRoute);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Onboarding failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      // Wider than the sign-in cards: this is a comfortable one-time setup, not
      // a challenge to get past.
      maxWidth: 600,
      // The aside already carries the mark on wide screens, and on a phone the
      // logo the user is about to upload sits right below.
      showBrand: _step == 0,
      // Four steps is enough that "which one am I on, and what is left" stops
      // being obvious from a progress bar alone.
      aside: AuthAside.steps(steps: _steps, current: _step),
      title: switch (_step) {
        0 => 'Tell us about your business',
        1 => 'Where do you trade?',
        2 => 'A few preferences',
        _ => 'Who else works here?',
      },
      subtitle: switch (_step) {
        0 => 'This appears on receipts and across the app',
        1 => 'You can add more locations later',
        2 => 'All of these can be changed in Settings',
        _ => 'They will get an invite to set up their own PIN',
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          StepBar(step: _step, count: _stepCount),
          const SizedBox(height: Insets.xl),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: switch (_step) {
              0 => _buildBasics(),
              1 => _buildStore(),
              2 => _buildPreferences(),
              _ => _buildTeam(),
            },
          ),
          const SizedBox(height: Insets.xxl),
          Row(
            children: [
              if (_step > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    key: OnboardingKeys.back,
                    onPressed: _back,
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: Insets.md),
              ],
              Expanded(
                child: FilledButton(
                  key: OnboardingKeys.next,
                  onPressed: _canContinue ? _next : null,
                  child: Text(_continueLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The last step's button says what it will do — "Finish setup" when there
  /// is nobody to invite, and how many invites it is about to send when there
  /// is. A button that hides a side effect is a button people learn to distrust.
  String get _continueLabel {
    if (_step < _stepCount - 1) return 'Continue';

    final count = _team.where((member) => member.isComplete).length;
    return switch (count) {
      0 => 'Finish setup',
      1 => 'Send 1 invite & finish',
      _ => 'Send $count invites & finish',
    };
  }

  // ---------------------------------------------------------------------
  // Steps
  // ---------------------------------------------------------------------

  Widget _buildBasics() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: ImageUploadField(
            image: _logoBytes,
            size: 120,
            label: 'Add logo',
            hint: '',
            onPicked: (name, bytes) => setState(() {
              _logoName = name;
              _logoBytes = bytes;
            }),
            onRemoved: () => setState(() {
              _logoName = null;
              _logoBytes = null;
            }),
          ),
        ),
        const SizedBox(height: Insets.xl),
        LabeledFormField(
          label: 'Business name',
          isRequired: true,
          child: TextField(
            key: OnboardingKeys.businessName,
            controller: _businessName,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'The Copper Fig'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: Insets.lg),
        LabeledFormField(
          label: 'Business type',
          child: DropdownButtonFormField<BusinessType>(
            key: OnboardingKeys.businessType,
            initialValue: _businessType,
            isExpanded: true,
            items: [
              for (final type in BusinessType.values)
                DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(type.icon, size: 17),
                      const SizedBox(width: Insets.sm),
                      Flexible(
                        child: Text(
                          type.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _businessType = value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStore() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LabeledFormField(
          label: 'Location name',
          isRequired: true,
          helper: 'What staff call this site',
          child: TextField(
            key: OnboardingKeys.locationName,
            controller: _locationName,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Riverside'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: Insets.lg),
        LabeledFormField(
          label: 'Address',
          child: TextField(
            key: OnboardingKeys.address,
            controller: _address,
            maxLines: 2,
            minLines: 2,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: '84 Riverside Walk, San Francisco',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Radii.md),
                borderSide: BorderSide(color: context.semantic.hairline),
              ),
            ),
          ),
        ),
        const SizedBox(height: Insets.lg),
        LabeledFormField(
          label: 'Phone',
          child: TextField(
            key: OnboardingKeys.phone,
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: '+1 415 555 0100'),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferences() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LabeledFormField(
          label: 'Currency',
          helper: 'Formats every amount in the app',
          child: DropdownButtonFormField<Currency>(
            key: OnboardingKeys.currency,
            initialValue: _currency,
            isExpanded: true,
            items: [
              for (final currency in Currency.values)
                DropdownMenuItem(
                  value: currency,
                  child: Text(
                    '${currency.description} (${currency.label})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _currency = value);
            },
          ),
        ),
        const SizedBox(height: Insets.lg),
        LabeledFormField(
          label: 'Tax rate',
          isRequired: true,
          helper: 'Applied to every ticket. '
              'Prices will read as ${Fmt.moneyIn(_currency, _currency == Currency.idr ? 48000 : 48)}',
          child: TextField(
            key: OnboardingKeys.taxRate,
            controller: _taxRate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              hintText: '8.25',
              suffixText: '%',
              errorText: _taxRate.text.trim().isEmpty || _parsedRate != null
                  ? null
                  : 'Enter a rate between 0 and 100',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: Insets.lg),
        LabeledFormField(
          label: 'Default order type',
          child: DropdownButtonFormField<OrderType>(
            key: OnboardingKeys.orderType,
            initialValue: _orderType,
            isExpanded: true,
            items: [
              for (final type in OrderType.values)
                DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(type.icon, size: 17),
                      const SizedBox(width: Insets.sm),
                      Flexible(
                        child: Text(
                          type.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _orderType = value);
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Step 4 — team
  // ---------------------------------------------------------------------

  Widget _buildTeam() {
    final roles = ref.watch(rolesProvider);

    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _team.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == _team.length - 1 ? 0 : Insets.lg,
            ),
            child: _TeammateRow(
              index: i,
              member: _team[i],
              roles: roles,
              // The first row is the one people type into without thinking;
              // leaving it un-removable keeps the step from emptying itself.
              onRemove: _team.length == 1 ? null : () => _removeTeammate(i),
              onChanged: () => setState(() {}),
            ),
          ),
        const SizedBox(height: Insets.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: OnboardingKeys.addTeammate,
            onPressed: _addTeammate,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add another'),
          ),
        ),
        const SizedBox(height: Insets.sm),
        _SkipHint(visible: _team.every((member) => !member.isComplete)),
      ],
    );
  }

  void _addTeammate() {
    setState(() => _team.add(_Teammate(roleId: _defaultRoleId)));
  }

  void _removeTeammate(int index) {
    setState(() => _team.removeAt(index).dispose());
  }
}

/// One invitee: who they are, and what they may do.
class _TeammateRow extends StatelessWidget {
  const _TeammateRow({
    required this.index,
    required this.member,
    required this.roles,
    required this.onRemove,
    required this.onChanged,
  });

  final int index;
  final _Teammate member;
  final List<BusinessRole> roles;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: Radii.card,
        border: Border.all(color: context.semantic.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Teammate ${index + 1}',
                  style: context.text.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    letterSpacing: 0.9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onRemove case final remove?)
                IconButton(
                  key: OnboardingKeys.removeTeammate(index),
                  onPressed: remove,
                  tooltip: 'Remove',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: Insets.md),
          // Name and email sit side by side wherever the card is wide enough
          // and stack where it is not — the same pairing the Staff forms use.
          FieldPair(
            left: LabeledFormField(
              label: 'Name',
              child: TextField(
                key: OnboardingKeys.teammateName(index),
                controller: member.name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Marco Rossi'),
                onChanged: (_) => onChanged(),
              ),
            ),
            right: LabeledFormField(
              label: 'Email',
              child: TextField(
                key: OnboardingKeys.teammateEmail(index),
                controller: member.email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'marco@venue.com'),
                onChanged: (_) => onChanged(),
              ),
            ),
          ),
          const SizedBox(height: Insets.lg),
          LabeledFormField(
            label: 'Role',
            helper: 'Sets what they can reach on the till',
            child: DropdownButtonFormField<String>(
              initialValue: member.roleId,
              isExpanded: true,
              items: [
                for (final role in roles)
                  DropdownMenuItem(
                    value: role.id,
                    child: Text(
                      role.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                member.roleId = value;
                onChanged();
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Says the step is optional, but only while it still is.
///
/// Once a name has been typed the hint would be telling someone they can
/// discard work they just did, which is not reassurance.
class _SkipHint extends StatelessWidget {
  const _SkipHint({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 180),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: context.colors.onSurfaceVariant,
          ),
          const SizedBox(width: Insets.sm - 2),
          Flexible(
            child: Text(
              'No rush — you can invite people from Staff later.',
              style: context.text.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
