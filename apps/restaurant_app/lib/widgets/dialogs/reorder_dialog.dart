import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/inventory_item.dart';
import '../../models/reorder.dart';
import '../../providers/reorder_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../labeled_form_field.dart';
import '../responsive_form_dialog.dart';
import '../section_label.dart';

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

  @override
  void initState() {
    super.initState();
    _quantity = TextEditingController(text: '${widget.item.reorderLevel}');
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

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(reordersProvider.notifier);
    final quantity = int.tryParse(_quantity.text.trim()) ?? 0;
    final unitCost = double.tryParse(_unitCost.text.trim()) ?? 0;
    final expectedDays = int.tryParse(_expectedDays.text.trim()) ?? 7;

    final reorder = Reorder(
      id: notifier.nextId(),
      inventoryItemId: widget.item.id,
      quantity: quantity,
      unit: widget.item.unit,
      unitCost: unitCost,
      supplier: widget.item.supplier,
      orderedAt: DateTime.now(),
      expectedAt: DateTime.now().add(Duration(days: expectedDays)),
      status: ReorderStatus.pending,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );

    notifier.upsert(reorder);

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Reorder created: $quantity ${widget.item.unit} of ${widget.item.name}',
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
        title: 'Create reorder for ${widget.item.name}',
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _save,
            child: const Text('Create reorder'),
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
                  '${widget.item.stock} ${widget.item.unit}',
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Insets.lg),
            LabeledFormField(
              label: 'Quantity to order',
              isRequired: true,
              child: TextFormField(
                controller: _quantity,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: '${widget.item.reorderLevel}',
                  suffixText: widget.item.unit,
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) return 'Enter quantity';
                  if (int.tryParse(value?.trim() ?? '') == null) {
                    return 'Enter a whole number';
                  }
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
                  if (double.tryParse(value?.trim() ?? '') == null) {
                    return 'Enter a number';
                  }
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
