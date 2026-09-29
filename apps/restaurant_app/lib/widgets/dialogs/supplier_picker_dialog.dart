/// Nested supplier picker: bottom sheet on mobile, centered popover/modal
/// with search on tablet/desktop.
///
/// Used twice from the cart dialog with the same component: bulk scope
/// (assign to all / unassigned) and per-item scope (override one line).
/// The parent cart dialog stays open underneath — this picker pops with the
/// chosen supplier id, and the caller writes it to the same cart field.
///
/// Accessibility (production requirement): autofocus the search field on
/// desktop, Tab/Shift+Tab stays inside via the dialog route's focus scope,
/// Esc closes (dialog route default), focus returns to the trigger on close
/// (Flutter restores it automatically through the route).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_strings.dart';
import '../../models/supplier.dart';
import '../../providers/suppliers_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';

/// Scope label shown in the picker header.
enum SupplierPickScope { bulk, perItem }

/// Opens the picker and returns the chosen supplier, or null on dismiss.
Future<Supplier?> showSupplierPicker({
  required BuildContext context,
  required SupplierPickScope scope,
  String? itemName,
  String? currentSupplierId,
}) {
  final form = context.formFactor;
  final content = _SupplierPickerContent(
    scope: scope,
    itemName: itemName,
    currentSupplierId: currentSupplierId,
  );
  if (form.isMobile) {
    return showModalBottomSheet<Supplier>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) =>
            _SheetBody(content: content, scrollController: controller),
      ),
    );
  }
  return showDialog<Supplier>(
    context: context,
    barrierDismissible: true,
    builder: (_) => Dialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 560),
        child: content,
      ),
    ),
  );
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.content, required this.scrollController});

  final Widget content;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: Insets.sm),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.outlineVariant,
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
          ),
          Flexible(child: content),
        ],
      ),
    );
  }
}

class _SupplierPickerContent extends ConsumerStatefulWidget {
  const _SupplierPickerContent({
    required this.scope,
    this.itemName,
    this.currentSupplierId,
  });

  final SupplierPickScope scope;
  final String? itemName;
  final String? currentSupplierId;

  @override
  ConsumerState<_SupplierPickerContent> createState() =>
      _SupplierPickerContentState();
}

class _SupplierPickerContentState
    extends ConsumerState<_SupplierPickerContent> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() => _query = _search.text.trim()));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(suppliersListProvider);
    final q = _query.toLowerCase();
    final filtered = q.isEmpty
        ? suppliers
        : suppliers
            .where((s) =>
                s.name.toLowerCase().contains(q) ||
                (s.phone ?? '').toLowerCase().contains(q))
            .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              Insets.lg, Insets.lg, Insets.sm, Insets.xs),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.scope == SupplierPickScope.bulk
                          ? AppStrings.reqPickerBulkTitle
                          : AppStrings.reqPickerItemTitle,
                      style: context.text.titleMedium,
                    ),
                    if (widget.itemName != null)
                      Text(
                        AppStrings.reqPickerForItem(widget.itemName ?? ''),
                        style: context.text.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: AppStrings.reqClose,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                // Min ~44px touch target on mobile/tablet.
                constraints: const BoxConstraints(
                    minWidth: 44, minHeight: 44),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
          // Always visible: desktop users with many suppliers type rather
          // than scroll/tap.
          child: SearchBar(
            controller: _search,
            hintText: AppStrings.reqSearchSuppliers,
            autoFocus: !context.isMobile,
            leading: const Icon(Icons.search_rounded),
            trailing: _query.isEmpty
                ? null
                : [
                    IconButton(
                      tooltip: AppStrings.reqClearSearch,
                      onPressed: () => _search.clear(),
                      icon: const Icon(Icons.clear_rounded),
                    ),
                  ],
          ),
        ),
        const SizedBox(height: Insets.sm),
        Flexible(
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(Insets.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.store_outlined,
                          size: 40,
                          color: context.colors.onSurfaceVariant),
                      const SizedBox(height: Insets.sm),
                      Text(
                        _query.isEmpty
                            ? AppStrings.reqNoSuppliers
                            : AppStrings.reqNoMatch(_query),
                        textAlign: TextAlign.center,
                        style: context.text.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final s = filtered[i];
                    final selected = s.id == widget.currentSupplierId;
                    return _SupplierRow(
                      supplier: s,
                      selected: selected,
                      onTap: () => Navigator.of(context).pop(s),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SupplierRow extends StatelessWidget {
  const _SupplierRow({
    required this.supplier,
    required this.selected,
    required this.onTap,
  });

  final Supplier supplier;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasWhatsapp =
        (supplier.phone ?? '').trim().isNotEmpty;
    return ListTile(
      // minVerticalPadding keeps rows ≥44px tall on touch devices.
      minVerticalPadding: Insets.md,
      leading: CircleAvatar(
        backgroundColor: selected
            ? context.colors.primaryContainer
            : context.colors.surfaceContainerHighest,
        child: Text(
          supplier.name.isEmpty
              ? '?'
              : supplier.name.characters.first.toUpperCase(),
          style: context.text.titleSmall,
        ),
      ),
      title: Text(supplier.name, overflow: TextOverflow.ellipsis),
      subtitle: supplier.phone == null
          ? Text(AppStrings.reqNoWhatsapp,
              style: TextStyle(color: context.semantic.warning))
          : Text(supplier.phone!,
              overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!hasWhatsapp)
            Tooltip(
              message: AppStrings.reqAddWhatsapp,
              child: Icon(Icons.warning_amber_rounded,
                  color: context.semantic.warning),
            ),
          if (selected)
            Icon(Icons.check_circle_rounded,
                color: context.colors.primary),
        ],
      ),
      onTap: onTap,
    );
  }
}
