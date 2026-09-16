import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/inventory_provider.dart';
import '../../constants/app_strings.dart';
import '../../providers/production_provider.dart';
import '../../services/inventory_api_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../../widgets/labeled_form_field.dart';
import '../../widgets/responsive_form_dialog.dart';
import 'stock_dialog_shared.dart';

/// Opens the record-production dialog for [recipe].
///
/// The recipe comes from the menu-item detail screen (via
/// `RecipesCatalogNotifier.recipeForSellable`), so this dialog never picks
/// one itself — by the time it opens, the "what are we making" question is
/// already answered and the only remaining inputs are the measured leading
/// quantity and the confirmed output.
Future<void> showRecordProductionDialog(
  BuildContext context,
  RecipeDto recipe,
) {
  return showResponsiveFormDialog<void>(
    context,
    builder: (_) => RecordProductionDialog(recipe: recipe),
  );
}

/// Widget keys for the dialog's controls. Same rationale as [StockDialogKeys]:
/// labels sit outside the inputs, so tests find fields by key, not copy.
abstract final class ProductionDialogKeys {
  static const leading = Key('productionDialog.leading');
  static const leadingQty = Key('productionDialog.leadingQty');
  static const actualQty = Key('productionDialog.actualQty');
  static const cancel = Key('productionDialog.cancel');
  static const submit = Key('productionDialog.submit');
}

class RecordProductionDialog extends ConsumerStatefulWidget {
  const RecordProductionDialog({super.key, required this.recipe});

  final RecipeDto recipe;

  @override
  ConsumerState<RecordProductionDialog> createState() =>
      _RecordProductionDialogState();
}

class _RecordProductionDialogState
    extends ConsumerState<RecordProductionDialog> {
  final _leadingQty = TextEditingController();
  final _actualQty = TextEditingController();

  late String _leadingItemId;
  bool _actualEdited = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // The first component is the usual thing weighed — rice before spices —
    // and the owner can switch to whatever they actually put on the scale.
    _leadingItemId = widget.recipe.components.first.rawMaterialItemId;
  }

  @override
  void dispose() {
    _leadingQty.dispose();
    _actualQty.dispose();
    super.dispose();
  }

  double? get _leadingAmount => parseQuantity(_leadingQty.text);

  double? get _actualAmount {
    final trimmed = _actualQty.text.trim();
    // Blank means "plan held" — the server commits the suggestion, so an
    // empty field is valid input, not a missing one.
    if (trimmed.isEmpty) return null;
    return parseQuantity(_actualQty.text);
  }

  ProductionPreview? get _preview => ProductionPreview.of(
        recipe: widget.recipe,
        leadingItemId: _leadingItemId,
        leadingQty: _leadingAmount ?? 0,
      );

  /// What the submit will actually send as the confirmed output: the typed
  /// value, or the suggestion when the field is blank.
  double? get _effectiveActual {
    final actual = _actualAmount ?? _preview?.suggestedOutput;
    if (actual == null || actual <= 0) return null;
    return actual;
  }

  String? get _error {
    if (_leadingAmount == null) return null;
    if (_leadingAmount! <= 0) return AppStrings.amountPositive;
    final actualText = _actualQty.text.trim();
    if (actualText.isNotEmpty &&
        (_actualAmount == null || _actualAmount! <= 0)) {
      return AppStrings.confirmedPositive;
    }
    return null;
  }

  bool get _canSubmit =>
      !_submitting &&
      _leadingAmount != null &&
      _leadingAmount! > 0 &&
      _error == null;

  double _stockOf(String catalogItemId) {
    for (final item in ref.read(inventoryItemsListProvider)) {
      if (item.catalogItemId == catalogItemId) return item.stock;
    }
    return 0;
  }

  void _onPreviewInputChanged() {
    // Keep the confirmed-output field tracking the suggestion until the
    // owner deliberately types their own number — afterwards their edit wins
    // over every recompute, so typing a leading quantity never clobbers it.
    final preview = _preview;
    if (!_actualEdited && preview != null) {
      _actualQty.text = _plain(preview.suggestedOutput);
    }
    setState(() {});
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final preview = _preview;
    final actual = _effectiveActual;
    if (preview == null || actual == null) return;

    setState(() => _submitting = true);
    try {
      final event =
          await ref.read(productionHistoryProvider.notifier).recordProduction(
                recipeId: widget.recipe.id,
                leadingItemId: _leadingItemId,
                leadingQuantity: _leadingAmount!,
                actualOutput: _actualQty.text.trim().isEmpty ? null : actual,
              );
      if (!mounted) return;
      Navigator.of(context).pop();
      final recorded = double.parse(event.actualOutputQuantity.toString());
      final suggested = double.parse(event.suggestedOutputQuantity.toString());
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            recorded == suggested
                ? AppStrings.productionRecorded(
                    Fmt.quantity(recorded),
                    event.sellableItemName,
                  )
                : AppStrings.productionRecordedAdjusted(
                    Fmt.quantity(recorded),
                    event.sellableItemName,
                    Fmt.quantity(suggested),
                  ),
          ),
        ),
      );
    } catch (e) {
      // Backend messages are written for owners ("Insufficient stock for
      // 'Meat'..."), so they go on the snackbar verbatim rather than behind
      // a generic "something went wrong".
      if (!mounted) return;
      setState(() => _submitting = false);
      final message = e is InventoryApiException ? e.message : e.toString();
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.recordFailed(message))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final preview = _preview;
    final leading = recipe.components.firstWhere(
      (c) => c.rawMaterialItemId == _leadingItemId,
      orElse: () => recipe.components.first,
    );

    return ResponsiveFormDialog(
      title: AppStrings.recordProductionTitle,
      width: kStockDialogWidth,
      actions: [
        OutlinedButton(
          key: ProductionDialogKeys.cancel,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.cancel),
        ),
        FilledButton(
          key: ProductionDialogKeys.submit,
          onPressed: _canSubmit ? _submit : null,
          child: Text(AppStrings.recordProductionTitle),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RecipeContext(recipe: recipe),
          const SizedBox(height: Insets.xl),
          LabeledFormField(
            label: AppStrings.measuredIngredient,
            helper: AppStrings.measuredHelper,
            isRequired: true,
            child: DropdownButtonFormField<String>(
              key: ProductionDialogKeys.leading,
              initialValue: _leadingItemId,
              isExpanded: true,
              items: [
                for (final component in recipe.components)
                  DropdownMenuItem(
                    value: component.rawMaterialItemId,
                    child: Text(
                      AppStrings.ingredientOption(
                        component.rawMaterialName,
                        component.rawMaterialUnit,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _leadingItemId = value);
                _onPreviewInputChanged();
              },
            ),
          ),
          const SizedBox(height: Insets.lg),
          LabeledFormField(
            label: AppStrings.quantityUsed,
            isRequired: true,
            child: TextFormField(
              key: ProductionDialogKeys.leadingQty,
              controller: _leadingQty,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
              ],
              decoration: InputDecoration(
                hintText: AppStrings.quantityHint,
                suffixText: leading.rawMaterialUnit,
                errorText: _error,
              ),
              onChanged: (_) => _onPreviewInputChanged(),
            ),
          ),
          if (preview != null) ...[
            const SizedBox(height: Insets.lg),
            _ConsumptionPreview(
              recipe: recipe,
              preview: preview,
              stockOf: _stockOf,
            ),
            const SizedBox(height: Insets.lg),
            StockPreviewLine(
              label: AppStrings.suggestedOutput,
              value: AppStrings.outputValue(
                Fmt.quantity(preview.suggestedOutput),
                recipe.sellableItemName,
              ),
              tone: context.semantic.success,
              icon: Icons.soup_kitchen_outlined,
            ),
            const SizedBox(height: Insets.lg),
            LabeledFormField(
              label: AppStrings.confirmedOutput,
              helper: AppStrings.acceptSuggestionHint,
              child: TextFormField(
                key: ProductionDialogKeys.actualQty,
                controller: _actualQty,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
                decoration:
                    InputDecoration(hintText: AppStrings.sameAsSuggested),
                onChanged: (value) {
                  _actualEdited = value.trim().isNotEmpty;
                  setState(() {});
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The recipe being produced: name, output, and per-unit ingredient list.
class _RecipeContext extends StatelessWidget {
  const _RecipeContext({required this.recipe});

  final RecipeDto recipe;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh.withValues(alpha: 0.55),
        borderRadius: Radii.card,
        border: Border.all(color: context.semantic.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.soup_kitchen_outlined,
                size: 20,
                color: colors.primary,
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: Text(
                  recipe.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.xs),
          Text(
            AppStrings.makesRecipe(
              recipe.sellableItemName,
              recipe.components
                  .map(
                    (c) =>
                        '${Fmt.quantity(_reqOf(c))} ${c.rawMaterialUnit} ${c.rawMaterialName}',
                  )
                  .join(' + '),
            ),
            style: context.text.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  static double _reqOf(RecipeIngredientDto component) =>
      double.parse(component.quantityRequired.toString());
}

/// Every ingredient this run will consume at the current ratio, with the
/// on-hand count beside each — the cook sees the shortfall before the
/// backend has to reject it.
class _ConsumptionPreview extends StatelessWidget {
  const _ConsumptionPreview({
    required this.recipe,
    required this.preview,
    required this.stockOf,
  });

  final RecipeDto recipe;
  final ProductionPreview preview;
  final double Function(String catalogItemId) stockOf;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: context.semantic.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.willConsume,
            style: context.text.labelLarge,
          ),
          const SizedBox(height: Insets.sm),
          for (final component in recipe.components)
            _ConsumptionLine(
              component: component,
              needed: preview.consumedByItemId[component.rawMaterialItemId] ?? 0,
              onHand: stockOf(component.rawMaterialItemId),
            ),
        ],
      ),
    );
  }
}

class _ConsumptionLine extends StatelessWidget {
  const _ConsumptionLine({
    required this.component,
    required this.needed,
    required this.onHand,
  });

  final RecipeIngredientDto component;
  final double needed;
  final double onHand;

  @override
  Widget build(BuildContext context) {
    final short = needed > onHand;
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.xs),
      child: Row(
        children: [
          Icon(
            short ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
            size: 16,
            color: short ? context.semantic.warning : context.semantic.success,
          ),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Text(
              component.rawMaterialName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodyMedium,
            ),
          ),
          Text(
            AppStrings.consumptionLine(
              Fmt.quantity(needed),
              component.rawMaterialUnit,
              Fmt.quantity(onHand),
            ),
            style: context.text.bodySmall?.copyWith(
              color: short ? context.semantic.warning : colors.onSurfaceVariant,
              fontWeight: short ? FontWeight.w700 : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// A display-plain number for prefilling an editable field: `10`, not
/// `10.0` and never grouped (`1,000` would not parse back).
String _plain(double value) =>
    value == value.roundToDouble() ? value.round().toString() : '$value';
