import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/inventory_item.dart';
import '../../models/stock_movement.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/staff_provider.dart';
import '../../providers/stock_movement_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/labeled_form_field.dart';

/// Width the three stock dialogs share. Narrower than the item form, which has
/// a photo column to accommodate — these are single-column and a wider box
/// would just stretch four short fields across dead space.
const double kStockDialogWidth = 480;

/// Widget keys for the stock dialogs' controls.
///
/// The labels sit outside the inputs, so there is no `labelText` for a test to
/// find a field by — the same reason [ItemFormKeys] exists. Shared across all
/// three dialogs because the fields are the shared widgets below, not
/// per-dialog copies.
abstract final class StockDialogKeys {
  static const quantity = Key('stockDialog.quantity');
  static const notes = Key('stockDialog.notes');
  static const reason = Key('stockDialog.reason');
  static const destination = Key('stockDialog.destination');
  static const submit = Key('stockDialog.submit');
  static const cancel = Key('stockDialog.cancel');
}

/// Read-only item context at the top of every stock dialog.
///
/// The same block in all three, so a user who has learned where the current
/// count sits in Adjust finds it in exactly the same place in Waste.
class StockItemContext extends StatelessWidget {
  const StockItemContext({super.key, required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh.withValues(alpha: 0.55),
        borderRadius: Radii.card,
        border: Border.all(color: context.semantic.hairline),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: item.image != null
                ? Image.memory(
                    item.image!.bytes,
                    fit: BoxFit.cover,
                    width: 40,
                    height: 40,
                  )
                : Text(item.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall,
                ),
                Text(
                  '${item.sku} · ${item.stock} ${item.unit} in stock',
                  maxLines: 1,
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
    );
  }
}

/// The quantity input the three dialogs share: digits only, unit as a suffix,
/// and an inline error when the amount is impossible.
class StockQuantityField extends StatelessWidget {
  const StockQuantityField({
    super.key,
    required this.controller,
    required this.item,
    required this.onChanged,
    this.label = 'Quantity',
    this.helper,
    this.errorText,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final InventoryItem item;
  final ValueChanged<String> onChanged;
  final String label;
  final String? helper;

  /// Supplied by the dialog rather than a validator, because the same message
  /// also has to gate the confirm button — deriving it once keeps the button
  /// and the error from ever disagreeing.
  final String? errorText;

  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return LabeledFormField(
      label: label,
      isRequired: true,
      helper: helper,
      child: TextFormField(
        key: StockDialogKeys.quantity,
        controller: controller,
        autofocus: autofocus,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: '0',
          suffixText: item.unit,
          errorText: errorText,
        ),
      ),
    );
  }
}

/// Optional free-text notes. Identical in all three dialogs.
class StockNotesField extends StatelessWidget {
  const StockNotesField({
    super.key,
    required this.controller,
    this.label = 'Notes',
    this.hint = 'Anything worth recording',
  });

  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return LabeledFormField(
      label: label,
      child: TextFormField(
        key: StockDialogKeys.notes,
        controller: controller,
        maxLines: 2,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: hint,
          // The pill border the theme applies to single-line inputs looks
          // wrong wrapped around a two-line box.
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Radii.md),
            borderSide: BorderSide(color: context.semantic.hairline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Radii.md),
            borderSide: BorderSide(color: context.colors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// A single-line preview of what confirming will do — "New stock level: 38 kg".
///
/// Live rather than shown after the fact, because the whole risk in a stock
/// dialog is transposing a digit, and the number is easier to sanity-check than
/// the arithmetic that produced it.
class StockPreviewLine extends StatelessWidget {
  const StockPreviewLine({
    super.key,
    required this.label,
    required this.value,
    this.tone,
    this.icon = Icons.arrow_forward_rounded,
  });

  final String label;
  final String value;
  final Color? tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = tone ?? colors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.md,
        vertical: Insets.sm + 2,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: accent),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: Insets.sm),
          Text(
            value,
            maxLines: 1,
            style: context.text.titleSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Applies a stock change and records it in the ledger, in that order.
///
/// The one place the two providers are written together. Doing it anywhere else
/// risks a count that moved without a movement to explain it, which is exactly
/// the discrepancy the ledger exists to make impossible.
///
/// Returns the item's stock level after the change — read back from the
/// provider rather than computed, because [InventoryNotifier.adjustStock]
/// clamps at zero and the ledger has to record what actually happened.
int applyStockMovement({
  required WidgetRef ref,
  required InventoryItem item,
  required int delta,
  required StockMovementType type,
  String? note,
}) {
  ref.read(inventoryItemsProvider.notifier).adjustStock(item.id, delta);

  final updated = ref
      .read(inventoryItemsProvider)
      .firstWhere((i) => i.id == item.id, orElse: () => item);

  ref
      .read(stockMovementsProvider.notifier)
      .record(
        itemId: item.id,
        type: type,
        // The recorded delta is the effective one: asking to remove 10 from a
        // shelf holding 4 removes 4, and the ledger says 4.
        delta: updated.stock - item.stock,
        balanceAfter: updated.stock,
        actor: ref.read(currentUserNameProvider),
        note: note,
      );

  return updated.stock;
}

/// Parses a quantity field. Null for empty or unparseable input, which the
/// dialogs treat as "not yet valid" rather than as zero.
int? parseQuantity(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  return int.tryParse(trimmed);
}
