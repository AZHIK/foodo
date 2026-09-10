import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/permission.dart';
import '../../providers/customers_provider.dart';
import '../../providers/order_session_provider.dart';
import '../../providers/permissions_provider.dart';
import '../../screens/customers/customer_form_dialog.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';

/// The Customer section of the checkout dialog: shows "Walk-in" when
/// nothing is selected, or the selected customer with a way to change or
/// remove the attribution.
///
/// Lives in `order_session_provider.dart`'s [selectedCustomerIdProvider] —
/// ticket-level state, same as the table number — not in the cart, so
/// clearing the cart never silently drops who the sale was rung up for.
class CustomerPickerField extends ConsumerWidget {
  const CustomerPickerField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedCustomerIdProvider);
    final customer = selectedId == null
        ? null
        : ref.watch(customerByIdProvider(selectedId));

    // Stale-id guard: the selected customer may have been deleted on
    // another device mid-ticket. Clear the selection after this frame
    // rather than during build.
    if (selectedId != null && customer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ref.read(selectedCustomerIdProvider.notifier).state = null;
        }
      });
    }

    if (customer == null) {
      return OutlinedButton.icon(
        onPressed: () => showCustomerPickerDialog(context, ref),
        icon: const Icon(Icons.person_search_outlined, size: 18),
        label: const Text('Walk-in — attach a customer'),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.lg, vertical: Insets.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: context.semantic.hairline),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            child: Text(
              customer.name.isEmpty ? '?' : customer.name[0].toUpperCase(),
            ),
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  customer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  customer.phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => showCustomerPickerDialog(context, ref),
            child: const Text('Change'),
          ),
          IconButton(
            tooltip: 'Remove customer',
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => ref.read(selectedCustomerIdProvider.notifier).state = null,
          ),
        ],
      ),
    );
  }
}

/// Search/select a customer for the ticket being charged, with a pinned
/// "No customer" clear option and, when permitted, a "+ Add new customer"
/// entry that reuses the full customer form and immediately selects
/// whoever was just added — fully offline, since a new customer's id is
/// generated on-device (see `customer_entries.dart`'s doc comment).
Future<void> showCustomerPickerDialog(BuildContext context, WidgetRef ref) async {
  final form = context.formFactor;
  final available = MediaQuery.sizeOf(context).width - 80;
  final width = math.max(240.0, math.min(480.0, available));

  final selectedId = await showDialog<String?>(
    context: context,
    builder: (dialogContext) => _CustomerPickerDialog(width: width, autofocus: form.isDesktop),
  );

  if (selectedId == 'no-customer-sentinel') {
    ref.read(selectedCustomerIdProvider.notifier).state = null;
  } else if (selectedId != null) {
    ref.read(selectedCustomerIdProvider.notifier).state = selectedId;
  }
}

class _CustomerPickerDialog extends ConsumerStatefulWidget {
  const _CustomerPickerDialog({required this.width, required this.autofocus});

  final double width;
  final bool autofocus;

  @override
  ConsumerState<_CustomerPickerDialog> createState() => _CustomerPickerDialogState();
}

class _CustomerPickerDialogState extends ConsumerState<_CustomerPickerDialog> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final allCustomers = ref.watch(customersListProvider);
    final canCreate = ref.watch(hasPermissionProvider(AppPermissions.customersCreate));
    final query = _search.trim().toLowerCase();

    final matches = query.isEmpty
        ? (() {
            final sorted = [...allCustomers]
              ..sort((a, b) => (b.lastOrderAt ?? DateTime(1970))
                  .compareTo(a.lastOrderAt ?? DateTime(1970)));
            return sorted.take(20).toList();
          })()
        : allCustomers
            .where((c) =>
                c.name.toLowerCase().contains(query) || c.phone.toLowerCase().contains(query))
            .take(20)
            .toList();

    return AlertDialog(
      title: const Text('Attach a customer'),
      contentPadding: const EdgeInsets.fromLTRB(Insets.lg, Insets.md, Insets.lg, Insets.sm),
      content: SizedBox(
        width: widget.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              autofocus: widget.autofocus,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search name or phone',
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
            const SizedBox(height: Insets.sm),
            ListTile(
              leading: const Icon(Icons.person_off_outlined),
              title: const Text('No customer (walk-in)'),
              onTap: () => Navigator.of(context).pop('no-customer-sentinel'),
            ),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: matches.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: Insets.xl),
                      child: Center(
                        child: Text(
                          'No matching customers',
                          style: context.text.bodyMedium
                              ?.copyWith(color: context.colors.onSurfaceVariant),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final customer = matches[index];
                        return ListTile(
                          title: Text(customer.name),
                          subtitle: Text(customer.phone),
                          trailing: customer.lastOrderAt == null
                              ? null
                              : Text(
                                  Fmt.relativeDateTime(customer.lastOrderAt!),
                                  style: context.text.bodySmall
                                      ?.copyWith(color: context.colors.onSurfaceVariant),
                                ),
                          onTap: () => Navigator.of(context).pop(customer.id),
                        );
                      },
                    ),
            ),
            if (canCreate) ...[
              const Divider(height: 1),
              TextButton.icon(
                onPressed: () async {
                  final created = await showCustomerFormDialog(context);
                  if (created != null && context.mounted) {
                    Navigator.of(context).pop(created.id);
                  }
                },
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Add new customer'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
