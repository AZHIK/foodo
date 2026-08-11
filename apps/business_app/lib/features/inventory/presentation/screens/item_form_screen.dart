import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/fakes/fake_data_service.dart';
import '../../../../shared/widgets/widgets.dart';

/// Which mode the shared item form is running in.
enum ItemFormMode { add, edit }

/// Shared form screen for creating or editing an inventory item.
///
/// A single screen driven by [ItemFormMode] (add vs edit); in edit mode an
/// [itemId] loads the existing item from [fakeInventoryProvider] into the
/// field state.
///
/// Field set (all built from the shared form kit):
/// - [AppTextField] — name, category
/// - [AppDropdownField] — unit of measure, item type
/// - [MoneyField] — selling price (senti int, TZS formatting)
/// - [AppNumberField] — reorder threshold, reorder quantity, initial stock
/// - toggles — allow negative stock, active status
///
/// Validation mirrors the backend schema constraints exactly: required
/// strings must be non-empty, prices and reorder quantity must be positive,
/// and the reorder threshold must be non-negative. No new rules are invented
/// here.
///
/// Multi-field rows stack vertically on phone widths and sit side-by-side on
/// tablet/desktop widths.
///
/// Submitting mutates [fakeInventoryProvider] (add via [FakeInventoryNotifier
/// .addItem], edit via [FakeInventoryNotifier.updateItem]) — the real API
/// integration will swap the provider underneath without touching this screen.
class ItemFormScreen extends ConsumerStatefulWidget {
  const ItemFormScreen({
    required this.mode,
    this.itemId,
    super.key,
  });

  final ItemFormMode mode;
  final String? itemId;

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  static const List<String> _unitOptions = ['pcs', 'kg', 'g', 'l', 'ml', 'box'];
  static const List<String> _itemTypeOptions = [
    'prepared_item',
    'raw_ingredient',
    'resellable',
    'variant_parent',
  ];

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _skuController;
  late final TextEditingController _barcodeController;

  late String _unit;
  late String _itemType;
  late int _priceSenti;
  late int _costPriceSenti;
  late int _stockLevel;
  late int _reorderThreshold;
  late int _reorderQuantity;
  late bool _allowNegativeStock;
  late bool _isActive;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _categoryController = TextEditingController();
    _skuController = TextEditingController();
    _barcodeController = TextEditingController();
    _unit = 'pcs';
    _itemType = 'prepared_item';
    _priceSenti = 0;
    _costPriceSenti = 0;
    _stockLevel = 10;
    _reorderThreshold = 5;
    _reorderQuantity = 20;
    _allowNegativeStock = false;
    _isActive = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      if (widget.mode == ItemFormMode.edit && widget.itemId != null) {
        final items = ref.read(fakeInventoryProvider);
        final existing = items.where((i) => i.id == widget.itemId).firstOrNull;
        if (existing != null) {
          _nameController.text = existing.name;
          _categoryController.text = existing.category;
          _skuController.text = existing.sku;
          _barcodeController.text = existing.barcode;
          _unit = existing.unit;
          _itemType = existing.itemType;
          _priceSenti = existing.priceSenti;
          _costPriceSenti = existing.costPriceSenti;
          _stockLevel = existing.stockLevel;
          _reorderThreshold = existing.reorderThreshold;
          _reorderQuantity = existing.reorderQuantity;
          _allowNegativeStock = existing.allowNegativeStock;
          _isActive = existing.isActive;
        }
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final notifier = ref.read(fakeInventoryProvider.notifier);
    final now = DateTime.now();

    if (widget.mode == ItemFormMode.add) {
      final newItem = FakeInventoryItem(
        id: 'inv_fake_${now.millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        sku: _skuController.text.trim().isNotEmpty
            ? _skuController.text.trim()
            : 'SKU-${now.millisecondsSinceEpoch.toString().substring(7)}',
        priceSenti: _priceSenti,
        costPriceSenti: _costPriceSenti,
        stockLevel: _stockLevel,
        reorderThreshold: _reorderThreshold,
        reorderQuantity: _reorderQuantity,
        unit: _unit,
        itemType: _itemType,
        barcode: _barcodeController.text.trim(),
        allowNegativeStock: _allowNegativeStock,
        isActive: _isActive,
        createdAt: now,
        updatedAt: now,
      );
      notifier.addItem(newItem);
    } else {
      final items = ref.read(fakeInventoryProvider);
      final existing = items.where((i) => i.id == widget.itemId).firstOrNull;
      if (existing != null) {
        notifier.updateItem(
          existing.copyWith(
            name: _nameController.text.trim(),
            category: _categoryController.text.trim(),
            sku: _skuController.text.trim(),
            barcode: _barcodeController.text.trim(),
            unit: _unit,
            itemType: _itemType,
            priceSenti: _priceSenti,
            costPriceSenti: _costPriceSenti,
            stockLevel: _stockLevel,
            reorderThreshold: _reorderThreshold,
            reorderQuantity: _reorderQuantity,
            allowNegativeStock: _allowNegativeStock,
            isActive: _isActive,
            updatedAt: now,
          ),
        );
      }
    }

    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.inventory);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointTablet;
    final title = widget.mode == ItemFormMode.add
        ? 'Add Inventory Item'
        : 'Edit Inventory Item';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spaceMD),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CardSection(
                title: 'Basic Information',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _nameController,
                      label: 'Item Name',
                      hint: 'e.g. Beef Stew',
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Item name is required'
                          : null,
                    ),
                    const SizedBox(height: AppDimensions.spaceMD),
                    AppTextField(
                      controller: _categoryController,
                      label: 'Category',
                      hint: 'e.g. Mains, Drinks, Pastries',
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Category is required'
                          : null,
                    ),
                    const SizedBox(height: AppDimensions.spaceMD),
                    _fieldGroup(
                      isWide: isWide,
                      fields: [
                        AppDropdownField<String>(
                          label: 'Unit of Measure',
                          value: _unit,
                          options: _unitOptions,
                          labelBuilder: (u) => _unitLabel(u),
                          onChanged: (v) {
                            if (v != null) setState(() => _unit = v);
                          },
                        ),
                        AppDropdownField<String>(
                          label: 'Item Type',
                          value: _itemType,
                          options: _itemTypeOptions,
                          labelBuilder: (t) => _itemTypeLabel(t),
                          onChanged: (v) {
                            if (v != null) setState(() => _itemType = v);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              _CardSection(
                title: 'Pricing & Stock',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _fieldGroup(
                      isWide: isWide,
                      fields: [
                        MoneyField(
                          label: 'Selling Price (TZS)',
                          initialSenti: _priceSenti,
                          allowZero: true,
                          onChanged: (senti) => _priceSenti = senti,
                          validator: (senti) =>
                              (senti == null || senti <= 0)
                              ? 'Selling price must be greater than zero'
                              : null,
                        ),
                        MoneyField(
                          label: 'Cost Price (TZS)',
                          initialSenti: _costPriceSenti,
                          allowZero: true,
                          onChanged: (senti) => _costPriceSenti = senti,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceMD),
                    _fieldGroup(
                      isWide: isWide,
                      fields: [
                        AppNumberField(
                          label: 'Initial Stock Level',
                          initialValue: _stockLevel,
                          min: 0,
                          allowNegative: false,
                          allowZero: true,
                          onChanged: (val) => _stockLevel = val,
                        ),
                        AppNumberField(
                          label: 'Reorder Threshold',
                          initialValue: _reorderThreshold,
                          min: 0,
                          allowNegative: false,
                          allowZero: true,
                          onChanged: (val) => _reorderThreshold = val,
                        ),
                        AppNumberField(
                          label: 'Reorder Quantity',
                          initialValue: _reorderQuantity,
                          min: 1,
                          allowNegative: false,
                          allowZero: false,
                          onChanged: (val) => _reorderQuantity = val,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              AppCard.outlined(
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      title: const Text('Allow Negative Stock'),
                      subtitle: const Text(
                        'Permit stock to go below zero after sales',
                      ),
                      value: _allowNegativeStock,
                      onChanged: (val) =>
                          setState(() => _allowNegativeStock = val),
                    ),
                    const Divider(),
                    SwitchListTile.adaptive(
                      title: const Text('Active Status'),
                      subtitle: const Text(
                        'Item is available for sales and POS selection',
                      ),
                      value: _isActive,
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLG),
              AppPrimaryButton(
                label: widget.mode == ItemFormMode.add ? 'Save Item' : 'Update Item',
                icon: Icons.check,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Lays out [fields] side-by-side on wide screens and stacked on narrow
  /// screens so the form never overflows at phone width.
  Widget _fieldGroup({required bool isWide, required List<Widget> fields}) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            if (i > 0) const SizedBox(width: AppDimensions.spaceMD),
            Expanded(child: fields[i]),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(height: AppDimensions.spaceMD),
          fields[i],
        ],
      ],
    );
  }

  static String _unitLabel(String unit) => switch (unit) {
        'pcs' => 'Pieces (pcs)',
        'kg' => 'Kilograms (kg)',
        'g' => 'Grams (g)',
        'l' => 'Liters (l)',
        'ml' => 'Milliliters (ml)',
        'box' => 'Box (box)',
        _ => unit,
      };

  static String _itemTypeLabel(String type) => switch (type) {
        'prepared_item' => 'Prepared Item',
        'raw_ingredient' => 'Raw Ingredient',
        'resellable' => 'Resellable Item',
        'variant_parent' => 'Variant Parent',
        _ => type,
      };
}

/// Outlined card wrapper with a section heading, used to group form fields.
class _CardSection extends StatelessWidget {
  const _CardSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard.outlined(
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          child,
        ],
      ),
    );
  }
}
