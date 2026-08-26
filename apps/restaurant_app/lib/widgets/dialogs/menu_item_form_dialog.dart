import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_menu.dart';
import '../../models/menu_item.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/menu_item_form_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../labeled_form_field.dart';
import '../responsive_form_dialog.dart';
import '../section_label.dart';
import '../selectable_option_card.dart';

/// Opens the add/edit menu item form over the current screen.
Future<void> showMenuItemFormDialog(
  BuildContext context, {
  MenuItem? existingItem,
}) {
  return showResponsiveFormDialog<void>(
    context,
    builder: (_) => MenuItemFormDialog(itemId: existingItem?.id),
  );
}

/// Widget keys for the form's controls.
abstract final class MenuItemFormKeys {
  static const name = Key('menuItemForm.name');
  static const category = Key('menuItemForm.category');
  static const description = Key('menuItemForm.description');
  static const price = Key('menuItemForm.price');
  static const prepMinutes = Key('menuItemForm.prepMinutes');
  static const linkedInventoryItem = Key('menuItemForm.linkedInventoryItem');
  static const isAvailable = Key('menuItemForm.isAvailable');
  static const isPopular = Key('menuItemForm.isPopular');
  static const isArchived = Key('menuItemForm.isArchived');
  static const cancel = Key('menuItemForm.cancel');
  static const submit = Key('menuItemForm.submit');
}

class MenuItemFormDialog extends ConsumerStatefulWidget {
  const MenuItemFormDialog({super.key, this.itemId});

  final String? itemId;
  static const double dialogWidth = 640;

  @override
  ConsumerState<MenuItemFormDialog> createState() =>
      _MenuItemFormDialogState();
}

class _MenuItemFormDialogState extends ConsumerState<MenuItemFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _prepMinutes = TextEditingController();

  bool _seeded = false;

  AutoDisposeFamilyNotifierProvider<MenuItemFormNotifier, MenuItemFormState,
      String?> get _provider => menuItemFormProvider(widget.itemId);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;

    ref.invalidate(_provider);
    final state = ref.read(_provider);

    _name.text = state.name;
    _description.text = state.description;
    _price.text = state.price;
    _prepMinutes.text = state.prepMinutes;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _prepMinutes.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = ref.read(_provider).isEdit;
    final item = ref.read(_provider.notifier).save();

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          isEdit ? '${item.name} updated' : '${item.name} added to menu',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_provider);

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ResponsiveFormDialog(
        title: state.isEdit ? 'Edit menu item' : 'Add menu item',
        width: MenuItemFormDialog.dialogWidth,
        actions: [
          OutlinedButton(
            key: MenuItemFormKeys.cancel,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: MenuItemFormKeys.submit,
            onPressed: state.canSave ? _save : null,
            child: Text(state.isEdit ? 'Save changes' : 'Add item'),
          ),
        ],
        child: _fields(state),
      ),
    );
  }

  Widget _fields(MenuItemFormState state) {
    final notifier = ref.read(_provider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Basic info'),
        const SizedBox(height: Insets.md),
        LabeledFormField(
          label: 'Item name',
          isRequired: true,
          child: TextFormField(
            key: MenuItemFormKeys.name,
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'e.g. Margherita Pizza',
            ),
            onChanged: notifier.setName,
            validator: MenuItemFormState.validateName,
          ),
        ),
        const SizedBox(height: Insets.lg),
        _FieldPair(
          left: LabeledFormField(
            label: 'Category',
            isRequired: true,
            child: DropdownButtonFormField<String>(
              key: MenuItemFormKeys.category,
              initialValue:
                  state.categoryId.isEmpty ? null : state.categoryId,
              isExpanded: true,
              hint: const Text('Select'),
              items: [
                for (final category in MockMenu.categories)
                  DropdownMenuItem(
                    value: category.id,
                    child: Text(
                      category.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) =>
                  notifier.setCategory(value ?? ''),
              validator: MenuItemFormState.validateCategory,
            ),
          ),
          right: LabeledFormField(
            label: 'Price',
            isRequired: true,
            child: TextFormField(
              key: MenuItemFormKeys.price,
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: Fmt.currencySymbol,
              ),
              onChanged: notifier.setPrice,
              validator: MenuItemFormState.validatePrice,
            ),
          ),
        ),
        const SizedBox(height: Insets.lg),
        LabeledFormField(
          label: 'Description',
          child: TextFormField(
            key: MenuItemFormKeys.description,
            controller: _description,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'What makes this item special...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Insets.md),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Insets.md),
                borderSide: BorderSide(color: context.semantic.hairline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Insets.md),
                borderSide: BorderSide(
                  color: context.colors.primary,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: notifier.setDescription,
          ),
        ),
        const SizedBox(height: Insets.xl),
        const SectionLabel('Prep & availability'),
        const SizedBox(height: Insets.md),
        _FieldPair(
          left: LabeledFormField(
            label: 'Prep time',
            isRequired: true,
            child: TextFormField(
              key: MenuItemFormKeys.prepMinutes,
              controller: _prepMinutes,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: '10',
                suffixText: 'min',
              ),
              onChanged: notifier.setPrepMinutes,
              validator: MenuItemFormState.validatePrepMinutes,
            ),
          ),
          right: LabeledFormField(
            label: 'Linked inventory',
            child: DropdownButtonFormField<String?>(
              key: MenuItemFormKeys.linkedInventoryItem,
              initialValue: state.linkedInventoryItemId,
              isExpanded: true,
              hint: const Text('None'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('None'),
                ),
                for (final item in ref.watch(inventoryItemsProvider))
                  DropdownMenuItem(
                    value: item.id,
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: notifier.setLinkedInventoryItem,
            ),
          ),
        ),
        const SizedBox(height: Insets.xl),
        const SectionLabel('Status'),
        const SizedBox(height: Insets.md),
        SelectableOptionGrid(
          perRow: 3,
          children: [
            SelectableOptionCard(
              label: 'Available',
              icon: Icons.check_circle_outline_rounded,
              selected: state.isAvailable,
              onTap: () => notifier.setIsAvailable(true),
            ),
            SelectableOptionCard(
              label: 'Unavailable',
              icon: Icons.remove_circle_outline_rounded,
              selected: !state.isAvailable,
              onTap: () => notifier.setIsAvailable(false),
            ),
            SelectableOptionCard(
              label: 'Popular',
              icon: Icons.star_outline_rounded,
              selected: state.isPopular,
              onTap: () => notifier.setIsPopular(!state.isPopular),
            ),
          ],
        ),
        const SizedBox(height: Insets.lg),
        SelectableOptionGrid(
          perRow: 2,
          children: [
            SelectableOptionCard(
              label: 'Active',
              subtitle: 'On the menu',
              icon: Icons.check_circle_outline_rounded,
              selected: !state.isArchived,
              onTap: () => notifier.setArchived(false),
            ),
            SelectableOptionCard(
              label: 'Archived',
              subtitle: 'Hidden from menu',
              icon: Icons.archive_outlined,
              selected: state.isArchived,
              onTap: () => notifier.setArchived(true),
            ),
          ],
        ),
      ],
    );
  }
}

/// Two controls that sit side by side when there is room and stack when there
/// is not.
class _FieldPair extends StatelessWidget {
  const _FieldPair({required this.left, required this.right});

  final Widget left;
  final Widget right;

  static const double _stackBelow = 280;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _stackBelow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              left,
              const SizedBox(height: Insets.lg),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: Insets.md),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}
