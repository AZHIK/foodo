import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/inventory_item.dart';
import '../../constants/app_strings.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../../widgets/image_upload_field.dart';
import '../../widgets/labeled_form_field.dart';
import '../../widgets/responsive_form_dialog.dart';
import 'stock_dialog_shared.dart';

enum WasteReason {
  expired('wasteReasonExpired', 'Expired'),
  spoiled('wasteReasonSpoiled', 'Spoiled'),
  prepError('wasteReasonPrep', 'Prep error'),
  damaged('wasteReasonDropped', 'Dropped / damaged'),
  other('wasteReasonOther', 'Other');

  const WasteReason(this.labelKey, this.labelDefault);
  final String labelKey;
  final String labelDefault;
  String get label => L10n.t(labelKey, labelDefault);
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

  bool _submitting = false;

  double? get _amount => parseQuantity(_quantity.text);

  double get _newLevel =>
      (widget.item.stock - (_amount ?? 0)).clamp(0, double.infinity);

  /// Waste cannot exceed what is on the shelf: you cannot throw away stock you
  /// do not have, and a count that says otherwise is a mis-key.
  String? get _error {
    final amount = _amount;
    if (amount == null) return null;
    if (amount == 0) return AppStrings.amountPositive;
    if (amount > widget.item.stock) {
      return AppStrings.onlyInStock(
        Fmt.quantity(widget.item.stock),
        widget.item.unit,
      );
    }
    return null;
  }

  bool get _canSubmit => !_submitting && _amount != null && _amount! > 0 && _error == null;

  Future<void> _submit() async {
    final note = _notes.text.trim();
    final amount = _amount ?? 0;
    final parts = <String>[
      _reason.label,
      if (note.isNotEmpty) note,
      // Recorded as text because the mock ledger stores no binaries — enough
      // for the history to show evidence was attached.
      if (_photoName != null) AppStrings.wastePhotoEvidence(_photoName!),
    ];
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = true);
    try {
      await applyWaste(
        ref: ref,
        item: widget.item,
        quantity: amount,
        reason: parts.join(' · '),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.wasteLogged(
              Fmt.quantity(amount),
              widget.item.unit,
              widget.item.name,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.wasteFailed(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final semantic = context.semantic;

    return ResponsiveFormDialog(
      title: AppStrings.logWaste,
      width: kStockDialogWidth,
      actions: [
        OutlinedButton(
          key: StockDialogKeys.cancel,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.cancel),
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
          child: Text(AppStrings.logWaste),
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
            label: AppStrings.quantityWasted,
            errorText: _error,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Insets.md),

          StockPreviewLine(
            label: AppStrings.remainingAfterWaste,
            value: '${Fmt.quantity(_newLevel)} ${item.unit}',
            tone: semantic.warning,
            icon: Icons.trending_down_rounded,
          ),
          const SizedBox(height: Insets.lg),

          LabeledFormField(
            label: AppStrings.wasteReasonLabel,
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
            hint: AppStrings.wasteNotesHint,
          ),
          const SizedBox(height: Insets.lg),

          LabeledFormField(
            label: AppStrings.photoLabel,
            helper: AppStrings.photoClaimHelper,
            child: Align(
              alignment: Alignment.centerLeft,
              child: ImageUploadField(
                image: _photoBytes,
                size: WasteLogDialog._photoSize,
                label: AppStrings.addPhoto,
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
