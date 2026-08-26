import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/menu_item.dart';
import 'menu_providers.dart';

/// Everything the menu item form is holding, mid-edit.
///
/// Numbers stay as the strings the user typed. Parsing on every keystroke
/// would fight the person entering "1." on the way to "1.50", so the raw text
/// is the state and parsing happens at the validator and at save.
@immutable
class MenuItemFormState {
  const MenuItemFormState({
    required this.isEdit,
    required this.name,
    required this.categoryId,
    required this.description,
    required this.price,
    required this.isAvailable,
    required this.isPopular,
    required this.prepMinutes,
    required this.isArchived,
    this.linkedInventoryItemId,
  });

  /// Blank form for a new item.
  factory MenuItemFormState.blank() => const MenuItemFormState(
    isEdit: false,
    name: '',
    categoryId: '',
    description: '',
    price: '',
    isAvailable: true,
    isPopular: false,
    prepMinutes: '10',
    isArchived: false,
  );

  factory MenuItemFormState.from(MenuItem item) => MenuItemFormState(
    isEdit: true,
    name: item.name,
    categoryId: item.categoryId,
    description: item.description,
    price: item.price.toStringAsFixed(2),
    isAvailable: item.isAvailable,
    isPopular: item.isPopular,
    prepMinutes: item.prepMinutes.toString(),
    isArchived: item.isArchived,
    linkedInventoryItemId: item.linkedInventoryItemId,
  );

  final bool isEdit;
  final String name;
  final String categoryId;
  final String description;
  final String price;
  final bool isAvailable;
  final bool isPopular;
  final String prepMinutes;
  final bool isArchived;
  final String? linkedInventoryItemId;

  static String? validateName(String? value) =>
      (value ?? '').trim().isEmpty ? 'Give the item a name' : null;

  static String? validateCategory(String? value) =>
      (value ?? '').isEmpty ? 'Pick a category' : null;

  static String? validatePrice(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Enter a price';
    final parsed = double.tryParse(text);
    if (parsed == null) return 'Enter a number';
    if (parsed < 0) return 'Price cannot be negative';
    return null;
  }

  static String? validatePrepMinutes(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Enter prep time';
    final parsed = int.tryParse(text);
    if (parsed == null) return 'Enter a whole number';
    if (parsed < 0) return 'Cannot be negative';
    return null;
  }

  bool get canSave =>
      validateName(name) == null &&
      validateCategory(categoryId) == null &&
      validatePrice(price) == null &&
      validatePrepMinutes(prepMinutes) == null;

  MenuItemFormState copyWith({
    String? name,
    String? categoryId,
    String? description,
    String? price,
    bool? isAvailable,
    bool? isPopular,
    String? prepMinutes,
    bool? isArchived,
    String? linkedInventoryItemId,
    bool clearLinkedInventoryItemId = false,
  }) {
    return MenuItemFormState(
      isEdit: isEdit,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
      isPopular: isPopular ?? this.isPopular,
      prepMinutes: prepMinutes ?? this.prepMinutes,
      isArchived: isArchived ?? this.isArchived,
      linkedInventoryItemId: clearLinkedInventoryItemId
          ? null
          : (linkedInventoryItemId ?? this.linkedInventoryItemId),
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
class MenuItemFormNotifier
    extends AutoDisposeFamilyNotifier<MenuItemFormState, String?> {
  @override
  MenuItemFormState build(String? itemId) {
    if (itemId == null) return MenuItemFormState.blank();

    // `read`, not `watch`: the form is a snapshot taken when it opened. Watching
    // would reset half-typed edits the moment anything else touched the list.
    for (final item in ref.read(menuItemsProvider)) {
      if (item.id == itemId) return MenuItemFormState.from(item);
    }
    // The row was deleted from under the dialog; fall back to add mode rather
    // than editing something that no longer exists.
    return MenuItemFormState.blank();
  }

  void setName(String value) => state = state.copyWith(name: value);
  void setCategory(String value) => state = state.copyWith(categoryId: value);
  void setDescription(String value) =>
      state = state.copyWith(description: value);
  void setPrice(String value) => state = state.copyWith(price: value);
  void setIsAvailable(bool value) =>
      state = state.copyWith(isAvailable: value);
  void setIsPopular(bool value) => state = state.copyWith(isPopular: value);
  void setPrepMinutes(String value) =>
      state = state.copyWith(prepMinutes: value);
  void setArchived(bool value) => state = state.copyWith(isArchived: value);
  void setLinkedInventoryItem(String? value) =>
      state = state.copyWith(linkedInventoryItemId: value);

  /// Writes the form back to the menu items list and returns what was saved.
  MenuItem save() {
    final menu = ref.read(menuItemsProvider.notifier);

    MenuItem? existing;
    if (arg != null) {
      for (final item in ref.read(menuItemsProvider)) {
        if (item.id == arg) existing = item;
      }
    }

    final name = state.name.trim();
    final price = double.tryParse(state.price.trim()) ?? 0;
    final prepMinutes = int.tryParse(state.prepMinutes.trim()) ?? 10;

    final item = existing != null
        ? existing.copyWith(
            name: name,
            description: state.description.trim(),
            price: price,
            categoryId: state.categoryId,
            isAvailable: state.isAvailable,
            isPopular: state.isPopular,
            prepMinutes: prepMinutes,
            linkedInventoryItemId: state.linkedInventoryItemId,
            isArchived: state.isArchived,
          )
        : MenuItem(
            id: menu.nextId(),
            name: name,
            description: state.description.trim(),
            price: price,
            categoryId: state.categoryId,
            emoji: '🍽️',
            isAvailable: state.isAvailable,
            isPopular: state.isPopular,
            prepMinutes: prepMinutes,
            linkedInventoryItemId: state.linkedInventoryItemId,
            isArchived: state.isArchived,
          );

    menu.upsert(item);
    return item;
  }
}

/// Keyed by the item id under edit, or null when adding.
final menuItemFormProvider = NotifierProvider.autoDispose
    .family<MenuItemFormNotifier, MenuItemFormState, String?>(
        MenuItemFormNotifier.new);
