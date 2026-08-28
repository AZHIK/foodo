import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/identity_service_api.dart' show AuthException;
import '../../models/business_role.dart';
import '../../models/permission.dart';
import '../../models/staff_member.dart';
import '../../providers/roles_provider.dart';
import '../../providers/staff_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/phone_validation.dart';
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

/// Opens a small dialog for granting one member an additional role.
///
/// Shares the role picker and its permission preview with the invite form, so
/// the two never describe the same role differently. There is no "change"
/// here — the backend allows a staff member to hold more than one role
/// simultaneously and has no replace/revoke-in-one-call endpoint, so this
/// only ever adds; removing a role no longer wanted is a separate action
/// from the staff list ("Remove from team" revokes a specific role).
Future<void> showAddRoleDialog(BuildContext context, StaffMember member) {
  return showResponsiveFormDialog<void>(
    context,
    builder: (_) => AddRoleDialog(member: member),
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
  final _phone = TextEditingController();

  String? _roleId;
  bool _submitting = false;
  String? _submitError;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_submitting &&
      validateName(_name.text) == null &&
      isValidTanzanianPhone(_phone.text) &&
      _roleId != null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !_canSubmit) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      await ref.read(staffMembersProvider.notifier).assignRole(
            phone: '+255${_phone.text.trim()}',
            roleId: _roleId!,
          );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Invite sent to ${_name.text.trim()}')),
      );
    } on AuthException catch (e) {
      // Surfaces the backend's own message verbatim (e.g. its real 409
      // "already has this role assignment" text) rather than invented copy.
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = e.statusCode == null
            ? 'Staff management requires an internet connection.'
            : e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = 'Something went wrong sending the invite.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final roles = ref.watch(rolesProvider).valueOrNull ?? const <BusinessRole>[];

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ResponsiveFormDialog(
        title: 'Invite staff',
        width: 520,
        actions: [
          OutlinedButton(
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _canSubmit ? _submit : null,
            child: _submitting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send invite'),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_submitError != null) ...[
              Container(
                padding: const EdgeInsets.all(Insets.md),
                decoration: BoxDecoration(
                  color: context.semantic.danger.withValues(alpha: 0.1),
                  borderRadius: Radii.card,
                  border: Border.all(color: context.semantic.danger.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _submitError!,
                  style: context.text.bodySmall?.copyWith(color: context.semantic.danger),
                ),
              ),
              const SizedBox(height: Insets.lg),
            ],
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
              label: 'Phone',
              isRequired: true,
              helper: "Their invite is sent to this number — it's how the backend finds or creates their account",
              child: TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                decoration: InputDecoration(
                  hintText: '6XXXXXXXX or 7XXXXXXXX',
                  errorText: _phone.text.isEmpty || isValidTanzanianPhone(_phone.text)
                      ? null
                      : tanzanianPhoneHint,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: Insets.lg, right: Insets.sm),
                    child: Text(
                      '+255',
                      style: context.text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: Insets.lg),

            RolePickerField(
              roles: roles,
              value: _roleId,
              onChanged: (value) => setState(() => _roleId = value),
            ),
          ],
        ),
      ),
    );
  }
}

class AddRoleDialog extends ConsumerStatefulWidget {
  const AddRoleDialog({super.key, required this.member});

  final StaffMember member;

  @override
  ConsumerState<AddRoleDialog> createState() => _AddRoleDialogState();
}

class _AddRoleDialogState extends ConsumerState<AddRoleDialog> {
  String? _roleId;
  bool _submitting = false;
  String? _submitError;

  @override
  Widget build(BuildContext context) {
    final roles = ref.watch(rolesProvider).valueOrNull ?? const <BusinessRole>[];
    final heldRoleIds = {for (final r in widget.member.roles) r.roleId};
    // A role they already hold can't be granted again — the backend treats
    // that exact triple as a 409, so it's excluded here rather than left to
    // fail server-side.
    final available = [
      for (final role in roles)
        if (!heldRoleIds.contains(role.id)) role,
    ];

    return ResponsiveFormDialog(
      title: 'Add a role',
      width: 480,
      actions: [
        OutlinedButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _roleId != null && !_submitting ? _submit : null,
          child: _submitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add role'),
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
          if (widget.member.roles.isNotEmpty) ...[
            const SizedBox(height: Insets.sm),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final r in widget.member.roles)
                  RoleBadge(role: roles.where((role) => role.id == r.roleId).firstOrNull, dense: true),
              ],
            ),
          ],
          const SizedBox(height: Insets.xl),
          if (_submitError != null) ...[
            Text(
              _submitError!,
              style: context.text.bodySmall?.copyWith(color: context.semantic.danger),
            ),
            const SizedBox(height: Insets.md),
          ],
          if (available.isEmpty)
            Text(
              'They already hold every role at this business.',
              style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
            )
          else
            RolePickerField(
              roles: available,
              value: _roleId,
              onChanged: (value) => setState(() => _roleId = value),
            ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final roleId = _roleId;
    if (roleId == null) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      await ref.read(staffMembersProvider.notifier).assignRole(
            phone: widget.member.phone,
            roleId: roleId,
          );

      if (!mounted) return;
      final roleName = ref.read(roleByIdProvider(roleId))?.name ?? 'the role';
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text('${widget.member.name} now has $roleName')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = e.statusCode == null
            ? 'Staff management requires an internet connection.'
            : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = 'Something went wrong adding the role.';
      });
    }
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
