import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/business_role.dart';
import '../../models/permission.dart';
import '../../models/staff_member.dart';
import '../../providers/roles_provider.dart';
import '../../providers/staff_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/labeled_form_field.dart';
import '../../widgets/responsive_form_dialog.dart';
import '../../widgets/staff/role_badge.dart';

/// Opens the invite form.
Future<void> showInviteStaffDialog(BuildContext context) {
  return showResponsiveFormDialog<void>(
    context,
    builder: (_) => const InviteStaffDialog(),
  );
}

/// Opens a small dialog for reassigning one member's role.
///
/// Shares the role picker and its permission preview with the invite form, so
/// the two never describe the same role differently.
Future<void> showChangeRoleDialog(BuildContext context, StaffMember member) {
  return showResponsiveFormDialog<void>(
    context,
    builder: (_) => ChangeRoleDialog(member: member),
  );
}

class InviteStaffDialog extends ConsumerStatefulWidget {
  const InviteStaffDialog({super.key});

  @override
  ConsumerState<InviteStaffDialog> createState() => _InviteStaffDialogState();
}

class _InviteStaffDialogState extends ConsumerState<InviteStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();

  String? _roleId;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      validateName(_name.text) == null &&
      validateEmail(_email.text) == null &&
      _roleId != null;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final member = ref
        .read(staffMembersProvider.notifier)
        .invite(
          name: _name.text,
          email: _email.text,
          phone: _phone.text,
          roleId: _roleId!,
          note: _note.text,
        );

    // Captured before the pop — this dialog's context is defunct afterwards.
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    messenger.showSnackBar(
      SnackBar(content: Text('Invite sent to ${member.email}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roles = ref.watch(rolesProvider);

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ResponsiveFormDialog(
        title: 'Invite staff',
        width: 520,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _canSubmit ? _submit : null,
            child: const Text('Send invite'),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LabeledFormField(
              label: 'Full name',
              isRequired: true,
              child: TextFormField(
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'e.g. Tomas Alvarez'),
                onChanged: (_) => setState(() {}),
                validator: validateName,
              ),
            ),
            const SizedBox(height: Insets.lg),

            LabeledFormField(
              label: 'Email',
              isRequired: true,
              helper: 'The invite link goes here',
              child: TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'name@example.com'),
                onChanged: (_) => setState(() {}),
                validator: validateEmail,
              ),
            ),
            const SizedBox(height: Insets.lg),

            LabeledFormField(
              label: 'Phone',
              helper: 'Optional',
              child: TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: '+1 415 555 0100'),
              ),
            ),
            const SizedBox(height: Insets.lg),

            RolePickerField(
              roles: roles,
              value: _roleId,
              onChanged: (value) => setState(() => _roleId = value),
            ),
            const SizedBox(height: Insets.lg),

            LabeledFormField(
              label: 'Personal message',
              helper: 'Optional — included in the invite email',
              child: TextFormField(
                controller: _note,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Welcome aboard — first shift is Thursday at 4pm.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                    borderSide: BorderSide(color: context.semantic.hairline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                    borderSide: BorderSide(
                      color: context.colors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChangeRoleDialog extends ConsumerStatefulWidget {
  const ChangeRoleDialog({super.key, required this.member});

  final StaffMember member;

  @override
  ConsumerState<ChangeRoleDialog> createState() => _ChangeRoleDialogState();
}

class _ChangeRoleDialogState extends ConsumerState<ChangeRoleDialog> {
  late String _roleId = widget.member.roleId;

  @override
  Widget build(BuildContext context) {
    final roles = ref.watch(rolesProvider);
    final changed = _roleId != widget.member.roleId;

    return ResponsiveFormDialog(
      title: 'Change role',
      width: 480,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: changed ? _submit : null,
          child: const Text('Save role'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.member.name,
            style: context.text.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            widget.member.email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Insets.xl),
          RolePickerField(
            roles: roles,
            value: _roleId,
            onChanged: (value) => setState(() => _roleId = value ?? _roleId),
          ),
        ],
      ),
    );
  }

  void _submit() {
    ref.read(staffMembersProvider.notifier).setRole(widget.member.id, _roleId);

    final roleName = ref.read(roleByIdProvider(_roleId))?.name ?? 'their role';
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    messenger.showSnackBar(
      SnackBar(content: Text('${widget.member.name} is now $roleName')),
    );
  }
}

/// A role dropdown with a live preview of what that role can do.
///
/// The preview reads the same [rolesProvider] the Role Form writes to, so a
/// permission granted there shows up here without either screen knowing about
/// the other.
class RolePickerField extends StatelessWidget {
  const RolePickerField({
    super.key,
    required this.roles,
    required this.value,
    required this.onChanged,
  });

  final List<BusinessRole> roles;
  final String? value;
  final ValueChanged<String?> onChanged;

  /// How many permissions to name before summarising the rest. Three is enough
  /// to characterise a role without turning the dialog into a permission
  /// matrix of its own.
  static const int _previewCount = 3;

  @override
  Widget build(BuildContext context) {
    final selected = roles.where((role) => role.id == value).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LabeledFormField(
          label: 'Role',
          isRequired: true,
          child: DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            hint: const Text('Select a role'),
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
            onChanged: onChanged,
            validator: (v) => v == null ? 'Pick a role' : null,
          ),
        ),
        if (selected != null) ...[
          const SizedBox(height: Insets.md),
          _RolePreview(role: selected),
        ],
      ],
    );
  }
}

class _RolePreview extends StatelessWidget {
  const _RolePreview({required this.role});

  final BusinessRole role;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final granted = AppPermissions.resolve(role.permissionIds);
    final shown = granted.take(RolePickerField._previewCount).toList();
    final extra = granted.length - shown.length;

    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: Radii.card,
        border: Border.all(color: context.semantic.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              RoleBadge(role: role, dense: true),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: Text(
                  role.permissionSummary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: context.text.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          Text(
            role.description,
            style: context.text.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (granted.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Insets.sm),
              child: Text(
                'This role grants no permissions yet.',
                style: context.text.bodySmall?.copyWith(
                  color: context.semantic.warning,
                ),
              ),
            )
          else ...[
            const SizedBox(height: Insets.sm),
            Wrap(
              spacing: Insets.xs + 2,
              runSpacing: Insets.xs + 2,
              children: [
                for (final id in shown)
                  _PermissionChip(label: AppPermissions.labelFor(id)),
                if (extra > 0) _PermissionChip(label: '+$extra more'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PermissionChip extends StatelessWidget {
  const _PermissionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.sm, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: context.semantic.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 12, color: colors.primary),
          const SizedBox(width: Insets.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Validation
//
// Static and pure so the field validators and the Send button's enabled state
// answer the same question — the pattern the item form established.
// ---------------------------------------------------------------------------

String? validateName(String? value) =>
    (value ?? '').trim().isEmpty ? 'Enter their full name' : null;

String? validateEmail(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return 'Enter an email address';
  // Deliberately loose: the point is to catch a typo, not to adjudicate RFC
  // 5322. A real invite is validated by whether the mail arrives.
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
    return 'Enter a valid email address';
  }
  return null;
}
