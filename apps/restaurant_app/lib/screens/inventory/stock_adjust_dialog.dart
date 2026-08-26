import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/inventory_item.dart';
import '../../models/stock_movement.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/labeled_form_field.dart';
import '../../widgets/responsive_form_dialog.dart';
import '../../widgets/selectable_option_card.dart';
import 'stock_dialog_shared.dart';

/// Why stock is being corrected.
///
/// A restock is a genuinely different event from a recount, so the reason
/// decides which [StockMovementType] the ledger records — otherwise every
/// delivery would file itself under "Adjustment" and the history would lose the
/// distinction the moment it was written.
enum AdjustReason {
  restock('Restock', StockMovementType.restock),
  recount('Recount / correction', StockMovementType.adjustment),
  damaged('Damaged', StockMovementType.adjustment),
  other('Other', StockMovementType.adjustment);

  const AdjustReason(this.label, this.movementType);
  final String label;
  final StockMovementType movementType;
}

/// Opens the stock adjustment dialog for [item].
Future<void> showStockAdjustDialog(BuildContext context, InventoryItem item) {
  return showResponsiveFormDialog<void>(
    context,
    builder: (_) => StockAdjustDialog(item: item),
  );
}

class StockAdjustDialog extends ConsumerStatefulWidget {
  const StockAdjustDialog({super.key, required this.item});

  final InventoryItem item;

  @override
  ConsumerState<StockAdjustDialog> createState() => _StockAdjustDialogState();
}

class _StockAdjustDialogState extends ConsumerState<StockAdjustDialog> {
  final _quantity = TextEditingController();
  final _notes = TextEditingController();

  bool _adding = true;
  AdjustReason _reason = AdjustReason.restock;

  @override
  void dispose() {
    _quantity.dispose();
    _notes.dispose();
    super.dispose();
  }

  int? get _amount => parseQuantity(_quantity.text);

  int get _delta => _adding ? (_amount ?? 0) : -(_amount ?? 0);

  int get _newLevel => (widget.item.stock + _delta).clamp(0, 1 << 31);

  /// Removing more than is on the shelf is a data-entry mistake, not a
  /// negative stock level. The provider would clamp it silently; catching it
  /// here means the user finds out before the ledger records a number they
  /// did not intend.
  String? get _error {
    final amount = _amount;
    if (amount == null) return null;
    if (amount == 0) return 'Enter an amount greater than zero';
    if (!_adding && amount > widget.item.stock) {
      return 'Only ${widget.item.stock} ${widget.item.unit} in stock';
    }
    return null;
  }

  bool get _canSubmit =>
      _amount != null && _amount! > 0 && _error == null;

  void _submit() {
    final note = _notes.text.trim();

    applyStockMovement(
      ref: ref,
      item: widget.item,
      delta: _delta,
      type: _reason.movementType,
      note: note.isEmpty ? _reason.label : '${_reason.label} · $note',
    );

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${widget.item.name} adjusted to $_newLevel ${widget.item.unit}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return ResponsiveFormDialog(
      title: 'Adjust stock',
      width: kStockDialogWidth,
      actions: [
        OutlinedButton(
          key: StockDialogKeys.cancel,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: StockDialogKeys.submit,
          onPressed: _canSubmit ? _submit : null,
          child: const Text('Confirm adjustment'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StockItemContext(item: item),
          const SizedBox(height: Insets.xl),

          LabeledFormField(
            label: 'Adjustment type',
            isRequired: true,
            child: SelectableOptionGrid(
              perRow: 2,
              children: [
                SelectableOptionCard(
                  label: 'Add stock',
                  subtitle: 'Delivery or found',
                  icon: Icons.add_circle_outline_rounded,
                  selected: _adding,
                  onTap: () => setState(() => _adding = true),
                ),
                SelectableOptionCard(
                  label: 'Remove stock',
                  subtitle: 'Correction or loss',
                  icon: Icons.remove_circle_outline_rounded,
                  selected: !_adding,
                  onTap: () => setState(() => _adding = false),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),

          StockQuantityField(
            controller: _quantity,
            item: item,
            errorText: _error,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Insets.md),

          StockPreviewLine(
            label: 'New stock level',
            value: '$_newLevel ${item.unit}',
            tone: _delta == 0
                ? null
                : (_delta > 0
                      ? context.semantic.success
                      : context.semantic.warning),
            icon: _delta >= 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
          ),
          const SizedBox(height: Insets.lg),

          LabeledFormField(
            label: 'Reason',
            isRequired: true,
            child: DropdownButtonFormField<AdjustReason>(
              key: StockDialogKeys.reason,
              initialValue: _reason,
              isExpanded: true,
              items: [
                for (final reason in AdjustReason.values)
                  DropdownMenuItem(
                    value: reason,
                    child: Text(
                      reason.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _reason = value ?? _reason),
            ),
          ),
          const SizedBox(height: Insets.lg),

          StockNotesField(
            controller: _notes,
            hint: 'e.g. counted with Marco after close',
          ),
        ],
      ),
    );
  }
}
