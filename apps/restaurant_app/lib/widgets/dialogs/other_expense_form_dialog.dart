import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_finance.dart';
import '../../models/other_expense.dart';
import '../../models/order.dart';
import '../../providers/other_expense_form_provider.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
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

  late final _provider =
      otherExpenseFormProvider(widget.expenseId);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_provider);
    final notifier = ref.read(_provider.notifier);

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
                        onPressed: state.canSave ? _save : null,
                        child: Text(
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

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final isEdit = widget.expenseId != null;
    ref.read(_provider.notifier).save();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          isEdit ? 'Expense updated' : 'Expense added',
        ),
      ),
    );
  }
}
