import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_finance.dart';
import '../../constants/app_strings.dart';
import '../../models/other_income.dart';
import '../../models/order.dart';
import '../../models/permission.dart';
import '../../providers/other_income_form_provider.dart';
import '../../providers/other_expenses_provider.dart' show FinanceOfflineMutationException;
import '../../providers/permissions_provider.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../image_upload_field.dart';
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
  bool _saving = false;

  late final _provider =
      otherIncomeFormProvider(widget.incomeId);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_provider);
    final notifier = ref.read(_provider.notifier);
    final canUploadReceipt = ref.watch(
      hasPermissionProvider(AppPermissions.financeAttachmentsUpload),
    );

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
                    widget.incomeId == null
                        ? AppStrings.addIncomeTitle
                        : AppStrings.editIncomeTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: Insets.lg),
                  LabeledFormField(
                    label: AppStrings.dateLabel,
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
                    label: AppStrings.categoryLabel,
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
                          val == null ? AppStrings.categoryRequired : null,
                    ),
                  ),
                  const SizedBox(height: Insets.lg),
                  LabeledFormField(
                    label: AppStrings.descriptionLabel,
                    child: TextFormField(
                      initialValue: state.description,
                      onChanged: notifier.setDescription,
                      validator: (val) => val?.isEmpty ?? true
                          ? AppStrings.descriptionRequired
                          : null,
                    ),
                  ),
                  const SizedBox(height: Insets.lg),
                  LabeledFormField(
                    label: AppStrings.amountLabel,
                    child: TextFormField(
                      initialValue: state.amount,
                      onChanged: notifier.setAmount,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val?.isEmpty ?? true) {
                          return AppStrings.amountRequired;
                        }
                        if (double.tryParse(val!) == null) {
                          return AppStrings.validAmount;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: Insets.lg),
                  LabeledFormField(
                    label: AppStrings.paymentMethodLabel,
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
                    label: AppStrings.sourceOptional,
                    child: TextFormField(
                      initialValue: state.source,
                      onChanged: notifier.setSource,
                    ),
                  ),
                  const SizedBox(height: Insets.lg),
                  LabeledFormField(
                    label: AppStrings.noteOptional,
                    child: TextFormField(
                      initialValue: state.note,
                      onChanged: notifier.setNote,
                      maxLines: 3,
                    ),
                  ),
                  if (canUploadReceipt) ...[
                    const SizedBox(height: Insets.lg),
                    LabeledFormField(
                      label: AppStrings.receiptOptional,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ImageUploadField(
                          image: state.receiptBytes,
                          size: 120,
                          label: AppStrings.uploadReceipt,
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
                        child: const Text(AppStrings.cancel),
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
                                widget.incomeId == null
                                    ? AppStrings.addAction
                                    : AppStrings.updateAction,
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

    final isEdit = widget.incomeId != null;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);

    try {
      await ref.read(_provider.notifier).save();
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppStrings.incomeSaved(isEdit)),
        ),
      );
    } on FinanceOfflineMutationException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(AppStrings.saveFailed(e))));
    }
  }
}
