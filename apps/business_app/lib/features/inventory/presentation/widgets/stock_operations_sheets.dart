import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/fakes/fake_data_service.dart';
import '../../../../shared/widgets/widgets.dart';

/// Modal stock-operation entry points reachable from the item detail screen.
///
/// **Design decision — modals, not full screens.** Each operation is a
/// single small form (one numeric input + a reason, or a source/destination
/// picker). Promoting them to dedicated routes would add navigation noise
/// and extra scaffolding for what is at most a 4-field form. Rendering them
/// as a [Dialog] on tablet/desktop widths and a [showModalBottomSheet] on
/// phone widths keeps the user in context, matches the app's minimalist
/// goal, and keeps the operation close to the item it applies to.
///
/// All three mutate [fakeInventoryProvider] in-memory:
/// - [showAdjustStock] — quantity delta + required reason
/// - [showRecordWaste] — positive quantity + required reason
/// - [showTransferStock] — source/destination location + positive quantity
class StockOperations {
  StockOperations._();

  static Future<void> showAdjustStock(
    BuildContext context,
    WidgetRef ref,
    FakeInventoryItem item,
  ) {
    return _showModal(context, _AdjustStockForm(item: item));
  }

  static Future<void> showRecordWaste(
    BuildContext context,
    WidgetRef ref,
    FakeInventoryItem item,
  ) {
    return _showModal(context, _RecordWasteForm(item: item));
  }

  static Future<void> showTransferStock(
    BuildContext context,
    WidgetRef ref,
    FakeInventoryItem item,
  ) {
    return _showModal(context, _TransferStockForm(item: item));
  }

  static Future<void> _showModal(BuildContext context, Widget child) {
    final isWide =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointTablet;
    if (isWide) {
      return showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceLG),
              child: child,
            ),
          ),
        ),
      );
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppDimensions.spaceMD,
          right: AppDimensions.spaceMD,
          top: AppDimensions.spaceMD,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppDimensions.spaceMD,
        ),
        child: SingleChildScrollView(child: child),
      ),
    );
  }
}

/// Shared form surface: title + form body + primary submit button.
class _OperationFormShell extends StatelessWidget {
  const _OperationFormShell({
    required this.title,
    required this.formKey,
    required this.submitLabel,
    required this.submitIcon,
    required this.onSubmit,
    required this.child,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final String submitLabel;
  final IconData submitIcon;
  final VoidCallback onSubmit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          child,
          const SizedBox(height: AppDimensions.spaceLG),
          AppPrimaryButton(
            label: submitLabel,
            icon: submitIcon,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

/// Adjust stock: signed quantity delta + required reason.
class _AdjustStockForm extends ConsumerStatefulWidget {
  const _AdjustStockForm({required this.item});
  final FakeInventoryItem item;

  @override
  ConsumerState<_AdjustStockForm> createState() => _AdjustStockFormState();
}

class _AdjustStockFormState extends ConsumerState<_AdjustStockForm> {
  final _formKey = GlobalKey<FormState>();
  int _delta = 0;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_delta == 0) return;
    ref
        .read(fakeInventoryProvider.notifier)
        .adjustStock(widget.item.id, _delta, _reasonController.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _OperationFormShell(
      title: 'Adjust Stock — ${widget.item.name}',
      formKey: _formKey,
      submitLabel: 'Submit Adjustment',
      submitIcon: Icons.check,
      onSubmit: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppNumberField(
            label: 'Quantity Delta (+ to add, - to reduce)',
            initialValue: _delta,
            allowNegative: true,
            allowZero: true,
            onChanged: (val) => _delta = val,
            validator: (val) =>
                (val == null || val == 0) ? 'Delta must not be zero' : null,
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          AppTextField(
            controller: _reasonController,
            label: 'Reason for Adjustment',
            hint: 'e.g. Stock count audit discrepancy',
            validator: (val) => (val == null || val.trim().isEmpty)
                ? 'Reason is required'
                : null,
          ),
        ],
      ),
    );
  }
}

/// Record waste: positive quantity + required reason.
class _RecordWasteForm extends ConsumerStatefulWidget {
  const _RecordWasteForm({required this.item});
  final FakeInventoryItem item;

  @override
  ConsumerState<_RecordWasteForm> createState() => _RecordWasteFormState();
}

class _RecordWasteFormState extends ConsumerState<_RecordWasteForm> {
  final _formKey = GlobalKey<FormState>();
  int _quantity = 1;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref
        .read(fakeInventoryProvider.notifier)
        .recordWaste(widget.item.id, _quantity, _reasonController.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _OperationFormShell(
      title: 'Record Waste — ${widget.item.name}',
      formKey: _formKey,
      submitLabel: 'Record Waste',
      submitIcon: Icons.delete_outline,
      onSubmit: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppNumberField(
            label: 'Wasted Quantity',
            initialValue: _quantity,
            min: 1,
            allowNegative: false,
            allowZero: false,
            onChanged: (val) => _quantity = val,
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          AppTextField(
            controller: _reasonController,
            label: 'Reason for Waste',
            hint: 'e.g. Expired, damaged in kitchen, spoilage',
            validator: (val) => (val == null || val.trim().isEmpty)
                ? 'Reason is required'
                : null,
          ),
        ],
      ),
    );
  }
}

/// Transfer stock: source/destination location + positive quantity.
class _TransferStockForm extends ConsumerStatefulWidget {
  const _TransferStockForm({required this.item});
  final FakeInventoryItem item;

  @override
  ConsumerState<_TransferStockForm> createState() => _TransferStockFormState();
}

class _TransferStockFormState extends ConsumerState<_TransferStockForm> {
  static const List<String> _locations = [
    'Main Store',
    'Kitchen Pantry',
    'Bar Storage',
  ];

  final _formKey = GlobalKey<FormState>();
  String _source = 'Main Store';
  String _destination = 'Kitchen Pantry';
  int _quantity = 1;

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_source == _destination) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Source and destination locations must be different'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ref
        .read(fakeInventoryProvider.notifier)
        .transferStock(widget.item.id, _source, _destination, _quantity);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _OperationFormShell(
      title: 'Transfer Stock — ${widget.item.name}',
      formKey: _formKey,
      submitLabel: 'Transfer Stock',
      submitIcon: Icons.swap_horiz,
      onSubmit: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppDropdownField<String>(
            label: 'Source Location',
            value: _source,
            options: _locations,
            onChanged: (v) {
              if (v != null) setState(() => _source = v);
            },
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          AppDropdownField<String>(
            label: 'Destination Location',
            value: _destination,
            options: _locations,
            onChanged: (v) {
              if (v != null) setState(() => _destination = v);
            },
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          AppNumberField(
            label: 'Transfer Quantity',
            initialValue: _quantity,
            min: 1,
            allowNegative: false,
            allowZero: false,
            onChanged: (val) => _quantity = val,
          ),
        ],
      ),
    );
  }
}
