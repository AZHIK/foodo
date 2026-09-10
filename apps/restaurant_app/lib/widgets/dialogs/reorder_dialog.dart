import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/inventory_item.dart';
import '../../models/permission.dart';
import '../../models/supplier.dart';
import '../../providers/permissions_provider.dart';
import '../../providers/reorder_provider.dart';
import '../../providers/suppliers_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../labeled_form_field.dart';
import '../responsive_form_dialog.dart';
import '../section_label.dart';
import 'supplier_form_dialog.dart' show showSupplierFormDialog;

/// Opens the reorder creation dialog for an inventory item.
Future<void> showReorderDialog(
  BuildContext context,
  InventoryItem item,
) {
  return showResponsiveFormDialog<void>(
    context,
    builder: (_) => _ReorderDialog(item: item),
  );
}

class _ReorderDialog extends ConsumerStatefulWidget {
  const _ReorderDialog({required this.item});

  final InventoryItem item;

  @override
  ConsumerState<_ReorderDialog> createState() => _ReorderDialogState();
}

class _ReorderDialogState extends ConsumerState<_ReorderDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantity;
  late final TextEditingController _unitCost;
  late final TextEditingController _expectedDays;
  late final TextEditingController _notes;
  String? _supplierId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _quantity = TextEditingController(text: Fmt.quantity(widget.item.reorderLevel));
    _unitCost = TextEditingController(text: '${widget.item.unitCost}');
    _expectedDays = TextEditingController(text: '7');
    _notes = TextEditingController();
  }

  @override
  void dispose() {
    _quantity.dispose();
    _unitCost.dispose();
    _expectedDays.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickSupplier() async {
    final selected = await _showSupplierPickerDialog(context, ref);
    if (selected != null) setState(() => _supplierId = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_supplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a supplier')),
      );
      return;
    }

    final quantity = double.tryParse(_quantity.text.trim()) ?? 0;
    final unitCost = double.tryParse(_unitCost.text.trim()) ?? 0;
    final expectedDays = int.tryParse(_expectedDays.text.trim()) ?? 7;

    setState(() => _saving = true);
    try {
      await ref.read(reordersProvider.notifier).create(
            itemId: widget.item.catalogItemId ?? widget.item.id,
            supplierId: _supplierId!,
            quantity: quantity,
            unit: widget.item.unit,
            unitCost: unitCost,
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            expectedAt: DateTime.now().add(Duration(days: expectedDays)),
          );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Reorder created: ${Fmt.quantity(quantity)} ${widget.item.unit} '
            'of ${widget.item.name}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final supplier =
        _supplierId == null ? null : ref.watch(supplierByIdProvider(_supplierId!));

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ResponsiveFormDialog(
        title: 'Create reorder for ${widget.item.name}',
        actions: [
          OutlinedButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create reorder'),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionLabel('Reorder details'),
            const SizedBox(height: Insets.md),
            LabeledFormField(
              label: 'Current stock',
              child: Container(
                padding: const EdgeInsets.all(Insets.md),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerLowest,
                  border: Border.all(color: context.semantic.hairline),
                  borderRadius: BorderRadius.circular(Insets.md),
                ),
                child: Text(
                  '${Fmt.quantity(widget.item.stock)} ${widget.item.unit}',
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Insets.lg),
            LabeledFormField(
              label: 'Supplier',
              isRequired: true,
              child: supplier == null
                  ? OutlinedButton.icon(
                      onPressed: _pickSupplier,
                      icon: const Icon(Icons.storefront_outlined, size: 18),
                      label: const Text('Select supplier'),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Insets.lg,
                        vertical: Insets.md,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(Insets.md),
                        border: Border.all(color: context.semantic.hairline),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              supplier.name,
                              style: context.text.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton(
                            onPressed: _pickSupplier,
                            child: const Text('Change'),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: Insets.lg),
            LabeledFormField(
              label: 'Quantity to order',
              isRequired: true,
              child: TextFormField(
                controller: _quantity,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: Fmt.quantity(widget.item.reorderLevel),
                  suffixText: widget.item.unit,
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) return 'Enter quantity';
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null) return 'Enter a number';
                  if (parsed <= 0) return 'Enter a positive number';
                  return null;
                },
              ),
            ),
            const SizedBox(height: Insets.lg),
            LabeledFormField(
              label: 'Unit cost',
              isRequired: true,
              child: TextFormField(
                controller: _unitCost,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: Fmt.money(widget.item.unitCost),
                  prefixText: Fmt.currencySymbol,
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) return 'Enter unit cost';
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null) return 'Enter a number';
                  if (parsed < 0) return 'Enter a non-negative number';
                  return null;
                },
              ),
            ),
            const SizedBox(height: Insets.lg),
            LabeledFormField(
              label: 'Expected delivery (days)',
              child: TextFormField(
                controller: _expectedDays,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: '7',
                  suffixText: 'days',
                ),
                validator: (value) {
                  if (value?.trim().isNotEmpty ?? false) {
                    if (int.tryParse(value?.trim() ?? '') == null) {
                      return 'Enter a whole number';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: Insets.lg),
            LabeledFormField(
              label: 'Notes (optional)',
              child: TextFormField(
                controller: _notes,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Special requests or notes for supplier...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Insets.md),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Insets.md),
                    borderSide: BorderSide(color: context.semantic.hairline),
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

/// Search/select a supplier for a reorder, with an "+ Add new supplier"
/// entry when permitted. Mirrors `customer_picker.dart`'s shape, minus the
/// "no supplier" clear option — a reorder always has exactly one supplier.
Future<String?> _showSupplierPickerDialog(BuildContext context, WidgetRef ref) {
  final form = context.formFactor;
  final available = MediaQuery.sizeOf(context).width - 80;
  final width = math.max(240.0, math.min(480.0, available));

  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _SupplierPickerDialog(width: width, autofocus: form.isDesktop),
  );
}

class _SupplierPickerDialog extends ConsumerStatefulWidget {
  const _SupplierPickerDialog({required this.width, required this.autofocus});

  final double width;
  final bool autofocus;

  @override
  ConsumerState<_SupplierPickerDialog> createState() => _SupplierPickerDialogState();
}

class _SupplierPickerDialogState extends ConsumerState<_SupplierPickerDialog> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final allSuppliers = ref.watch(suppliersListProvider);
    final canCreate = ref.watch(hasPermissionProvider(AppPermissions.suppliersCreate));
    final query = _search.trim().toLowerCase();

    final matches = query.isEmpty
        ? allSuppliers
        : allSuppliers.where((s) => s.name.toLowerCase().contains(query)).toList();

    return AlertDialog(
      title: const Text('Select a supplier'),
      contentPadding: const EdgeInsets.fromLTRB(Insets.lg, Insets.md, Insets.lg, Insets.sm),
      content: SizedBox(
        width: widget.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              autofocus: widget.autofocus,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search suppliers',
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
            const SizedBox(height: Insets.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: matches.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: Insets.xl),
                      child: Center(
                        child: Text(
                          'No matching suppliers',
                          style: context.text.bodyMedium
                              ?.copyWith(color: context.colors.onSurfaceVariant),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final Supplier supplier = matches[index];
                        return ListTile(
                          title: Text(supplier.name),
                          subtitle: supplier.phone == null ? null : Text(supplier.phone!),
                          onTap: () => Navigator.of(context).pop(supplier.id),
                        );
                      },
                    ),
            ),
            if (canCreate) ...[
              const Divider(height: 1),
              TextButton.icon(
                onPressed: () async {
                  final created = await showSupplierFormDialog(context);
                  if (created != null && context.mounted) {
                    Navigator.of(context).pop(created.id);
                  }
                },
                icon: const Icon(Icons.add_business_outlined, size: 18),
                label: const Text('Add new supplier'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
