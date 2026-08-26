import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inventory_item.dart';
import 'inventory_provider.dart';

/// Everything the item form is holding, mid-edit.
///
/// Numbers stay as the strings the user typed. Parsing on every keystroke
/// would fight the person entering "1." on the way to "1.50", so the raw text
/// is the state and parsing happens at the validator and at save.
@immutable
class ItemFormState {
  const ItemFormState({
    required this.isEdit,
    required this.name,
    required this.categoryId,
    required this.sku,
    required this.unitCost,
    required this.lowStockAlert,
    required this.stock,
    required this.unit,
    required this.trackStock,
    required this.isArchived,
    this.description = '',
    this.image,
  });

  /// Blank form for a new item.
  ///
  /// Category starts unset on purpose: a defaulted dropdown gets accepted
  /// unread, and miscategorised stock is invisible in every filter afterwards.
  factory ItemFormState.blank() => const ItemFormState(
    isEdit: false,
    name: '',
    categoryId: '',
    sku: '',
    unitCost: '',
    lowStockAlert: '',
    stock: '0',
    unit: 'ea',
    trackStock: true,
    isArchived: false,
  );

  factory ItemFormState.from(InventoryItem item) => ItemFormState(
    isEdit: true,
    name: item.name,
    categoryId: item.categoryId,
    sku: item.sku,
    unitCost: item.unitCost.toStringAsFixed(2),
    lowStockAlert: item.reorderLevel.toString(),
    stock: item.stock.toString(),
    unit: item.unit,
    trackStock: item.trackStock,
    isArchived: item.isArchived,
    description: item.description,
    image: item.image,
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
  final bool trackStock;
  final bool isArchived;
  final ItemImage? image;

  Uint8List? get imageBytes => image?.bytes;

  // -------------------------------------------------------------------
  // Validation
  //
  // Static and pure so the field validators and the Save button's enabled
  // state are answering the same question — an inline error the user cannot
  // see the cause of, or a live button on an invalid form, both come from
  // having two copies of these rules.
  // -------------------------------------------------------------------

  static String? validateName(String? value) =>
      (value ?? '').trim().isEmpty ? 'Give the item a name' : null;

  static String? validateCategory(String? value) =>
      (value ?? '').isEmpty ? 'Pick a category' : null;

  static String? validateUnitCost(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Enter a unit cost';
    final parsed = double.tryParse(text);
    if (parsed == null) return 'Enter a number';
    if (parsed < 0) return 'Cost cannot be negative';
    return null;
  }

  /// Optional: an item with no threshold simply never reports as low.
  static String? validateLowStockAlert(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final parsed = int.tryParse(text);
    if (parsed == null) return 'Enter a whole number';
    if (parsed < 0) return 'Cannot be negative';
    return null;
  }

  static String? validateStock(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final parsed = int.tryParse(text);
    if (parsed == null) return 'Enter a whole number';
    if (parsed < 0) return 'Cannot be negative';
    return null;
  }

  /// Drives the primary button. Name, category and unit cost are the three the
  /// brief calls required; the optional numeric fields still have to parse if
  /// they were filled in at all.
  bool get canSave =>
      validateName(name) == null &&
      validateCategory(categoryId) == null &&
      validateUnitCost(unitCost) == null &&
      (!trackStock ||
          (validateLowStockAlert(lowStockAlert) == null &&
              validateStock(stock) == null));

  ItemFormState copyWith({
    String? name,
    String? categoryId,
    String? sku,
    String? unitCost,
    String? lowStockAlert,
    String? stock,
    String? unit,
    bool? trackStock,
    bool? isArchived,
    String? description,
    ItemImage? image,
    bool clearImage = false,
  }) {
    return ItemFormState(
      isEdit: isEdit,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      sku: sku ?? this.sku,
      unitCost: unitCost ?? this.unitCost,
      lowStockAlert: lowStockAlert ?? this.lowStockAlert,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      trackStock: trackStock ?? this.trackStock,
      isArchived: isArchived ?? this.isArchived,
      description: description ?? this.description,
      image: clearImage ? null : (image ?? this.image),
    );
  }
}

/// One form's worth of edit state, keyed by the id being edited — or null for
/// add mode.
///
/// A family rather than a single provider so an edit in one dialog cannot bleed
/// into another, and `autoDispose` so closing the dialog throws the draft away:
/// reopening the form has to start from the saved item, not from where the last
/// abandoned edit left off.
class ItemFormNotifier
    extends AutoDisposeFamilyNotifier<ItemFormState, String?> {
  @override
  ItemFormState build(String? itemId) {
    if (itemId == null) return ItemFormState.blank();

    // `read`, not `watch`: the form is a snapshot taken when it opened. Watching
    // would reset half-typed edits the moment anything else touched the list.
    for (final item in ref.read(inventoryItemsProvider)) {
      if (item.id == itemId) return ItemFormState.from(item);
    }
    // The row was deleted from under the dialog; fall back to add mode rather
    // than editing something that no longer exists.
    return ItemFormState.blank();
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

  void setTrackStock(bool value) => state = state.copyWith(trackStock: value);

  void setImage(String name, Uint8List bytes) => state = state.copyWith(
    image: ItemImage(name: name, bytes: bytes),
  );

  void clearImage() => state = state.copyWith(clearImage: true);

  /// Writes the form back to the inventory list and returns what was saved.
  ///
  /// Fields the form does not expose — the emoji fallback, the supplier, the
  /// last count timestamp — are carried across from the stored item rather than
  /// reset, so editing a name cannot quietly wipe them.
  InventoryItem save() {
    final inventory = ref.read(inventoryItemsProvider.notifier);

    InventoryItem? existing;
    if (arg != null) {
      for (final item in ref.read(inventoryItemsProvider)) {
        if (item.id == arg) existing = item;
      }
    }

    final name = state.name.trim();
    final unitCost = double.tryParse(state.unitCost.trim()) ?? 0;
    final reorderLevel = int.tryParse(state.lowStockAlert.trim()) ?? 0;
    final sku = state.sku.trim();

    final item = existing != null
        ? existing.copyWith(
            name: name,
            categoryId: state.categoryId,
            sku: sku.isEmpty ? existing.sku : sku,
            unitCost: unitCost,
            reorderLevel: reorderLevel,
            unit: state.unit,
            trackStock: state.trackStock,
            isArchived: state.isArchived,
            description: state.description.trim(),
            image: state.image,
            clearImage: state.image == null,
            // Stock is deliberately not written here — the count moves through
            // the Stock Adjust flow, which records why it changed.
          )
        : InventoryItem(
            id: inventory.nextId(),
            sku: sku.isEmpty ? _generatedSku(name) : sku,
            name: name,
            categoryId: state.categoryId,
            emoji: '📦',
            stock: int.tryParse(state.stock.trim()) ?? 0,
            reorderLevel: reorderLevel,
            unitCost: unitCost,
            unit: state.unit,
            trackStock: state.trackStock,
            isArchived: state.isArchived,
            description: state.description.trim(),
            image: state.image,
          );

    inventory.upsert(item);
    return item;
  }

  /// A placeholder code so the SKU column and its sort stay populated. A real
  /// system would take this from the supplier catalogue.
  static String _generatedSku(String name) {
    final letters = name.toUpperCase().replaceAll(RegExp('[^A-Z]'), '');
    final prefix = letters.isEmpty
        ? 'NEW'
        : letters.substring(0, letters.length < 3 ? letters.length : 3);
    return '$prefix-${DateTime.now().millisecondsSinceEpoch % 10000}';
  }
}

/// Keyed by the item id under edit, or null when adding.
final itemFormProvider = NotifierProvider.autoDispose
    .family<ItemFormNotifier, ItemFormState, String?>(ItemFormNotifier.new);
