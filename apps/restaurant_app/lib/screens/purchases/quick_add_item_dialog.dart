/// Quick-add item dialog for the purchasing flow.
///
/// A compact alternative to the full `ItemFormDialog`: just name, unit,
/// cost, and type (raw material vs resold as-is). On save it creates the
/// item via `InventoryApiService`, refreshes the inventory list, and
/// returns the new item's id so the caller can select it immediately.
///
/// Returns the created item id, or null when dismissed.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_strings.dart';
import '../../providers/inventory_api_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/permissions_provider.dart';
import '../../providers/units_provider.dart';
import '../../services/inventory_api_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/dialog_helper.dart';

Future<String?> showQuickAddItemDialog(
  BuildContext context, {
  String? initialCost,
}) {
  return showAppDialog<String>(
    context: context,
    builder: (_) => _QuickAddItemDialog(initialCost: initialCost),
  );
}

class _QuickAddItemDialog extends ConsumerStatefulWidget {
  const _QuickAddItemDialog({this.initialCost});

  final String? initialCost;

  @override
  ConsumerState<_QuickAddItemDialog> createState() =>
      _QuickAddItemDialogState();
}

class _QuickAddItemDialogState extends ConsumerState<_QuickAddItemDialog> {
  final _name = TextEditingController();
  late final TextEditingController _cost =
      TextEditingController(text: widget.initialCost ?? '');
  String? _unitId;
  String _itemType = 'raw_material';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _cost.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final cost = Decimal.tryParse(_cost.text.trim());
    if (name.isEmpty) {
      setState(() => _error = 'Enter an item name');
      return;
    }
    if (cost == null || cost < Decimal.zero) {
      setState(() => _error = 'Enter a valid unit cost');
      return;
    }
    final businessId = ref.read(currentBusinessIdProvider);
    final storeId = ref.read(currentStoreIdProvider);
    if (businessId == null || storeId == null) {
      setState(() => _error = 'Purchases need an active store context');
      return;
    }
    var unitId = _unitId;
    unitId ??= ref
        .read(unitsListProvider)
        .where((u) => u.abbreviation == 'kg')
        .firstOrNull
        ?.id;
    unitId ??= ref.read(unitsListProvider).firstOrNull?.id;
    if (unitId == null) {
      setState(() => _error = 'Units are still loading — try again shortly');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final created =
          await ref.read(inventoryApiServiceProvider).createItem(
                businessId: businessId,
                storeId: storeId,
                name: name,
                unitId: unitId,
                itemType: _itemType,
                reorderThreshold: Decimal.zero,
                reorderQuantity: Decimal.zero,
                unitCost: cost,
              );
      // Make the new row visible to the line's item picker immediately.
      await ref.read(inventoryItemsProvider.notifier).refresh();
      if (!mounted) return;
      Navigator.of(context).pop(created.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e is InventoryApiException
            ? e.message
            : 'Could not create item: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(unitsListProvider);
    return AlertDialog(
      title: const Text('New item'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Item name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: Insets.sm),
            DropdownButtonFormField<String>(
              initialValue: _unitId,
              decoration: const InputDecoration(labelText: 'Unit'),
              items: [
                for (final unit in units)
                  DropdownMenuItem(
                    value: unit.id,
                    child: Text(unit.abbreviation),
                  ),
              ],
              onChanged: (v) => setState(() => _unitId = v),
            ),
            const SizedBox(height: Insets.sm),
            TextField(
              controller: _cost,
              decoration: const InputDecoration(labelText: 'Unit cost'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: Insets.sm),
            DropdownButtonFormField<String>(
              initialValue: _itemType,
              decoration:
                  const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(
                  value: 'raw_material',
                  child: Text('Raw material'),
                ),
                DropdownMenuItem(
                  value: 'both',
                  child: Text('Resold as-is'),
                ),
              ],
              onChanged: (v) =>
                  setState(() => _itemType = v ?? 'raw_material'),
            ),
            if (_error != null) ...[
              const SizedBox(height: Insets.sm),
              Text(_error!, style: TextStyle(color: context.colors.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add item'),
        ),
      ],
    );
  }
}
