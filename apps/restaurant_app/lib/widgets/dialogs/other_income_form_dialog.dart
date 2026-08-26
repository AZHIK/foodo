import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_finance.dart';
import '../../models/other_income.dart';
import '../../models/order.dart';
import '../../providers/other_income_form_provider.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../labeled_form_field.dart';
import '../responsive_form_dialog.dart';

Future<void> showOtherIncomeFormDialog(
  BuildContext context, {
  OtherIncome? existingIncome,
}) {
  return showResponsiveFormDialog<void>(
    context,
    builder: (_) => OtherIncomeFormDialog(incomeId: existingIncome?.id),
  );
}

class OtherIncomeFormDialog extends ConsumerStatefulWidget {
  const OtherIncomeFormDialog({super.key, this.incomeId});
  final String? incomeId;
  static const double dialogWidth = 560;

  @override
  ConsumerState<OtherIncomeFormDialog> createState() =>
      _OtherIncomeFormDialogState();
}

class _OtherIncomeFormDialogState extends ConsumerState<OtherIncomeFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final _provider =
      otherIncomeFormProvider(widget.incomeId);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_provider);
    final notifier = ref.read(_provider.notifier);

    return Dialog(
      child: SizedBox(
        width: OtherIncomeFormDialog.dialogWidth,
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
                    widget.incomeId == null ? 'Add income' : 'Edit income',
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
                      items: MockFinance.incomeCategories
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
                    label: 'Source (optional)',
                    child: TextFormField(
                      initialValue: state.source,
                      onChanged: notifier.setSource,
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
                          widget.incomeId == null ? 'Add' : 'Update',
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

    final isEdit = widget.incomeId != null;
    ref.read(_provider.notifier).save();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          isEdit ? 'Income updated' : 'Income added',
        ),
      ),
    );
  }
}
