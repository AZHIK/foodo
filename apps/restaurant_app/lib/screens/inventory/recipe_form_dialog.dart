import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/inventory_item.dart';
import '../../constants/app_strings.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/production_provider.dart';
import '../../services/inventory_api_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/dialogs/item_form_dialog.dart';
import '../../widgets/labeled_form_field.dart';
import '../../widgets/responsive_form_dialog.dart';
import 'stock_dialog_shared.dart';

/// Opens the recipe form: pass [recipe] to edit, or [sellable] to define a
/// new recipe for a menu item. Exactly one of the two decides the mode.
Future<void> showRecipeFormDialog(
  BuildContext context, {
  InventoryItem? sellable,
  RecipeDto? recipe,
}) {
  assert(
    (sellable == null) != (recipe == null),
    'pass either a sellable (add) or a recipe (edit), not both or neither',
  );
  return showResponsiveFormDialog<void>(
    context,
    builder: (_) => RecipeFormDialog(sellable: sellable, recipe: recipe),
  );
}

/// Widget keys for the form's controls. Ingredient rows are keyed per index
/// so tests can target "the second row's quantity" without depending on
/// item names that change per test.
abstract final class RecipeFormKeys {
  static const sellable = Key('recipeForm.sellable');
  static const name = Key('recipeForm.name');
  static const addIngredient = Key('recipeForm.addIngredient');
  static const cancel = Key('recipeForm.cancel');
  static const submit = Key('recipeForm.submit');
  static const delete = Key('recipeForm.delete');

  static Key ingredientItem(int index) =>
      Key('recipeForm.ingredientItem.$index');
  static Key ingredientQty(int index) => Key('recipeForm.ingredientQty.$index');
  static Key removeIngredient(int index) =>
      Key('recipeForm.removeIngredient.$index');
}

/// One editable ingredient row: a raw-item pick plus its per-unit quantity.
class _IngredientRow {
  _IngredientRow({this.rawCatalogId, String qty = ''})
      : qtyController = TextEditingController(text: qty);

  String? rawCatalogId;
  final TextEditingController qtyController;

  void dispose() => qtyController.dispose();
}

class RecipeFormDialog extends ConsumerStatefulWidget {
  const RecipeFormDialog({super.key, this.sellable, this.recipe});

  final InventoryItem? sellable;
  final RecipeDto? recipe;

  bool get isEdit => recipe != null;

  @override
  ConsumerState<RecipeFormDialog> createState() => _RecipeFormDialogState();
}

class _RecipeFormDialogState extends ConsumerState<RecipeFormDialog> {
  final _name = TextEditingController();
  final List<_IngredientRow> _rows = [];

  String? _sellableCatalogId;
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    final recipe = widget.recipe;
    if (recipe != null) {
      _name.text = recipe.name;
      _sellableCatalogId = recipe.sellableItemId;
      for (final component in recipe.components) {
        _rows.add(
          _IngredientRow(
            rawCatalogId: component.rawMaterialItemId,
            qty: _plain(double.parse(component.quantityRequired.toString())),
          ),
        );
      }
    } else {
      _sellableCatalogId = widget.sellable?.catalogItemId;
      _rows.add(_IngredientRow());
    }
  }

  @override
  void dispose() {
    _name.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  /// Raw materials (and dual-use lines) backed by backend items — the only
  /// lines the server accepts as ingredients.
  List<InventoryItem> _pickableIngredients() => [
        for (final item in ref.watch(groceryItemsProvider))
          if (item.catalogItemId != null) item,
      ];

  /// Menu lines backed by backend items — the only lines that can own a
  /// recipe. Only used when adding; editing never re-targets a recipe.
  List<InventoryItem> _pickableSellables() => [
        for (final item in ref.watch(menuCatalogItemsProvider))
          if (item.catalogItemId != null) item,
      ];

  String? _duplicateId() {
    final seen = <String>{};
    for (final row in _rows) {
      final id = row.rawCatalogId;
      if (id == null) continue;
      if (!seen.add(id)) return id;
    }
    return null;
  }

  String? get _error {
    final filled = [
      for (final row in _rows)
        if (row.rawCatalogId != null) row,
    ];
    if (filled.isEmpty) return null;
    for (final row in filled) {
      final qty = parseQuantity(row.qtyController.text);
      if (qty == null || qty <= 0) {
        return AppStrings.everyIngredientPositive;
      }
    }
    if (_duplicateId() != null) {
      return AppStrings.ingredientOnce;
    }
    return null;
  }

  bool get _canSubmit {
    if (_saving || _deleting) return false;
    if (_sellableCatalogId == null) return false;
    final filled = [
      for (final row in _rows)
        if (row.rawCatalogId != null) row,
    ];
    if (filled.isEmpty) return false;
    return _error == null;
  }

  List<RecipeComponentInput> _inputs() => [
        for (final row in _rows)
          if (row.rawCatalogId != null)
            RecipeComponentInput(
              rawMaterialItemId: row.rawCatalogId!,
              quantityRequired: Decimal.parse(
                parseQuantity(row.qtyController.text).toString(),
              ),
            ),
      ];

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final recipeId = widget.recipe?.id;
    final nameText = _name.text.trim();

    setState(() => _saving = true);
    try {
      final saved = recipeId == null
          ? await ref.read(recipesCatalogProvider.notifier).createRecipe(
                sellableItemId: _sellableCatalogId!,
                name: nameText.isEmpty ? null : nameText,
                components: _inputs(),
              )
          : await ref.read(recipesCatalogProvider.notifier).updateRecipe(
                recipeId: recipeId,
                // Blank keeps the server-side name (the backend treats null
                // as "don't rename"); only a typed value renames.
                name: nameText.isEmpty ? null : nameText,
                components: _inputs(),
              );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppStrings.recipeSaved(saved.name, recipeId != null)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(AppStrings.saveFailed(e))));
    }
  }

  Future<void> _delete() async {
    final recipe = widget.recipe;
    if (recipe == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.deleteRecipeTitle),
        content: Text(
          AppStrings.deleteRecipeBody(
            recipe.name,
            recipe.components.length,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppStrings.keepAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(AppStrings.deleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _deleting = true);
    try {
      await ref.read(recipesCatalogProvider.notifier).deleteRecipe(recipe.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.recipeDeletedLine(recipe.name))),
      );
    } catch (e) {
      // A 409 here names the blocker ("production events were recorded
      // against it") — shown verbatim like every other backend message.
      if (!mounted) return;
      setState(() => _deleting = false);
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.deleteFailed(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEdit;

    return ResponsiveFormDialog(
      title: isEdit ? AppStrings.editRecipeTitle : AppStrings.addRecipeTitle,
      // Same width as the item form — recipe editing reads as family.
      width: ItemFormDialog.dialogWidth,
      actions: [
        OutlinedButton(
          key: RecipeFormKeys.cancel,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.cancel),
        ),
        if (isEdit)
          TextButton(
            key: RecipeFormKeys.delete,
            onPressed: _deleting ? null : _delete,
            style: TextButton.styleFrom(
              foregroundColor: context.semantic.warning,
            ),
            child: Text(AppStrings.deleteAction),
          ),
        FilledButton(
          key: RecipeFormKeys.submit,
          onPressed: _canSubmit ? _submit : null,
          child: Text(
            isEdit ? AppStrings.saveChanges : AppStrings.addRecipeAction,
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isEdit) ...[
            LabeledFormField(
              label: AppStrings.menuItemProduces,
              helper: AppStrings.recipeProducesHelper,
              isRequired: true,
              child: Builder(
                builder: (context) {
                  final sellables = _pickableSellables();
                  final initial = sellables.any(
                    (i) => i.catalogItemId == _sellableCatalogId,
                  )
                      ? _sellableCatalogId
                      : null;
                  return DropdownButtonFormField<String>(
                    key: RecipeFormKeys.sellable,
                    initialValue: initial,
                    isExpanded: true,
                    hint: Text(AppStrings.selectHint),
                    items: [
                      for (final item in sellables)
                        DropdownMenuItem(
                          value: item.catalogItemId,
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _sellableCatalogId = value),
                  );
                },
              ),
            ),
            const SizedBox(height: Insets.lg),
          ],
          LabeledFormField(
            label: AppStrings.recipeName,
            helper: isEdit
                ? AppStrings.recipeNameHelper
                : AppStrings.recipeNameDefault,
            child: TextFormField(
              key: RecipeFormKeys.name,
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration:
                  InputDecoration(hintText: AppStrings.recipeNameExample),
            ),
          ),
          const SizedBox(height: Insets.xl),
          _SectionHeader(
            title: AppStrings.ingredientsSection,
            onAdd: () => setState(() => _rows.add(_IngredientRow())),
          ),
          const SizedBox(height: Insets.md),
          for (var i = 0; i < _rows.length; i++) ...[
            if (i > 0) const SizedBox(height: Insets.md),
            _IngredientEditor(
              index: i,
              row: _rows[i],
              ingredients: _pickableIngredients(),
              removable: _rows.length > 1,
              onChanged: () => setState(() {}),
              onRemove: () => setState(() {
                _rows.removeAt(i).dispose();
              }),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: Insets.md),
            Text(
              _error!,
              style: context.text.bodySmall?.copyWith(
                color: context.semantic.warning,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Ingredients" plus its add control on one row.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onAdd});

  final String title;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: context.text.titleSmall),
        ),
        OutlinedButton.icon(
          key: RecipeFormKeys.addIngredient,
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded, size: 16),
          label: Text(AppStrings.addIngredient),
        ),
      ],
    );
  }
}

/// One ingredient row: raw-item picker, per-unit quantity, remove control.
class _IngredientEditor extends StatelessWidget {
  const _IngredientEditor({
    required this.index,
    required this.row,
    required this.ingredients,
    required this.removable,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final _IngredientRow row;
  final List<InventoryItem> ingredients;
  final bool removable;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    InventoryItem? selected;
    for (final item in ingredients) {
      if (item.catalogItemId == row.rawCatalogId) selected = item;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<String>(
            key: RecipeFormKeys.ingredientItem(index),
            initialValue: selected?.catalogItemId,
            isExpanded: true,
            hint: Text(AppStrings.ingredientHint),
            items: [
              for (final item in ingredients)
                DropdownMenuItem(
                  value: item.catalogItemId,
                  child: Text(
                    AppStrings.ingredientOption(item.name, item.unit),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) {
              row.rawCatalogId = value;
              onChanged();
            },
          ),
        ),
        const SizedBox(width: Insets.md),
        Expanded(
          flex: 2,
          child: TextFormField(
            key: RecipeFormKeys.ingredientQty(index),
            controller: row.qtyController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
            ],
            decoration: InputDecoration(
              hintText: AppStrings.quantityHint,
              suffixText: selected?.unit,
            ),
            onChanged: (_) => onChanged(),
          ),
        ),
        if (removable)
          IconButton(
            key: RecipeFormKeys.removeIngredient(index),
            tooltip: AppStrings.removeIngredient,
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
      ],
    );
  }
}

/// Display-plain quantity for prefilling a field: `2`, not `2.0`.
String _plain(double value) =>
    value == value.roundToDouble() ? value.round().toString() : '$value';
