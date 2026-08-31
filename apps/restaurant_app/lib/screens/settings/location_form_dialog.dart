import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dio/dio.dart';

import '../../models/staff_member.dart';
import '../../models/store_location.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_provider.dart';
import '../../providers/store_api_provider_real.dart';
import '../../providers/store_locations_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/field_pair.dart';
import '../../widgets/labeled_form_field.dart';
import '../../widgets/responsive_form_dialog.dart';
import 'store_settings_screen.dart' show SettingSwitchTile;

abstract final class LocationFormKeys {
  static const name = Key('locationForm.name');
  static const locationType = Key('locationForm.locationType');
  static const address = Key('locationForm.address');
  static const phone = Key('locationForm.phone');
  static const manager = Key('locationForm.manager');
  static const staffCount = Key('locationForm.staffCount');
  static const active = Key('locationForm.active');
  static const submit = Key('locationForm.submit');
  static const cancel = Key('locationForm.cancel');
}

/// Opens the add/edit form. Passing [existing] pre-fills it; omitting it
/// creates a new site.
///
/// One dialog for both, because "add a location" and "correct a location's
/// phone number" are the same six fields — a separate detail screen for an
/// entity this small would be a page with nothing on it.
Future<void> showLocationFormDialog(
  BuildContext context, {
  StoreLocation? existing,
}) {
  return showResponsiveFormDialog<void>(
    context,
    builder: (_) => LocationFormDialog(existing: existing),
  );
}

class LocationFormDialog extends ConsumerStatefulWidget {
  const LocationFormDialog({super.key, this.existing});

  final StoreLocation? existing;

  @override
  ConsumerState<LocationFormDialog> createState() => _LocationFormDialogState();
}

class _LocationFormDialogState extends ConsumerState<LocationFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _staffCount = TextEditingController();

  late LocationType _locationType;
  String? _managerId;
  bool _isActive = true;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _locationType = existing?.locationType ?? LocationType.restaurantBranch;
    if (existing == null) {
      _staffCount.text = '0';
      return;
    }

    _name.text = existing.name;
    _address.text = existing.address ?? '';
    _phone.text = existing.phone ?? '';
    _staffCount.text = '${existing.staffCount}';
    _managerId = existing.managerId;
    _isActive = existing.isActive;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _staffCount.dispose();
    super.dispose();
  }

  /// The current site cannot be switched off from the terminal standing in it,
  /// and neither can the last one still trading.
  bool get _canDeactivate {
    final existing = widget.existing;
    // A site that does not exist yet cannot be the last one trading.
    if (existing == null) return true;
    if (existing.isCurrent) return false;
    return ref.read(storeLocationsProvider.notifier).canDeactivate(existing.id);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;

    setState(() => _saving = true);

    try {
      final auth = ref.read(authProvider);
      final businessId = auth.selectedBusinessId;
      if (businessId == null) {
        throw Exception('No business context available');
      }

      final storeApi = ref.read(storeApiServiceProvider);
      final existing = widget.existing;

      final locationName = _name.text.trim();
      final phone = _phone.text.trim();

      final result;
      if (existing == null) { // ignore: prefer_const_constructors
        // Create new store
        result = await storeApi.createStore(
          businessId: businessId,
          name: locationName,
          locationType: _locationType.backendValue,
          address: _address.text.trim().isEmpty ? null : _address.text.trim(),
          status: _isActive ? 'active' : 'inactive',
        );
      } else {
        // Update existing store
        result = await storeApi.updateStore(
          businessId: businessId,
          storeId: existing.id,
          name: locationName,
          locationType: _locationType.backendValue,
          address: _address.text.trim().isEmpty ? null : _address.text.trim(),
          status: (existing.isCurrent || _isActive) ? 'active' : 'inactive',
        );
      }

      // Update store settings (phone lives on StoreSetting, not Store)
      if (phone.isNotEmpty) {
        await storeApi.updateStoreSettings(
          businessId: businessId,
          storeId: result.id,
          phone: phone,
        );
      }

      // Refresh stores list
      await refreshStores(ref);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? '$locationName updated'
                  : '$locationName added — it can now receive stock transfers',
            ),
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.response?.data?['detail']?.toString() ?? 'Could not save location',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(staffMembersProvider).valueOrNull ?? const [];
    final isCurrent = widget.existing?.isCurrent ?? false;

    return ResponsiveFormDialog(
      title: _isEdit ? 'Edit location' : 'Add location',
      width: 520,
      actions: [
        OutlinedButton(
          key: LocationFormKeys.cancel,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: LocationFormKeys.submit,
          onPressed: _submit,
          child: Text(_isEdit ? 'Save location' : 'Add location'),
        ),
      ],
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LabeledFormField(
              label: 'Location name',
              isRequired: true,
              child: TextFormField(
                key: LocationFormKeys.name,
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Harbour Point'),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return 'Give the location a name';
                  return _isNameTaken(text) ? 'That name is already used' : null;
                },
              ),
            ),
            const SizedBox(height: Insets.lg),
            LabeledFormField(
              label: 'Location type',
              child: DropdownButtonFormField<LocationType>(
                key: LocationFormKeys.locationType,
                initialValue: _locationType,
                isExpanded: true,
                items: [
                  for (final type in LocationType.values)
                    DropdownMenuItem(
                      value: type,
                      child: Text(
                        type.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _locationType = value);
                },
              ),
            ),
            const SizedBox(height: Insets.lg),

            LabeledFormField(
              label: 'Address',
              child: TextFormField(
                key: LocationFormKeys.address,
                controller: _address,
                maxLines: 2,
                minLines: 2,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: '12 Pier Road, San Francisco',
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
            const SizedBox(height: Insets.lg),

            FieldPair(
              stackBelow: 340,
              left: LabeledFormField(
                label: 'Phone',
                child: TextFormField(
                  key: LocationFormKeys.phone,
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '+1 415 555 0142',
                  ),
                ),
              ),
              right: LabeledFormField(
                label: 'Staff based here',
                child: TextFormField(
                  key: LocationFormKeys.staffCount,
                  controller: _staffCount,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: const InputDecoration(hintText: '0'),
                ),
              ),
            ),
            const SizedBox(height: Insets.lg),

            LabeledFormField(
              label: 'Manager',
              helper: 'Anyone on the staff list can run a site',
              child: DropdownButtonFormField<String?>(
                key: LocationFormKeys.manager,
                initialValue: _managerId,
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String?>(
                    child: Text(StoreLocation.unassignedManager),
                  ),
                  for (final member in staff)
                    DropdownMenuItem<String?>(
                      value: member.id,
                      child: Text(
                        _managerLabel(member),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _managerId = value),
              ),
            ),
            const SizedBox(height: Insets.lg),

            SettingSwitchTile(
              switchKey: LocationFormKeys.active,
              title: 'Active',
              subtitle: isCurrent
                  ? 'This terminal is installed here, so it always trades'
                  : _isActive
                  ? 'Trading, and offered as a stock transfer destination'
                  : 'Kept for history; offered nowhere',
              value: isCurrent ? true : _isActive,
              onChanged: (value) {
                if (isCurrent) return;
                if (!value && !_canDeactivate) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'At least one location has to stay active',
                      ),
                    ),
                  );
                  return;
                }
                setState(() => _isActive = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Two sites with the same name would be indistinguishable in the transfer
  /// dropdown, which is the whole point of the name.
  bool _isNameTaken(String candidate) {
    final lower = candidate.toLowerCase();
    for (final location in ref.read(storeLocationsProvider)) {
      if (location.id == widget.existing?.id) continue;
      if (location.name.toLowerCase() == lower) return true;
    }
    return false;
  }

  String _managerLabel(StaffMember member) =>
      member.isPending ? '${member.name} (invite pending)' : member.name;
}
