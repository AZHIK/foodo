import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/customer.dart';
import '../../providers/customers_provider.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/labeled_form_field.dart';
import '../../widgets/responsive_form_dialog.dart';
import '../../widgets/section_label.dart';

/// Opens the add/edit customer form dialog.
Future<void> showCustomerFormDialog(
  BuildContext context, {
  Customer? existingCustomer,
}) {
  return showResponsiveFormDialog<void>(
    context,
    builder: (_) => _CustomerFormDialog(customer: existingCustomer),
  );
}

class _CustomerFormDialog extends ConsumerStatefulWidget {
  const _CustomerFormDialog({this.customer});

  final Customer? customer;

  @override
  ConsumerState<_CustomerFormDialog> createState() =>
      _CustomerFormDialogState();
}

class _CustomerFormDialogState extends ConsumerState<_CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.customer?.name ?? '');
    _phone = TextEditingController(text: widget.customer?.phone ?? '');
    _email = TextEditingController(text: widget.customer?.email ?? '');
    _address = TextEditingController(text: widget.customer?.addressLine1 ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.customer != null;
    Customer? saved;

    if (isEdit) {
      final updated = widget.customer!.copyWith(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        addressLine1: _address.text.trim(),
      );
      ref.read(customersProvider.notifier).upsert(updated);
      saved = updated;
    } else {
      final notifier = ref.read(customersProvider.notifier);
      final newCustomer = Customer(
        id: notifier.nextId(),
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        addressLine1:
            _address.text.trim().isEmpty ? null : _address.text.trim(),
        createdAt: DateTime.now(),
        lastOrderAt: null,
        totalOrders: 0,
        totalSpent: 0,
      );
      notifier.upsert(newCustomer);
      saved = newCustomer;
    }

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          isEdit ? '${saved.name} updated' : '${saved.name} added',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.customer != null;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ResponsiveFormDialog(
        title: isEdit ? 'Edit customer' : 'Add customer',
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _save,
            child: Text(isEdit ? 'Save changes' : 'Add customer'),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionLabel('Contact info'),
            const SizedBox(height: Insets.md),
            LabeledFormField(
              label: 'Name',
              isRequired: true,
              child: TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Full name',
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Enter a name'
                    : null,
              ),
            ),
            const SizedBox(height: Insets.lg),
            LabeledFormField(
              label: 'Phone',
              isRequired: true,
              child: TextFormField(
                controller: _phone,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '+1 (555) 123-4567',
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Enter a phone number'
                    : null,
              ),
            ),
            const SizedBox(height: Insets.lg),
            LabeledFormField(
              label: 'Email',
              child: TextFormField(
                controller: _email,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'email@example.com',
                ),
              ),
            ),
            const SizedBox(height: Insets.lg),
            LabeledFormField(
              label: 'Address',
              child: TextFormField(
                controller: _address,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Street address (optional)',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
