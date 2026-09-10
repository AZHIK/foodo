import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_finance.dart';
import '../../models/other_expense.dart';
import '../../models/order.dart';
import '../../models/permission.dart';
import '../../providers/other_expense_form_provider.dart';
import '../../providers/other_expenses_provider.dart' show FinanceOfflineMutationException;
import '../../providers/permissions_provider.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../image_upload_field.dart';
import '../labeled_form_field.dart';
import '../responsive_form_dialog.dart';

Future<void> showOtherExpenseFormDialog(
  BuildContext context, {
  OtherExpense? existingExpense,
}) {
  return showResponsiveFormDialog<void>(
    context,
    builder: (_) => OtherExpenseFormDialog(expenseId: existingExpense?.id),
  );
}

class OtherExpenseFormDialog extends ConsumerStatefulWidget {
  const OtherExpenseFormDialog({super.key, this.expenseId});
  final String? expenseId;
  static const double dialogWidth = 560;

  @override
  ConsumerState<OtherExpenseFormDialog> createState() =>
      _OtherExpenseFormDialogState();
}

class _OtherExpenseFormDialogState extends ConsumerState<OtherExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final _provider =
      otherExpenseFormProvider(widget.expenseId);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_provider);
    final notifier = ref.read(_provider.notifier);
    final canUploadReceipt = ref.watch(
      hasPermissionProvider(AppPermissions.financeAttachmentsUpload),
    );

    return Dialog(
      child: SizedBox(
        width: OtherExpenseFormDialog.dialogWidth,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(Insets.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.expenseId == null ? 'Add expense' : 'Edit expense',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: Insets.lg),
                  LabeledFormField(
                    label: 'Date',
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: state.date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            notifier.setDate(picked);
                          }
                        },
                        child: Text(Fmt.longDate(state.date)),
                      ),
                    ),
                  ),
                  const SizedBox(height: Insets.lg),
                  LabeledFormField(
                    label: 'Category',
                    child: DropdownButtonFormField<String>(
                      initialValue: state.categoryId.isEmpty ? null : state.categoryId,
                      items: MockFinance.expenseCategories
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.label),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          notifier.setCategory(val);
                        }
                      },
                      validator: (val) =>
                          val == null ? 'Category is required' : null,
                    ),
                  ),
                  const SizedBox(height: Insets.lg),
                  LabeledFormField(
                    label: 'Description',
                    child: TextFormField(
                      initialValue: state.description,
                      onChanged: notifier.setDescription,
                      validator: (val) => val?.isEmpty ?? true
                          ? 'Description is required'
                          : null,
                    ),
                  ),
                  const SizedBox(height: Insets.lg),
                  LabeledFormField(
                    label: 'Amount',
                    child: TextFormField(
                      initialValue: state.amount,
                      onChanged: notifier.setAmount,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val?.isEmpty ?? true) {
                          return 'Amount is required';
                        }
                        if (double.tryParse(val!) == null) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: Insets.lg),
                  LabeledFormField(
                    label: 'Payment Method',
                    child: DropdownButtonFormField<PaymentType>(
                      initialValue: state.paymentType,
                      items: PaymentType.values
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.label),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          notifier.setPaymentType(val);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: Insets.lg),
                  LabeledFormField(
                    label: 'Payee (optional)',
                    child: TextFormField(
                      initialValue: state.payee,
                      onChanged: notifier.setPayee,
                    ),
                  ),
                  const SizedBox(height: Insets.lg),
                  LabeledFormField(
                    label: 'Note (optional)',
                    child: TextFormField(
                      initialValue: state.note,
                      onChanged: notifier.setNote,
                      maxLines: 3,
                    ),
                  ),
                  if (canUploadReceipt) ...[
                    const SizedBox(height: Insets.lg),
                    LabeledFormField(
                      label: 'Receipt (optional)',
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ImageUploadField(
                          image: state.receiptBytes,
                          size: 120,
                          label: 'Upload receipt',
                          onPicked: notifier.setReceipt,
                          onRemoved: notifier.clearReceipt,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: Insets.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: Insets.md),
                      FilledButton(
                        onPressed: state.canSave && !_saving ? _save : null,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                widget.expenseId == null ? 'Add' : 'Update',
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final isEdit = widget.expenseId != null;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);

    try {
      await ref.read(_provider.notifier).save();
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Expense updated' : 'Expense added'),
        ),
      );
    } on FinanceOfflineMutationException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }
}
