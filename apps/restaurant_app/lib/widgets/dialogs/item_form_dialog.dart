import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/inventory_item.dart';
import '../../constants/app_strings.dart';
import '../../providers/categories_provider.dart';
import '../../providers/item_form_provider.dart';
import '../../providers/units_provider.dart';
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
  static const sellingPrice = Key('itemForm.sellingPrice');
  static const lowStockAlert = Key('itemForm.lowStockAlert');
  static const reorderQuantity = Key('itemForm.reorderQuantity');
  static const allowNegativeStock = Key('itemForm.allowNegativeStock');
  static const stock = Key('itemForm.stock');
  static const unit = Key('itemForm.unit');
  static const trackStock = Key('itemForm.trackStock');
  static const cancel = Key('itemForm.cancel');
  static const submit = Key('itemForm.submit');

  /// The entry-choice step's three options.
  static const chooseGrocery = Key('itemForm.chooseGrocery');
  static const chooseMenuItem = Key('itemForm.chooseMenuItem');
  static const chooseBoth = Key('itemForm.chooseBoth');
  static const changeType = Key('itemForm.changeType');
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
  final _sellingPrice = TextEditingController();
  final _lowStock = TextEditingController();
  final _reorderQuantity = TextEditingController();
  final _stock = TextEditingController();
  final _description = TextEditingController();

  bool _seeded = false;
  bool _saving = false;

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

    // Categories/units each sync themselves exactly once per app session
    // (on the first widget that reads their provider) — reopening this form
    // later in the same session would otherwise keep showing whatever
    // taxonomy existed at that first read, even after someone adds a new
    // category/unit on the backend. Re-syncing every time the form opens is
    // the one place staleness here actually bites (picking a since-removed
    // option, or not seeing a newly added one), so it's worth the extra
    // network round trip — the dropdowns keep showing cached data while
    // this resolves, no flash of empty state.
    //
    // `refresh()` writes `state` synchronously (before its first `await`,
    // to flip to `AsyncLoading`), and `didChangeDependencies` still counts
    // as build phase — Riverpod forbids a provider write there even via an
    // unawaited call. `Future(() {...})` defers the call to a fresh
    // microtask, after this build finishes.
    Future(() {
      if (!mounted) return;
      unawaited(ref.read(categoriesProvider.notifier).refresh());
      unawaited(ref.read(unitsProvider.notifier).refresh());
    });

    _name.text = state.name;
    _sku.text = state.sku;
    _unitCost.text = state.unitCost;
    _sellingPrice.text = state.sellingPrice;
    _lowStock.text = state.lowStockAlert;
    _reorderQuantity.text = state.reorderQuantity;
    _stock.text = state.stock;
    _description.text = state.description;
  }

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _unitCost.dispose();
    _sellingPrice.dispose();
    _lowStock.dispose();
    _reorderQuantity.dispose();
    _stock.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // The button is already disabled on invalid state; this second pass is what
    // paints the inline errors if anything slipped through.
    if (!_formKey.currentState!.validate()) return;

    final isEdit = ref.read(_provider).isEdit;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _saving = true);
    try {
      final item = await ref.read(_provider.notifier).save();
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? '${item.name} updated' : '${item.name} added to inventory',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(AppStrings.saveFailed(e))));
    }
  }

  /// True only while adding a new item that has not been through the
  /// Grocery/Menu item/Both entry choice yet — an existing item always has a
  /// real [ItemFormState.itemType], so editing never shows the chooser.
  bool _chooserMode(ItemFormState state) => !state.isEdit && state.itemType.isEmpty;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_provider);
    final isMobile = MediaQuery.sizeOf(context).width < Breakpoints.tablet;
    final chooserMode = _chooserMode(state);

    return Form(
      key: _formKey,
      // Errors appear once a field has been touched, not the instant the empty
      // form opens.
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ResponsiveFormDialog(
        title: state.isEdit ? AppStrings.editItemTitle : AppStrings.addItemTitle,
        width: ItemFormDialog.dialogWidth,
        actions: [
          OutlinedButton(
            key: ItemFormKeys.cancel,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            key: ItemFormKeys.submit,
            onPressed: state.canSave && !_saving ? _save : null,
            child: Text(
              state.isEdit ? AppStrings.saveChanges : AppStrings.addItemTitle,
            ),
          ),
        ],
        child: chooserMode
            ? _typeChoiceStep(context)
            : (isMobile ? _mobileBody(state) : _wideBody(state)),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Entry choice
  // -------------------------------------------------------------------

  /// "Grocery or Menu item?" — the first thing an add-item flow asks, rather
  /// than a generic item-type dropdown buried among other fields. The less
  /// common "both bought and sold" case is still one tap away, just not the
  /// lead option.
  Widget _typeChoiceStep(BuildContext context) {
    final notifier = ref.read(_provider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(AppStrings.whatAdding, style: context.text.titleMedium),
        const SizedBox(height: Insets.xs),
        Text(
          AppStrings.chooserSubtitle,
          style: context.text.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Insets.lg),
        SelectableOptionGrid(
          perRow: 2,
          children: [
            SelectableOptionCard(
              key: ItemFormKeys.chooseGrocery,
              label: AppStrings.groceryOption,
              subtitle: AppStrings.groceryOptionBlurb,
              icon: Icons.shopping_basket_outlined,
              selected: false,
              onTap: () => notifier.chooseType('raw_material'),
            ),
            SelectableOptionCard(
              key: ItemFormKeys.chooseMenuItem,
              label: AppStrings.menuItemOption,
              subtitle: AppStrings.menuItemOptionBlurb,
              icon: Icons.restaurant_menu_rounded,
              selected: false,
              onTap: () => notifier.chooseType('sellable'),
            ),
          ],
        ),
        const SizedBox(height: Insets.lg),
        Center(
          child: TextButton.icon(
            key: ItemFormKeys.chooseBoth,
            onPressed: () => notifier.chooseType('both'),
            icon: const Icon(Icons.swap_horiz_rounded, size: 16),
            label: Text(AppStrings.bothOptionBlurb),
          ),
        ),
      ],
    );
  }

  /// Sits above the fields once a type has been chosen, naming the choice and
  /// offering a way back to the chooser without losing anything else typed.
  Widget _typeSummaryBar(BuildContext context, ItemFormState state) {
    final (label, icon) = switch (state.itemType) {
      'raw_material' => (AppStrings.groceryOption, Icons.shopping_basket_outlined),
      'sellable' => (AppStrings.menuItemOption, Icons.restaurant_menu_rounded),
      _ => (AppStrings.bothType, Icons.swap_horiz_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.lg, vertical: Insets.sm),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: context.semantic.hairline),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.colors.onSurfaceVariant),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Text(label, style: context.text.labelLarge),
          ),
          TextButton(
            key: ItemFormKeys.changeType,
            onPressed: () => ref.read(_provider.notifier).resetType(),
            child: Text(AppStrings.changeType),
          ),
        ],
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
        if (!state.isEdit) ...[
          _typeSummaryBar(context, state),
          const SizedBox(height: Insets.lg),
        ],
        SectionLabel(AppStrings.basicInfo),
        const SizedBox(height: Insets.md),
        LabeledFormField(
          label: AppStrings.itemNameLabel,
          isRequired: true,
          child: TextFormField(
            key: ItemFormKeys.name,
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: AppStrings.itemNameExample,
            ),
            onChanged: notifier.setName,
            validator: ItemFormState.validateName,
          ),
        ),
        const SizedBox(height: Insets.lg),
        _FieldPair(
          left: LabeledFormField(
            label: AppStrings.categoryLabel,
            isRequired: true,
            child: DropdownButtonFormField<String>(
              key: ItemFormKeys.category,
              initialValue: state.categoryId.isEmpty ? null : state.categoryId,
              // Without this the menu sizes to its widest entry and pushes past
              // the field instead of ellipsising inside it.
              isExpanded: true,
              hint: Text(AppStrings.selectOption),
              items: [
                for (final category in ref.watch(categoriesListProvider))
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
            label: AppStrings.skuLabel2,
            helper: state.isEdit ? null : AppStrings.skuHelper,
            child: TextFormField(
              key: ItemFormKeys.sku,
              controller: _sku,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              decoration:
                  InputDecoration(hintText: AppStrings.skuExample),
              onChanged: notifier.setSku,
            ),
          ),
        ),
        const SizedBox(height: Insets.lg),
        LabeledFormField(
          label: AppStrings.descriptionLabel,
          helper: AppStrings.descriptionHelper,
          child: TextFormField(
            key: ItemFormKeys.description,
            controller: _description,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: AppStrings.descriptionExample,
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
        SectionLabel(AppStrings.pricingStock),
        const SizedBox(height: Insets.md),
        // The toggle governs the fields under it, so it comes before them —
        // switching it off after typing a threshold reads as a mistake.
        _SwitchTile(
          key: ItemFormKeys.trackStock,
          title: AppStrings.trackStockLabel,
          subtitleOn: AppStrings.trackStockOn,
          subtitleOff: AppStrings.trackStockOff,
          value: state.trackStock,
          onChanged: notifier.setTrackStock,
        ),
        const SizedBox(height: Insets.lg),
        _FieldPair(
          left: LabeledFormField(
            label: AppStrings.unitCostLabel,
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
                hintText: AppStrings.moneyHint,
                prefixText: Fmt.currencySymbol,
              ),
              onChanged: notifier.setUnitCost,
              validator: ItemFormState.validateUnitCost,
            ),
          ),
          right: LabeledFormField(
            label: AppStrings.lowAlertLabel,
            enabled: state.trackStock,
            helper: state.trackStock ? AppStrings.lowAlertHelper : null,
            child: TextFormField(
              key: ItemFormKeys.lowStockAlert,
              controller: _lowStock,
              // Disabled rather than removed: hiding it would reflow the row
              // and shift the unit cost field out from under the cursor.
              enabled: state.trackStock,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(hintText: AppStrings.quantityHint),
              onChanged: notifier.setLowStockAlert,
              validator: (value) => state.trackStock
                  ? ItemFormState.validateLowStockAlert(value)
                  : null,
            ),
          ),
        ),
        if (state.trackStock) ...[
          const SizedBox(height: Insets.lg),
          LabeledFormField(
            label: AppStrings.reorderQtyLabel,
            helper: AppStrings.reorderQtyHelper,
            child: TextFormField(
              key: ItemFormKeys.reorderQuantity,
              controller: _reorderQuantity,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(hintText: AppStrings.quantityHint),
              onChanged: notifier.setReorderQuantity,
              validator: ItemFormState.validateReorderQuantity,
            ),
          ),
          const SizedBox(height: Insets.lg),
          _SwitchTile(
            key: ItemFormKeys.allowNegativeStock,
            title: AppStrings.allowNegativeLabel,
            subtitleOn: AppStrings.allowNegativeOn,
            subtitleOff: AppStrings.allowNegativeOff,
            value: state.allowNegativeStock,
            onChanged: notifier.setAllowNegativeStock,
          ),
        ],
        const SizedBox(height: Insets.lg),
        // Disabled rather than hidden for a raw material — same reasoning as
        // the low-stock alert field above: hiding it would reflow the row
        // around it, and a grocery-only item can still be reclassified later.
        LabeledFormField(
          label: AppStrings.sellingPrice,
          enabled: state.itemType != 'raw_material',
          helper: state.itemType == 'raw_material'
              ? AppStrings.priceGroceryHint
              : AppStrings.priceRequiredTill,
          child: TextFormField(
            key: ItemFormKeys.sellingPrice,
            controller: _sellingPrice,
            enabled: state.itemType != 'raw_material',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              hintText: AppStrings.moneyHint,
              prefixText: Fmt.currencySymbol,
            ),
            onChanged: notifier.setSellingPrice,
            validator: (value) => ItemFormState.validateSellingPrice(
              value,
              isRequired: state.itemType != 'raw_material',
            ),
          ),
        ),

        if (state.trackStock) ...[
          const SizedBox(height: Insets.lg),
          _FieldPair(
            left: state.isEdit
                ? _ReadOnlyStock(value: state.stock, unit: state.unit)
                : LabeledFormField(
                    label: AppStrings.openingStock,
                    helper: AppStrings.openingStockHelper,
                    child: TextFormField(
                      key: ItemFormKeys.stock,
                      controller: _stock,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(hintText: AppStrings.quantityHint),
                      onChanged: notifier.setStock,
                      validator: ItemFormState.validateStock,
                    ),
                  ),
            right: LabeledFormField(
              label: AppStrings.unitLabel,
              // Falls back to a single option carrying the current value
              // while the real taxonomy is still syncing (or offline with
              // an empty cache) — mirrors the old MockInventory.units
              // fallback shape without hardcoding a fake unit list.
              child: Builder(builder: (_) {
                final abbreviations = [
                  for (final unit in ref.watch(unitsListProvider)) unit.abbreviation,
                ];
                final options = abbreviations.isEmpty ? [state.unit] : abbreviations;
                return DropdownButtonFormField<String>(
                  key: ItemFormKeys.unit,
                  initialValue: options.contains(state.unit) ? state.unit : options.first,
                  isExpanded: true,
                  items: [
                    for (final unit in options)
                      DropdownMenuItem(value: unit, child: Text(unit)),
                  ],
                  onChanged: (value) => notifier.setUnit(value ?? state.unit),
                );
              }),
            ),
          ),
        ],

        const SizedBox(height: Insets.xl),
        SectionLabel(AppStrings.statusSection),
        const SizedBox(height: Insets.md),
        SelectableOptionGrid(
          perRow: 2,
          children: [
            SelectableOptionCard(
              label: AppStrings.activeOption,
              subtitle: AppStrings.activeOptionBlurb,
              icon: Icons.check_circle_outline_rounded,
              selected: !state.isArchived,
              onTap: () => notifier.setArchived(false),
            ),
            SelectableOptionCard(
              label: AppStrings.archivedOption,
              subtitle: AppStrings.archivedOptionBlurb,
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
        SectionLabel(AppStrings.photoSection),
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
      label: AppStrings.currentStockReadonly,
      helper: AppStrings.adjustFlowHint,
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
                AppStrings.stockValue(value, unit),
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

/// A labelled on/off row in its own bordered card — the shared shape behind
/// both the track-stock and allow-negative-stock toggles, so a second
/// checkbox-like setting did not mean inventing a second widget.
class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    super.key,
    required this.title,
    required this.subtitleOn,
    required this.subtitleOff,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitleOn;
  final String subtitleOff;
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
        title: Text(title, style: context.text.bodyMedium),
        subtitle: Text(
          value ? subtitleOn : subtitleOff,
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
