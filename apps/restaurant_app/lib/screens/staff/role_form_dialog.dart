import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/business_role.dart';
import '../../models/permission.dart';
import '../../providers/roles_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/labeled_form_field.dart';
import '../../widgets/responsive_form_dialog.dart';
import '../../widgets/section_label.dart';

/// Opens the role form. Pass [existingRole] to edit, omit it to create.
Future<void> showRoleFormDialog(
  BuildContext context, {
  BusinessRole? existingRole,
}) {
  return showResponsiveFormDialog<void>(
    context,
    builder: (_) => RoleFormDialog(roleId: existingRole?.id),
  );
}

class RoleFormDialog extends ConsumerStatefulWidget {
  const RoleFormDialog({super.key, this.roleId});

  /// Id of the role being edited, or null to create one.
  final String? roleId;

  /// Wider than any other dialog in the app, because this one has to fit a
  /// permission matrix. Two columns of toggles at 460px would be unreadable and
  /// one column would be a scroll of eighteen rows.
  static const double dialogWidth = 740;

  /// Below this the matrix drops to a single column. Two columns need roughly
  /// 300px each plus the gutter before a permission label starts wrapping.
  static const double _twoColumnMin = 640;

  @override
  ConsumerState<RoleFormDialog> createState() => _RoleFormDialogState();
}

class _RoleFormDialogState extends ConsumerState<RoleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();

  /// The working copy. Edits are held here and only written to the provider on
  /// save, so cancelling a half-made change to a live role leaves every staff
  /// badge exactly as it was.
  late Set<String> _selected;

  /// Which groups are open. All of them on a wide screen, none on a phone —
  /// eighteen expanded toggles is not a form anyone can navigate on mobile.
  late Set<String> _expanded;

  BusinessRole? _existing;
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;

    final role = widget.roleId == null
        ? null
        : ref.read(roleByIdProvider(widget.roleId!));

    _existing = role;
    _name.text = role?.name ?? '';
    _description.text = role?.description ?? '';
    _selected = Set.of(role?.permissionIds ?? const <String>{});

    final isMobile = MediaQuery.sizeOf(context).width < Breakpoints.tablet;
    _expanded = isMobile
        ? <String>{}
        : {for (final group in AppPermissions.groups) group.id};
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  bool get _isEdit => _existing != null;

  /// A built-in role's identity is referenced by staff records and reporting,
  /// so its name and description are fixed — but what it *can do* is still the
  /// business's decision, so the matrix stays live.
  bool get _isSystem => _existing?.isSystem ?? false;

  bool get _canSave =>
      _name.text.trim().isNotEmpty && _selected.isNotEmpty;

  void _toggle(String permissionId, bool on) {
    setState(() {
      on ? _selected.add(permissionId) : _selected.remove(permissionId);
    });
  }

  void _setGroup(PermissionGroup group, {required bool on}) {
    setState(() {
      on
          ? _selected.addAll(group.permissionIds)
          : _selected.removeAll(group.permissionIds);
    });
  }

  void _toggleExpanded(String groupId) {
    setState(() {
      _expanded.contains(groupId)
          ? _expanded.remove(groupId)
          : _expanded.add(groupId);
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(rolesProvider.notifier);
    final existing = _existing;

    final role = existing != null
        ? existing.copyWith(
            // A system role keeps its stored name and description whatever the
            // disabled fields happen to contain.
            name: _isSystem ? existing.name : _name.text.trim(),
            description:
                _isSystem ? existing.description : _description.text.trim(),
            permissionIds: _selected,
          )
        : BusinessRole(
            id: notifier.nextId(),
            name: _name.text.trim(),
            description: _description.text.trim(),
            permissionIds: _selected,
          );

    notifier.upsert(role);

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          _isEdit ? '"${role.name}" updated' : '"${role.name}" created',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ResponsiveFormDialog(
        title: _isEdit ? 'Edit role' : 'Create role',
        width: RoleFormDialog.dialogWidth,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _canSave ? _save : null,
            child: Text(_isEdit ? 'Save role' : 'Create role'),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionLabel('Basic info'),
            const SizedBox(height: Insets.md),

            if (_isSystem) ...[
              const _SystemRoleNotice(),
              const SizedBox(height: Insets.lg),
            ],

            LabeledFormField(
              label: 'Role name',
              isRequired: true,
              enabled: !_isSystem,
              child: TextFormField(
                controller: _name,
                enabled: !_isSystem,
                autofocus: !_isSystem,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'e.g. Shift supervisor',
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Give the role a name'
                    : null,
              ),
            ),
            const SizedBox(height: Insets.lg),

            LabeledFormField(
              label: 'Description',
              enabled: !_isSystem,
              helper: 'One line on what this role is for',
              child: TextFormField(
                controller: _description,
                enabled: !_isSystem,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Runs the floor when a manager is off',
                ),
              ),
            ),

            const SizedBox(height: Insets.xl),
            _PermissionsHeader(
              selectedCount: _selected.length,
              onSelectAll: () => setState(
                () => _selected = {for (final p in AppPermissions.all) p.id},
              ),
              onClearAll: () => setState(_selected.clear),
            ),
            const SizedBox(height: Insets.md),

            _PermissionMatrix(
              selected: _selected,
              expanded: _expanded,
              onToggle: _toggle,
              onToggleGroup: _setGroup,
              onToggleExpanded: _toggleExpanded,
            ),

            if (_selected.isEmpty) ...[
              const SizedBox(height: Insets.md),
              Text(
                'Pick at least one permission — a role that grants nothing '
                'cannot be assigned usefully.',
                style: context.text.bodySmall?.copyWith(
                  color: context.semantic.warning,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SystemRoleNotice extends StatelessWidget {
  const _SystemRoleNotice();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.45),
        borderRadius: Radii.card,
        border: Border.all(color: context.semantic.hairline),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, size: 17, color: colors.primary),
          const SizedBox(width: Insets.md - 2),
          Expanded(
            child: Text(
              'Built-in roles keep their name and description. You can still '
              'change what this role is allowed to do.',
              style: context.text.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionsHeader extends StatelessWidget {
  const _PermissionsHeader({
    required this.selectedCount,
    required this.onSelectAll,
    required this.onClearAll,
  });

  final int selectedCount;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final label = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SectionLabel('Permissions'),
            const SizedBox(height: 2),
            Text(
              '$selectedCount of ${AppPermissions.count} selected',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        );

        final buttons = Wrap(
          spacing: Insets.xs,
          children: [
            TextButton(onPressed: onSelectAll, child: const Text('Select all')),
            TextButton(onPressed: onClearAll, child: const Text('Clear all')),
          ],
        );

        if (constraints.maxWidth < 340) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [label, buttons],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [Expanded(child: label), buttons],
        );
      },
    );
  }
}

/// The permission groups, laid out in two columns where there is room.
///
/// Not a true masonry: the groups are dealt alternately into two columns, which
/// keeps related permissions together and costs nothing in layout passes. A
/// real masonry would balance the columns' heights better and be considerably
/// more machinery than five collapsible cards justify.
class _PermissionMatrix extends StatelessWidget {
  const _PermissionMatrix({
    required this.selected,
    required this.expanded,
    required this.onToggle,
    required this.onToggleGroup,
    required this.onToggleExpanded,
  });

  final Set<String> selected;
  final Set<String> expanded;
  final void Function(String permissionId, bool on) onToggle;
  final void Function(PermissionGroup group, {required bool on}) onToggleGroup;
  final ValueChanged<String> onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final groups = AppPermissions.groups;

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumn =
            constraints.maxWidth >= RoleFormDialog._twoColumnMin;

        if (!twoColumn) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < groups.length; i++) ...[
                if (i > 0) const SizedBox(height: Insets.md),
                _buildGroup(groups[i]),
              ],
            ],
          );
        }

        final left = <PermissionGroup>[];
        final right = <PermissionGroup>[];
        for (var i = 0; i < groups.length; i++) {
          (i.isEven ? left : right).add(groups[i]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _columnOf(left)),
            const SizedBox(width: Insets.md),
            Expanded(child: _columnOf(right)),
          ],
        );
      },
    );
  }

  Widget _columnOf(List<PermissionGroup> groups) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < groups.length; i++) ...[
        if (i > 0) const SizedBox(height: Insets.md),
        _buildGroup(groups[i]),
      ],
    ],
  );

  Widget _buildGroup(PermissionGroup group) => _PermissionGroupCard(
    group: group,
    selected: selected,
    expanded: expanded.contains(group.id),
    onToggle: onToggle,
    onToggleGroup: onToggleGroup,
    onToggleExpanded: () => onToggleExpanded(group.id),
  );
}

class _PermissionGroupCard extends StatelessWidget {
  const _PermissionGroupCard({
    required this.group,
    required this.selected,
    required this.expanded,
    required this.onToggle,
    required this.onToggleGroup,
    required this.onToggleExpanded,
  });

  final PermissionGroup group;
  final Set<String> selected;
  final bool expanded;
  final void Function(String permissionId, bool on) onToggle;
  final void Function(PermissionGroup group, {required bool on}) onToggleGroup;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ids = group.permissionIds;
    final on = ids.where(selected.contains).length;
    final all = on == ids.length;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: Radii.card,
        border: Border.all(
          color: on > 0
              ? colors.primary.withValues(alpha: 0.35)
              : context.semantic.hairline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onToggleExpanded,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.md,
                Insets.md,
                Insets.sm,
                Insets.md,
              ),
              child: Row(
                children: [
                  Icon(group.icon, size: 18, color: colors.primary),
                  const SizedBox(width: Insets.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          group.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleSmall,
                        ),
                        Text(
                          '$on of ${ids.length}',
                          maxLines: 1,
                          style: context.text.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Per-group bulk action, labelled by what it will do next
                  // rather than by the group's current state.
                  TextButton(
                    onPressed: () => onToggleGroup(group, on: !all),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Insets.sm,
                      ),
                      minimumSize: const Size(0, 36),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(all ? 'Clear' : 'All'),
                  ),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            for (final permission in group.permissions)
              _PermissionRow(
                permission: permission,
                value: selected.contains(permission.id),
                onChanged: (on) => onToggle(permission.id, on),
              ),
          ],
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.permission,
    required this.value,
    required this.onChanged,
  });

  final Permission permission;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Insets.md,
          Insets.sm,
          Insets.md,
          Insets.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A checkbox rather than a switch: a matrix of eighteen switches
            // reads as eighteen separate settings, where checkboxes read as one
            // list being ticked off.
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    permission.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyMedium?.copyWith(
                      fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    permission.description,
                    maxLines: 2,
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
      ),
    );
  }
}
