import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/inventory_item.dart';
import '../../models/stock_movement.dart';
import '../../models/store_location.dart';
import '../../providers/store_locations_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/labeled_form_field.dart';
import '../../widgets/responsive_form_dialog.dart';
import 'stock_dialog_shared.dart';

/// Opens the stock transfer dialog for [item].
Future<void> showStockTransferDialog(
  BuildContext context,
  InventoryItem item,
) {
  return showResponsiveFormDialog<void>(
    context,
    builder: (_) => StockTransferDialog(item: item),
  );
}

class StockTransferDialog extends ConsumerStatefulWidget {
  const StockTransferDialog({super.key, required this.item});

  final InventoryItem item;

  @override
  ConsumerState<StockTransferDialog> createState() =>
      _StockTransferDialogState();
}

class _StockTransferDialogState extends ConsumerState<StockTransferDialog> {
  final _quantity = TextEditingController();
  final _notes = TextEditingController();

  /// Held as an id rather than the object: Store Management can edit a
  /// location while this dialog is open, and the edited record is a different
  /// instance of the same site. An id still resolves; a stale object would drop
  /// out of the dropdown's item list and trip its "value must be one of the
  /// items" assertion.
  String? _destinationId;

  @override
  void initState() {
    super.initState();
    // Pre-selected when there is exactly one other site: a required dropdown
    // with one option is a question with only one answer.
    final targets = ref.read(transferTargetsProvider);
    if (targets.length == 1) _destinationId = targets.first.id;
  }

  /// The chosen site, or null once it stops being a valid destination.
  StoreLocation? _resolve(List<StoreLocation> targets) {
    for (final location in targets) {
      if (location.id == _destinationId) return location;
    }
    return null;
  }

  @override
  void dispose() {
    _quantity.dispose();
    _notes.dispose();
    super.dispose();
  }

  int? get _amount => parseQuantity(_quantity.text);

  int get _newLevel => (widget.item.stock - (_amount ?? 0)).clamp(0, 1 << 31);

  String? get _error {
    final amount = _amount;
    if (amount == null) return null;
    if (amount == 0) return 'Enter an amount greater than zero';
    if (amount > widget.item.stock) {
      return 'Only ${widget.item.stock} ${widget.item.unit} in stock';
    }
    return null;
  }

  bool _canSubmit(StoreLocation? destination) =>
      destination != null &&
      _amount != null &&
      _amount! > 0 &&
      _error == null;

  void _submit(StoreLocation destination) {
    final note = _notes.text.trim();

    applyStockMovement(
      ref: ref,
      item: widget.item,
      // Transfer-out only. The destination site keeps its own inventory, and
      // crediting it is out of scope until multi-location stock exists — so
      // this records the half of the move that actually happened here.
      delta: -(_amount ?? 0),
      type: StockMovementType.transfer,
      note: note.isEmpty
          ? 'To ${destination.name}'
          : 'To ${destination.name} · $note',
    );

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '$_amount ${widget.item.unit} of ${widget.item.name} '
          'transferred to ${destination.name}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    // Read live rather than from the mock table: a location added on the Store
    // Management screen is a valid destination the moment it is saved.
    final targets = ref.watch(transferTargetsProvider);
    final currentStore = ref.watch(currentStoreProvider);
    final destination = _resolve(targets);

    return ResponsiveFormDialog(
      title: 'Transfer stock',
      width: kStockDialogWidth,
      actions: [
        OutlinedButton(
          key: StockDialogKeys.cancel,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: StockDialogKeys.submit,
          onPressed: _canSubmit(destination)
              ? () => _submit(destination!)
              : null,
          child: const Text('Transfer stock'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StockItemContext(item: item),
          const SizedBox(height: Insets.xl),

          LabeledFormField(
            label: 'Transfer to',
            isRequired: true,
            helper: 'Moving out of ${currentStore?.name ?? 'this store'}',
            child: DropdownButtonFormField<StoreLocation>(
              key: StockDialogKeys.destination,
              initialValue: destination,
              isExpanded: true,
              hint: const Text('Select a location'),
              items: [
                for (final location in targets)
                  DropdownMenuItem(
                    value: location,
                    child: Text(
                      location.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _destinationId = value?.id),
            ),
          ),
          const SizedBox(height: Insets.lg),

          StockQuantityField(
            controller: _quantity,
            item: item,
            label: 'Quantity to transfer',
            errorText: _error,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Insets.md),

          StockPreviewLine(
            label: 'Remaining at this store',
            value: '$_newLevel ${item.unit}',
            tone: context.semantic.warning,
            icon: Icons.swap_horiz_rounded,
          ),
          const SizedBox(height: Insets.lg),

          StockNotesField(
            controller: _notes,
            hint: 'e.g. covering their Friday service',
          ),
        ],
      ),
    );
  }
}
