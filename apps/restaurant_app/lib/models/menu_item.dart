import 'package:flutter/material.dart';

/// A menu category, e.g. "Starters" or "Drinks".
///
/// [id] is the stable key used for filtering; a backend would supply the same
/// value so nothing downstream has to change.
@immutable
class MenuCategory {
  const MenuCategory({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;

  /// Sentinel category used by the "All" tab. Never comes from a backend.
  static const all = MenuCategory(
    id: '_all',
    label: 'All',
    icon: Icons.grid_view_rounded,
  );
}

/// A single sellable item on the menu.
@immutable
class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.emoji,
    this.imageUrl,
    this.isAvailable = true,
    this.isPopular = false,
    this.prepMinutes = 10,
    this.linkedInventoryItemId,
    this.isArchived = false,
  });

  final String id;
  final String name;
  final String description;

  /// Unit price in the store's currency.
  final double price;
  final String categoryId;

  /// Rendered as artwork when [imageUrl] is null, which keeps the UI fully
  /// offline while still giving each card a distinct look.
  final String emoji;

  /// Populated once a backend serves real photography.
  final String? imageUrl;

  final bool isAvailable;
  final bool isPopular;
  final int prepMinutes;

  /// ID of the linked inventory item for stock tracking (nullable).
  /// Multiple menu items can theoretically link to the same inventory item,
  /// but typically a menu item links to one inventory item.
  /// TODO: single item only — revisit if menu items need multi-ingredient recipes.
  final String? linkedInventoryItemId;

  /// Soft-delete flag: archived items don't appear in the POS grid.
  final bool isArchived;

  MenuItem copyWith({
    String? name,
    String? description,
    double? price,
    String? categoryId,
    String? emoji,
    String? imageUrl,
    bool? isAvailable,
    bool? isPopular,
    int? prepMinutes,
    String? linkedInventoryItemId,
    bool? isArchived,
    bool clearLinkedInventoryItemId = false,
  }) {
    return MenuItem(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      emoji: emoji ?? this.emoji,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      isPopular: isPopular ?? this.isPopular,
      prepMinutes: prepMinutes ?? this.prepMinutes,
      linkedInventoryItemId: clearLinkedInventoryItemId
          ? null
          : (linkedInventoryItemId ?? this.linkedInventoryItemId),
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MenuItem && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
