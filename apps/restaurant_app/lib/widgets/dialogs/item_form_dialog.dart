import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_inventory.dart';
import '../../models/inventory_item.dart';
import '../../providers/item_form_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../image_upload_field.dart';
import '../labeled_form_field.dart';
import '../responsive_form_dialog.dart';
import '../section_label.dart';
import '../selectable_option_card.dart';

/// Opens the add/edit item form over the current screen.
///
/// The single entry point for both modes and both presentations — pass
/// [existingItem] to edit, omit it to add, and the breakpoint is handled
/// inside. Callers never branch on screen width, and there is no route: the
/// form is a layer over the inventory list, and closing it returns the user to
/// exactly the scroll position, filter and page they left.
Future<void> showItemFormDialog(
  BuildContext context, {
  InventoryItem? existingItem,
}) {
  return showResponsiveFormDialog<void>(
    context,
    builder: (_) => ItemFormDialog(itemId: existingItem?.id),
  );
}

/// Widget keys for the form's controls.
///
/// The labels sit outside the inputs, so there is no `labelText` for a test to
/// find a field by. Naming them here keeps the finders from depending on hint
/// copy, which is the sort of thing that gets reworded.
abstract final class ItemFormKeys {
  static const name = Key('itemForm.name');
  static const sku = Key('itemForm.sku');
  static const category = Key('itemForm.category');
  static const description = Key('itemForm.description');
  static const unitCost = Key('itemForm.unitCost');
  static const lowStockAlert = Key('itemForm.lowStockAlert');
  static const stock = Key('itemForm.stock');
  static const unit = Key('itemForm.unit');
  static const trackStock = Key('itemForm.trackStock');
  static const cancel = Key('itemForm.cancel');
  static const submit = Key('itemForm.submit');
}

/// The form itself. Prefer [showItemFormDialog] — this is public only so tests
/// and future callers can mount it directly.
class ItemFormDialog extends ConsumerStatefulWidget {
  const ItemFormDialog({super.key, this.itemId});

  /// Id of the item being edited, or null to add a new one.
  final String? itemId;

  /// Wide enough for the photo column and two fields beside it without either
  /// feeling squeezed. A confirmation dialog's width would put three controls
  /// on top of each other.
  static const double dialogWidth = 640;

  /// The photo column on tablet and desktop.
  static const double _photoColumn = 190;

  /// On a phone the dropzone goes full-width, but capped: a 360px square would
  /// push every field below the fold.
  static const double _photoMobile = 172;

  @override
  ConsumerState<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends ConsumerState<ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // The controllers hold what the user is typing; the notifier holds the
  // committed value. One-way, controller to notifier — nothing in the form
  // rewrites a field's text underneath the cursor, so no listener is needed
  // in the other direction.
  final _name = TextEditingController();
  final _sku = TextEditingController();
  final _unitCost = TextEditingController();
  final _lowStock = TextEditingController();
  final _stock = TextEditingController();
  final _description = TextEditingController();

  bool _seeded = false;

  AutoDisposeFamilyNotifierProvider<ItemFormNotifier, ItemFormState, String?>
  get _provider => itemFormProvider(widget.itemId);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Not `initState`: `ref` reaches for an inherited widget, which is not
    // available that early. Guarded because this also runs on every resize.
    if (_seeded) return;
    _seeded = true;

    // autoDispose tears the draft down when the last listener goes, but it does
    // so asynchronously — reopening the form in the same frame it closed would
    // otherwise inherit the abandoned edit. Invalidating first guarantees the
    // read below builds from the stored item.
    ref.invalidate(_provider);
    final state = ref.read(_provider);

    _name.text = state.name;
    _sku.text = state.sku;
    _unitCost.text = state.unitCost;
    _lowStock.text = state.lowStockAlert;
    _stock.text = state.stock;
    _description.text = state.description;
  }

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _unitCost.dispose();
    _lowStock.dispose();
    _stock.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    // The button is already disabled on invalid state; this second pass is what
    // paints the inline errors if anything slipped through.
    if (!_formKey.currentState!.validate()) return;

    final isEdit = ref.read(_provider).isEdit;
    final item = ref.read(_provider.notifier).save();

    // Grabbed before the pop: the dialog's own context is defunct afterwards.
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          isEdit ? '${item.name} updated' : '${item.name} added to inventory',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_provider);
    final isMobile = MediaQuery.sizeOf(context).width < Breakpoints.tablet;

    return Form(
      key: _formKey,
      // Errors appear once a field has been touched, not the instant the empty
      // form opens.
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ResponsiveFormDialog(
        title: state.isEdit ? 'Edit item' : 'Add item',
        width: ItemFormDialog.dialogWidth,
        actions: [
          OutlinedButton(
            key: ItemFormKeys.cancel,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: ItemFormKeys.submit,
            onPressed: state.canSave ? _save : null,
            child: Text(state.isEdit ? 'Save changes' : 'Add item'),
          ),
        ],
        child: isMobile ? _mobileBody(state) : _wideBody(state),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Layouts
  // -------------------------------------------------------------------

  /// Photo pinned to a fixed left column, everything else flowing beside it.
  Widget _wideBody(ItemFormState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: ItemFormDialog._photoColumn,
          child: _PhotoSection(
            state: state,
            size: ItemFormDialog._photoColumn,
            notifier: ref.read(_provider.notifier),
          ),
        ),
        const SizedBox(width: Insets.xl),
        Expanded(child: _fields(state)),
      ],
    );
  }

  /// One column, sections in reading order, the dropzone centred at a size that
  /// leaves room for the fields under it.
  Widget _mobileBody(ItemFormState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PhotoSection(
          state: state,
          size: ItemFormDialog._photoMobile,
          centered: true,
          notifier: ref.read(_provider.notifier),
        ),
        const SizedBox(height: Insets.xl),
        _fields(state),
      ],
    );
  }

  Widget _fields(ItemFormState state) {
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
            key: ItemFormKeys.name,
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'e.g. Heirloom Tomatoes',
            ),
            onChanged: notifier.setName,
            validator: ItemFormState.validateName,
          ),
        ),
        const SizedBox(height: Insets.lg),
        _FieldPair(
          left: LabeledFormField(
            label: 'Category',
            isRequired: true,
            child: DropdownButtonFormField<String>(
              key: ItemFormKeys.category,
              initialValue: state.categoryId.isEmpty ? null : state.categoryId,
              // Without this the menu sizes to its widest entry and pushes past
              // the field instead of ellipsising inside it.
              isExpanded: true,
              hint: const Text('Select'),
              items: [
                for (final category in MockInventory.categories)
                  DropdownMenuItem(
                    value: category.id,
                    child: Text(
                      category.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => notifier.setCategory(value ?? ''),
              validator: ItemFormState.validateCategory,
            ),
          ),
          right: LabeledFormField(
            label: 'SKU',
            helper: state.isEdit ? null : 'Generated if left blank',
            child: TextFormField(
              key: ItemFormKeys.sku,
              controller: _sku,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'PRD-1001'),
              onChanged: notifier.setSku,
            ),
          ),
        ),
        const SizedBox(height: Insets.lg),
        LabeledFormField(
          label: 'Description',
          helper: 'Shown on the item\'s detail page',
          child: TextFormField(
            key: ItemFormKeys.description,
            controller: _description,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Grade, origin, prep notes…',
              // The theme's pill border is drawn for single-line inputs and
              // looks wrong wrapped around a two-line box.
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Radii.md),
                borderSide: BorderSide(color: context.semantic.hairline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Radii.md),
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
        const SectionLabel('Pricing & stock'),
        const SizedBox(height: Insets.md),
        // The toggle governs the fields under it, so it comes before them —
        // switching it off after typing a threshold reads as a mistake.
        _TrackStockToggle(
          key: ItemFormKeys.trackStock,
          value: state.trackStock,
          onChanged: notifier.setTrackStock,
        ),
        const SizedBox(height: Insets.lg),
        _FieldPair(
          left: LabeledFormField(
            label: 'Unit cost',
            isRequired: true,
            child: TextFormField(
              key: ItemFormKeys.unitCost,
              controller: _unitCost,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: Fmt.currencySymbol,
              ),
              onChanged: notifier.setUnitCost,
              validator: ItemFormState.validateUnitCost,
            ),
          ),
          right: LabeledFormField(
            label: 'Low stock alert',
            enabled: state.trackStock,
            helper: state.trackStock ? 'Warn at or below this' : null,
            child: TextFormField(
              key: ItemFormKeys.lowStockAlert,
              controller: _lowStock,
              // Disabled rather than removed: hiding it would reflow the row
              // and shift the unit cost field out from under the cursor.
              enabled: state.trackStock,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: '0'),
              onChanged: notifier.setLowStockAlert,
              validator: (value) => state.trackStock
                  ? ItemFormState.validateLowStockAlert(value)
                  : null,
            ),
          ),
        ),
        if (state.trackStock) ...[
          const SizedBox(height: Insets.lg),
          _FieldPair(
            left: state.isEdit
                ? _ReadOnlyStock(value: state.stock, unit: state.unit)
                : LabeledFormField(
                    label: 'Opening stock',
                    helper: 'What is on the shelf today',
                    child: TextFormField(
                      key: ItemFormKeys.stock,
                      controller: _stock,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(hintText: '0'),
                      onChanged: notifier.setStock,
                      validator: ItemFormState.validateStock,
                    ),
                  ),
            right: LabeledFormField(
              label: 'Unit',
              child: DropdownButtonFormField<String>(
                key: ItemFormKeys.unit,
                initialValue: MockInventory.units.contains(state.unit)
                    ? state.unit
                    : MockInventory.units.first,
                isExpanded: true,
                items: [
                  for (final unit in MockInventory.units)
                    DropdownMenuItem(value: unit, child: Text(unit)),
                ],
                onChanged: (value) => notifier.setUnit(value ?? state.unit),
              ),
            ),
          ),
        ],

        const SizedBox(height: Insets.xl),
        const SectionLabel('Status'),
        const SizedBox(height: Insets.md),
        SelectableOptionGrid(
          perRow: 2,
          children: [
            SelectableOptionCard(
              label: 'Active',
              subtitle: 'Counted and reorderable',
              icon: Icons.check_circle_outline_rounded,
              selected: !state.isArchived,
              onTap: () => notifier.setArchived(false),
            ),
            SelectableOptionCard(
              label: 'Archived',
              subtitle: 'Kept for reporting only',
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

/// The "Photo" block: label plus the square dropzone.
class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.state,
    required this.size,
    required this.notifier,
    this.centered = false,
  });

  final ItemFormState state;
  final double size;
  final ItemFormNotifier notifier;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final field = ImageUploadField(
      image: state.imageBytes,
      size: size,
      onPicked: notifier.setImage,
      onRemoved: notifier.clearImage,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Photo'),
        const SizedBox(height: Insets.md),
        if (centered) Center(child: field) else field,
        if (state.image != null) ...[
          const SizedBox(height: Insets.sm),
          Text(
            state.image!.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Two controls that sit side by side when there is room and stack when there
/// is not — the guard that keeps a 360px phone from overflowing the row.
class _FieldPair extends StatelessWidget {
  const _FieldPair({required this.left, required this.right});

  final Widget left;
  final Widget right;

  /// Below this each half would be narrower than a usable input.
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

/// Current stock in edit mode: shown, not editable.
///
/// A count is a physical fact about a shelf. Letting it be retyped in the same
/// form as a price edit loses the reason it changed, which is the one thing a
/// stock audit needs — so it routes through Stock Adjust instead.
class _ReadOnlyStock extends StatelessWidget {
  const _ReadOnlyStock({required this.value, required this.unit});

  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return LabeledFormField(
      label: 'Current stock',
      helper: 'Changes go through Stock Adjust',
      child: Container(
        // Matches the height of a real input so the row's two halves line up.
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: context.semantic.hairline),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 15,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: Insets.sm),
            Expanded(
              child: Text(
                '$value $unit',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackStockToggle extends StatelessWidget {
  const _TrackStockToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: context.semantic.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        dense: true,
        // Comfortably past the 44px touch floor, and the whole row is the
        // target rather than just the switch.
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.xs,
        ),
        title: Text(
          'Track stock for this item',
          style: context.text.bodyMedium,
        ),
        subtitle: Text(
          value
              ? 'Counted against a low-stock threshold'
              : 'No counts, no low-stock warnings',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
