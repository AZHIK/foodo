import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inventory_item.dart';
import '../constants/app_limits.dart';
import '../constants/app_strings.dart';
import 'inventory_provider.dart';

/// Everything the grocery form is holding, mid-edit.
///
/// Groceries are `raw_material` lines and always stock-tracked: there is no
/// type choice and no tracking toggle on this form. Numbers stay as the
/// strings the user typed — parsing happens at the validator and at save,
/// so typing "1." on the way to "1.50" is never fought.
@immutable
class GroceryFormState {
  const GroceryFormState({
    required this.isEdit,
    required this.name,
    required this.categoryId,
    required this.sku,
    required this.unitCost,
    required this.lowStockAlert,
    required this.stock,
    required this.unit,
    required this.isArchived,
    this.description = '',
    this.image,
    this.imageCleared = false,
    this.reorderQuantity = '',
    this.allowNegativeStock = false,
  });

  /// Blank form for a new grocery line. Category starts unset on purpose: a
  /// defaulted dropdown gets accepted unread, and miscategorised stock is
  /// invisible in every filter afterwards.
  factory GroceryFormState.blank() => const GroceryFormState(
    isEdit: false,
    name: '',
    categoryId: '',
    sku: '',
    unitCost: '',
    lowStockAlert: '',
    stock: '0',
    unit: 'ea',
    isArchived: false,
  );

  factory GroceryFormState.from(InventoryItem item) => GroceryFormState(
    isEdit: true,
    name: item.name,
    categoryId: item.categoryId,
    sku: item.sku,
    unitCost: item.unitCost.toStringAsFixed(2),
    lowStockAlert: item.reorderLevel.toString(),
    stock: item.stock.toString(),
    unit: item.unit,
    isArchived: item.isArchived,
    description: item.description,
    image: item.image,
    reorderQuantity: item.reorderQuantity.toString(),
    allowNegativeStock: item.allowNegativeStock,
  );

  final bool isEdit;
  final String name;
  final String categoryId;
  final String sku;
  final String description;
  final String unitCost;
  final String lowStockAlert;
  final String stock;
  final String unit;
  final bool isArchived;
  final ItemImage? image;

  /// True once the user explicitly removes the photo in this editing
  /// session. Distinct from `image == null` (also true when the item simply
  /// has no photo): only an explicit removal deletes the server-side photo
  /// on save.
  final bool imageCleared;

  final String reorderQuantity;
  final bool allowNegativeStock;

  Uint8List? get imageBytes => image?.bytes;

  // -------------------------------------------------------------------
  // Validation — static and pure so the field validators and the Save
  // button's enabled state answer the same question.
  // -------------------------------------------------------------------

  static String? validateName(String? value) =>
      (value ?? '').trim().isEmpty ? AppStrings.giveItemName : null;

  static String? validateCategory(String? value) =>
      (value ?? '').isEmpty ? AppStrings.pickCategory : null;

  static String? validateUnitCost(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return AppStrings.enterUnitCost;
    final parsed = double.tryParse(text);
    if (parsed == null) return AppStrings.enterNumberError;
    if (parsed < 0) return AppStrings.negativeCost;
    return null;
  }

  /// Optional: a line with no threshold simply never reports as low.
  static String? validateLowStockAlert(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null) return AppStrings.enterNumberError;
    if (parsed < 0) return AppStrings.negativeNumber;
    return null;
  }

  static String? validateStock(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null) return AppStrings.enterNumberError;
    if (parsed < 0) return AppStrings.negativeNumber;
    return null;
  }

  static String? validateReorderQuantity(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null) return AppStrings.enterNumberError;
    if (parsed < 0) return AppStrings.negativeNumber;
    return null;
  }

  /// Name, category and unit cost are required; the optional numeric fields
  /// still have to parse when filled in.
  bool get canSave =>
      validateName(name) == null &&
      validateCategory(categoryId) == null &&
      validateUnitCost(unitCost) == null &&
      validateLowStockAlert(lowStockAlert) == null &&
      validateStock(stock) == null &&
      validateReorderQuantity(reorderQuantity) == null;

  GroceryFormState copyWith({
    String? name,
    String? categoryId,
    String? sku,
    String? unitCost,
    String? lowStockAlert,
    String? stock,
    String? unit,
    bool? isArchived,
    String? description,
    ItemImage? image,
    String? reorderQuantity,
    bool? allowNegativeStock,
    bool clearImage = false,
  }) {
    return GroceryFormState(
      isEdit: isEdit,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      sku: sku ?? this.sku,
      unitCost: unitCost ?? this.unitCost,
      lowStockAlert: lowStockAlert ?? this.lowStockAlert,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      isArchived: isArchived ?? this.isArchived,
      description: description ?? this.description,
      image: clearImage ? null : (image ?? this.image),
      // Picking a new photo un-removes a removal.
      imageCleared: clearImage ? true : (image != null ? false : imageCleared),
      reorderQuantity: reorderQuantity ?? this.reorderQuantity,
      allowNegativeStock: allowNegativeStock ?? this.allowNegativeStock,
    );
  }
}

/// One form's worth of edit state, keyed by the id being edited — or null
/// for add mode. A family so an edit in one dialog cannot bleed into
/// another, and `autoDispose` so closing the dialog throws the draft away.
class GroceryFormNotifier
    extends AutoDisposeFamilyNotifier<GroceryFormState, String?> {
  @override
  GroceryFormState build(String? itemId) {
    if (itemId == null) return GroceryFormState.blank();

    // `read`, not `watch`: the form is a snapshot taken when it opened.
    for (final item in ref.read(inventoryItemsListProvider)) {
      if (item.id == itemId) return GroceryFormState.from(item);
    }
    return GroceryFormState.blank();
  }

  void setName(String value) => state = state.copyWith(name: value);
  void setCategory(String value) => state = state.copyWith(categoryId: value);
  void setSku(String value) => state = state.copyWith(sku: value);
  void setDescription(String value) =>
      state = state.copyWith(description: value);
  void setUnitCost(String value) => state = state.copyWith(unitCost: value);
  void setUnit(String value) => state = state.copyWith(unit: value);
  void setStock(String value) => state = state.copyWith(stock: value);
  void setArchived(bool value) => state = state.copyWith(isArchived: value);

  void setLowStockAlert(String value) =>
      state = state.copyWith(lowStockAlert: value);

  void setReorderQuantity(String value) =>
      state = state.copyWith(reorderQuantity: value);

  void setAllowNegativeStock(bool value) =>
      state = state.copyWith(allowNegativeStock: value);

  void setImage(String name, Uint8List bytes) => state = state.copyWith(
    image: ItemImage(name: name, bytes: bytes),
  );

  void clearImage() => state = state.copyWith(clearImage: true);

  /// Writes the form back to the inventory list and returns what was saved.
  /// Always a tracked `raw_material` line — groceries have no type choice.
  Future<InventoryItem> save() async {
    final inventory = ref.read(inventoryItemsProvider.notifier);

    InventoryItem? existing;
    if (arg != null) {
      for (final item in ref.read(inventoryItemsListProvider)) {
        if (item.id == arg) existing = item;
      }
    }

    final name = state.name.trim();
    final unitCost = double.tryParse(state.unitCost.trim()) ?? 0;
    final reorderLevel = double.tryParse(state.lowStockAlert.trim()) ?? 0;
    final reorderQuantity = double.tryParse(state.reorderQuantity.trim()) ?? 0;
    final sku = state.sku.trim();

    final item = existing != null
        ? existing.copyWith(
            name: name,
            categoryId: state.categoryId,
            sku: sku.isEmpty ? existing.sku : sku,
            unitCost: unitCost,
            reorderLevel: reorderLevel,
            reorderQuantity: reorderQuantity,
            allowNegativeStock: state.allowNegativeStock,
            unit: state.unit,
            trackStock: true,
            isArchived: state.isArchived,
            description: state.description.trim(),
            image: state.image,
            clearImage: state.image == null,
            itemType: 'raw_material',
            // Stock moves through the Stock Adjust flow, which records why.
            // A price set on a grocery stays off the till: groceries are
            // never sellable.
            clearSellingPrice: true,
            isSellable: false,
          )
        : InventoryItem(
            id: inventory.nextId(),
            sku: sku.isEmpty ? _generatedSku(name) : sku,
            name: name,
            categoryId: state.categoryId,
            emoji: '📦',
            stock: double.tryParse(state.stock.trim()) ?? 0,
            reorderLevel: reorderLevel,
            reorderQuantity: reorderQuantity,
            allowNegativeStock: state.allowNegativeStock,
            unitCost: unitCost,
            unit: state.unit,
            trackStock: true,
            isArchived: state.isArchived,
            description: state.description.trim(),
            image: state.image,
            itemType: 'raw_material',
          );

    await inventory.upsert(
      item,
      deleteRemoteImage: state.imageCleared && (existing?.imageUrl != null),
    );
    return item;
  }

  static String _generatedSku(String name) {
    final letters = name.toUpperCase().replaceAll(RegExp('[^A-Z]'), '');
    final prefix = letters.isEmpty
        ? 'NEW'
        : letters.substring(0, letters.length < 3 ? letters.length : 3);
    return '$prefix-${DateTime.now().millisecondsSinceEpoch % AppLimits.skuSuffixMod}';
  }
}

/// Keyed by the item id under edit, or null when adding.
final groceryFormProvider = NotifierProvider.autoDispose
    .family<GroceryFormNotifier, GroceryFormState, String?>(
      GroceryFormNotifier.new,
    );
