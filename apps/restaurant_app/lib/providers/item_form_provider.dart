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
    this.sellingPrice = '',
    this.itemType = '',
    this.reorderQuantity = '',
    this.allowNegativeStock = false,
  });

  /// Blank form for a new item.
  ///
  /// Category starts unset on purpose: a defaulted dropdown gets accepted
  /// unread, and miscategorised stock is invisible in every filter afterwards.
  /// [itemType] starts empty too — that is what tells the dialog to show the
  /// Grocery/Menu item/Both entry choice before any other field.
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
    sellingPrice: item.sellingPrice?.toStringAsFixed(2) ?? '',
    itemType: item.itemType,
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
  final bool trackStock;
  final bool isArchived;
  final ItemImage? image;

  /// Blank means "not for sale" — the item stays off the POS menu until a
  /// price is set. Kept as text like the other numeric fields so a half-typed
  /// "4." isn't fought by eager parsing.
  final String sellingPrice;

  /// `sellable` | `raw_material` | `both`, or empty while adding a new item
  /// that has not been through the entry-choice step yet. Never empty once
  /// [isEdit] is true — an existing item always has a real type.
  final String itemType;

  /// How much to reorder when this line falls below [lowStockAlert]. Text
  /// like the other numeric fields; optional the same way the threshold is.
  final String reorderQuantity;

  final bool allowNegativeStock;

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
  /// A number, not necessarily a whole one — kg/L-tracked items reorder at
  /// fractional thresholds too.
  static String? validateLowStockAlert(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null) return 'Enter a number';
    if (parsed < 0) return 'Cannot be negative';
    return null;
  }

  static String? validateStock(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null) return 'Enter a number';
    if (parsed < 0) return 'Cannot be negative';
    return null;
  }

  /// Blank only passes for a grocery ([isRequired] false) — a stockroom-only
  /// line genuinely has no till price. A `sellable` or `both` item must carry
  /// one: an item that can be rung up with no price would silently vanish
  /// from the POS menu (`isSellable` requires a non-null price), which is a
  /// confusing way to fail rather than a real "not for sale yet" state.
  static String? validateSellingPrice(String? value, {required bool isRequired}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return isRequired ? 'Enter a selling price to sell this at the till' : null;
    }
    final parsed = double.tryParse(text);
    if (parsed == null) return 'Enter a number';
    if (parsed < 0) return 'Cannot be negative';
    return null;
  }

  /// Optional, same shape as [validateLowStockAlert] — a blank reorder
  /// quantity is fine, a malformed one is not.
  static String? validateReorderQuantity(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null) return 'Enter a number';
    if (parsed < 0) return 'Cannot be negative';
    return null;
  }

  /// Drives the primary button. Name, category and unit cost are the three the
  /// brief calls required; the optional numeric fields still have to parse if
  /// they were filled in at all. A new item also needs [itemType] set — the
  /// entry-choice step is what sets it, so this is what keeps the form
  /// unsavable until that choice has been made. A selling price is required
  /// too, unless the item is a pure grocery — see [validateSellingPrice].
  bool get canSave =>
      itemType.isNotEmpty &&
      validateName(name) == null &&
      validateCategory(categoryId) == null &&
      validateUnitCost(unitCost) == null &&
      validateSellingPrice(sellingPrice, isRequired: itemType != 'raw_material') ==
          null &&
      (!trackStock ||
          (validateLowStockAlert(lowStockAlert) == null &&
              validateStock(stock) == null &&
              validateReorderQuantity(reorderQuantity) == null));

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
    String? sellingPrice,
    String? itemType,
    String? reorderQuantity,
    bool? allowNegativeStock,
    bool clearImage = false,
    // itemType has no natural "unset" value to fall back to via `??`, since
    // '' is itself meaningful (the entry choice has not been made) — going
    // back to the chooser has to say so explicitly.
    bool clearItemType = false,
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
      sellingPrice: sellingPrice ?? this.sellingPrice,
      itemType: clearItemType ? '' : (itemType ?? this.itemType),
      reorderQuantity: reorderQuantity ?? this.reorderQuantity,
      allowNegativeStock: allowNegativeStock ?? this.allowNegativeStock,
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
    for (final item in ref.read(inventoryItemsListProvider)) {
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
  void setSellingPrice(String value) =>
      state = state.copyWith(sellingPrice: value);
  void setUnit(String value) => state = state.copyWith(unit: value);
  void setStock(String value) => state = state.copyWith(stock: value);
  void setArchived(bool value) => state = state.copyWith(isArchived: value);

  void setLowStockAlert(String value) =>
      state = state.copyWith(lowStockAlert: value);

  void setReorderQuantity(String value) =>
      state = state.copyWith(reorderQuantity: value);

  void setAllowNegativeStock(bool value) =>
      state = state.copyWith(allowNegativeStock: value);

  void setTrackStock(bool value) => state = state.copyWith(trackStock: value);

  /// Answers the entry-choice step. Groceries and "both" default to tracked
  /// stock; a pure menu item defaults to untracked — prepared-to-order dishes
  /// are the common case, and the toggle is still there for the exception.
  void chooseType(String type) {
    state = state.copyWith(itemType: type, trackStock: type != 'sellable');
  }

  /// Sends the form back to the entry-choice step. Everything else already
  /// typed is kept — changing your mind about the item's type should not
  /// throw away the name and cost you already entered.
  void resetType() => state = state.copyWith(clearItemType: true);

  void setImage(String name, Uint8List bytes) => state = state.copyWith(
    image: ItemImage(name: name, bytes: bytes),
  );

  void clearImage() => state = state.copyWith(clearImage: true);

  /// Writes the form back to the inventory list and returns what was saved.
  ///
  /// Fields the form does not expose — the emoji fallback, the supplier, the
  /// last count timestamp — are carried across from the stored item rather than
  /// reset, so editing a name cannot quietly wipe them.
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
    final sellingPrice = double.tryParse(state.sellingPrice.trim());
    // Defensive fallback only — the entry-choice step blocks `canSave` (and
    // therefore this call) until a type is picked, so this never actually
    // runs empty in practice.
    final itemType = state.itemType.isEmpty ? 'both' : state.itemType;

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
            trackStock: state.trackStock,
            isArchived: state.isArchived,
            description: state.description.trim(),
            image: state.image,
            clearImage: state.image == null,
            sellingPrice: sellingPrice,
            clearSellingPrice: sellingPrice == null,
            isSellable: itemType != 'raw_material' && sellingPrice != null,
            itemType: itemType,
            // Stock is deliberately not written here — the count moves through
            // the Stock Adjust flow, which records why it changed.
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
            trackStock: state.trackStock,
            isArchived: state.isArchived,
            description: state.description.trim(),
            image: state.image,
            sellingPrice: sellingPrice,
            isSellable: itemType != 'raw_material' && sellingPrice != null,
            itemType: itemType,
          );

    await inventory.upsert(item);
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
