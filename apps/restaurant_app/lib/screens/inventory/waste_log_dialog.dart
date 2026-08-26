import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/inventory_item.dart';
import '../../models/stock_movement.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/image_upload_field.dart';
import '../../widgets/labeled_form_field.dart';
import '../../widgets/responsive_form_dialog.dart';
import 'stock_dialog_shared.dart';

enum WasteReason {
  expired('Expired'),
  spoiled('Spoiled'),
  prepError('Prep error'),
  damaged('Dropped / damaged'),
  other('Other');

  const WasteReason(this.label);
  final String label;
}

/// Opens the waste log dialog for [item].
Future<void> showWasteLogDialog(BuildContext context, InventoryItem item) {
  return showResponsiveFormDialog<void>(
    context,
    builder: (_) => WasteLogDialog(item: item),
  );
}

class WasteLogDialog extends ConsumerStatefulWidget {
  const WasteLogDialog({super.key, required this.item});

  final InventoryItem item;

  /// Small enough to sit beside the reason field without pushing the footer
  /// off a phone, large enough that the upload prompt still reads.
  static const double _photoSize = 120;

  @override
  ConsumerState<WasteLogDialog> createState() => _WasteLogDialogState();
}

class _WasteLogDialogState extends ConsumerState<WasteLogDialog> {
  final _quantity = TextEditingController();
  final _notes = TextEditingController();

  WasteReason _reason = WasteReason.expired;
  String? _photoName;
  Uint8List? _photoBytes;

  @override
  void dispose() {
    _quantity.dispose();
    _notes.dispose();
    super.dispose();
  }

  int? get _amount => parseQuantity(_quantity.text);

  int get _newLevel =>
      (widget.item.stock - (_amount ?? 0)).clamp(0, 1 << 31);

  /// Waste cannot exceed what is on the shelf: you cannot throw away stock you
  /// do not have, and a count that says otherwise is a mis-key.
  String? get _error {
    final amount = _amount;
    if (amount == null) return null;
    if (amount == 0) return 'Enter an amount greater than zero';
    if (amount > widget.item.stock) {
      return 'Only ${widget.item.stock} ${widget.item.unit} in stock';
    }
    return null;
  }

  bool get _canSubmit => _amount != null && _amount! > 0 && _error == null;

  void _submit() {
    final note = _notes.text.trim();
    final parts = <String>[
      _reason.label,
      if (note.isNotEmpty) note,
      // Recorded as text because the mock ledger stores no binaries — enough
      // for the history to show evidence was attached.
      if (_photoName != null) 'Photo: $_photoName',
    ];

    applyStockMovement(
      ref: ref,
      item: widget.item,
      delta: -(_amount ?? 0),
      type: StockMovementType.waste,
      note: parts.join(' · '),
    );

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '$_amount ${widget.item.unit} of ${widget.item.name} '
          'logged as waste',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final semantic = context.semantic;

    return ResponsiveFormDialog(
      title: 'Log waste',
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
          // Amber rather than the app's teal: this action records a loss, and
          // it should not look like the same kind of confirmation as a sale.
          style: FilledButton.styleFrom(
            backgroundColor: semantic.warning,
            foregroundColor: semantic.onWarning,
          ),
          child: const Text('Log waste'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StockItemContext(item: item),
          const SizedBox(height: Insets.xl),

          StockQuantityField(
            controller: _quantity,
            item: item,
            label: 'Quantity wasted',
            errorText: _error,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Insets.md),

          StockPreviewLine(
            label: 'Remaining after waste',
            value: '$_newLevel ${item.unit}',
            tone: semantic.warning,
            icon: Icons.trending_down_rounded,
          ),
          const SizedBox(height: Insets.lg),

          LabeledFormField(
            label: 'Waste reason',
            isRequired: true,
            child: DropdownButtonFormField<WasteReason>(
              key: StockDialogKeys.reason,
              initialValue: _reason,
              isExpanded: true,
              items: [
                for (final reason in WasteReason.values)
                  DropdownMenuItem(
                    value: reason,
                    child: Text(
                      reason.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _reason = value ?? _reason),
            ),
          ),
          const SizedBox(height: Insets.lg),

          StockNotesField(
            controller: _notes,
            hint: 'e.g. left out of the chiller overnight',
          ),
          const SizedBox(height: Insets.lg),

          LabeledFormField(
            label: 'Photo',
            helper: 'Optional — useful for a supplier claim',
            child: Align(
              alignment: Alignment.centerLeft,
              child: ImageUploadField(
                image: _photoBytes,
                size: WasteLogDialog._photoSize,
                label: 'Add photo',
                // No room for the file-size hint at this size; the field hides
                // it below 150px anyway, and an empty string states the intent.
                hint: '',
                onPicked: (name, bytes) => setState(() {
                  _photoName = name;
                  _photoBytes = bytes;
                }),
                onRemoved: () => setState(() {
                  _photoName = null;
                  _photoBytes = null;
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
