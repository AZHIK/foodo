import 'package:flutter/material.dart';

import '../models/menu_item.dart';

/// In-memory stand-in for a menu service.
///
/// Swap this class for an HTTP/DB implementation and only
/// `lib/providers/menu_providers.dart` needs to change.
abstract final class MockMenu {
  static MenuCategory? categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  static String categoryLabel(String id) => categoryById(id)?.label ?? id;

  /// Position in [categories], used to assign a stable colour to a category.
  ///
  /// Keyed to the catalogue's own order rather than to however a chart happens
  /// to have sorted its slices, so "Mains" is the same colour in the donut and
  /// on the rank badge beside it.
  static int categoryIndex(String id) {
    for (var i = 0; i < categories.length; i++) {
      if (categories[i].id == id) return i;
    }
    // Anything uncategorised lands after the known categories rather than
    // stealing the first one's colour.
    return categories.length;
  }

  static const categories = <MenuCategory>[
    MenuCategory(id: 'starters', label: 'Starters', icon: Icons.set_meal_rounded),
    MenuCategory(id: 'mains', label: 'Mains', icon: Icons.dinner_dining_rounded),
    MenuCategory(id: 'sides', label: 'Sides', icon: Icons.rice_bowl_rounded),
    MenuCategory(id: 'drinks', label: 'Drinks', icon: Icons.local_bar_rounded),
    MenuCategory(id: 'desserts', label: 'Desserts', icon: Icons.icecream_rounded),
  ];

  static const items = <MenuItem>[
    // ---- Starters -------------------------------------------------------
    MenuItem(
      id: 'st-01',
      name: 'Truffle Arancini',
      description: 'Crispy risotto balls, black truffle, parmesan cream',
      price: 12.50,
      categoryId: 'starters',
      emoji: '🍙',
      isPopular: true,
      prepMinutes: 12,
    ),
    MenuItem(
      id: 'st-02',
      name: 'Burrata & Heirloom',
      description: 'Creamy burrata, heirloom tomato, basil oil, sourdough',
      price: 14.00,
      categoryId: 'starters',
      emoji: '🍅',
      prepMinutes: 8,
    ),
    MenuItem(
      id: 'st-03',
      name: 'Charred Octopus',
      description: 'Smoked paprika, confit potato, salsa verde',
      price: 16.75,
      categoryId: 'starters',
      emoji: '🐙',
      prepMinutes: 15,
    ),
    MenuItem(
      id: 'st-04',
      name: 'Soup of the Day',
      description: 'Ask your server — served with warm focaccia',
      price: 8.25,
      categoryId: 'starters',
      emoji: '🍜',
      prepMinutes: 6,
    ),
    MenuItem(
      id: 'st-05',
      name: 'Garlic Prawns',
      description: 'Chilli, white wine, parsley, grilled bread',
      price: 15.50,
      categoryId: 'starters',
      emoji: '🍤',
      isPopular: true,
      prepMinutes: 12,
    ),
    MenuItem(
      id: 'st-06',
      name: 'Beef Tartare',
      description: 'Hand-cut sirloin, cured yolk, crisp shallot',
      price: 17.00,
      categoryId: 'starters',
      emoji: '🥩',
      isAvailable: false,
      prepMinutes: 10,
    ),

    // ---- Mains ----------------------------------------------------------
    MenuItem(
      id: 'mn-01',
      name: 'Dry-Aged Ribeye',
      description: '400g, 45-day aged, bone marrow butter, triple-cooked chips',
      price: 42.00,
      categoryId: 'mains',
      emoji: '🥩',
      isPopular: true,
      prepMinutes: 25,
    ),
    MenuItem(
      id: 'mn-02',
      name: 'Wild Mushroom Risotto',
      description: 'Carnaroli rice, porcini, aged pecorino, chive oil',
      price: 24.50,
      categoryId: 'mains',
      emoji: '🍄',
      prepMinutes: 22,
    ),
    MenuItem(
      id: 'mn-03',
      name: 'Miso Black Cod',
      description: 'Saikyo miso glaze, pickled ginger, bok choy',
      price: 34.00,
      categoryId: 'mains',
      emoji: '🐟',
      isPopular: true,
      prepMinutes: 20,
    ),
    MenuItem(
      id: 'mn-04',
      name: 'Smash Burger',
      description: 'Double patty, aged cheddar, house pickles, secret sauce',
      price: 19.50,
      categoryId: 'mains',
      emoji: '🍔',
      isPopular: true,
      prepMinutes: 14,
    ),
    MenuItem(
      id: 'mn-05',
      name: 'Margherita Pizza',
      description: '48-hour dough, San Marzano, fior di latte, basil',
      price: 17.00,
      categoryId: 'mains',
      emoji: '🍕',
      prepMinutes: 11,
    ),
    MenuItem(
      id: 'mn-06',
      name: 'Herb Roast Chicken',
      description: 'Half free-range bird, lemon thyme jus, greens',
      price: 26.00,
      categoryId: 'mains',
      emoji: '🍗',
      prepMinutes: 28,
    ),
    MenuItem(
      id: 'mn-07',
      name: 'Cacio e Pepe',
      description: 'Fresh tonnarelli, pecorino romano, cracked pepper',
      price: 21.00,
      categoryId: 'mains',
      emoji: '🍝',
      prepMinutes: 15,
    ),
    MenuItem(
      id: 'mn-08',
      name: 'Lamb Shank Tagine',
      description: 'Apricot, harissa, almond couscous, coriander',
      price: 29.50,
      categoryId: 'mains',
      emoji: '🍲',
      prepMinutes: 18,
    ),

    // ---- Sides ----------------------------------------------------------
    MenuItem(
      id: 'sd-01',
      name: 'Triple-Cooked Chips',
      description: 'Rosemary salt, garlic aioli',
      price: 7.50,
      categoryId: 'sides',
      emoji: '🍟',
      isPopular: true,
      prepMinutes: 8,
    ),
    MenuItem(
      id: 'sd-02',
      name: 'Charred Broccolini',
      description: 'Chilli, lemon, toasted almond',
      price: 8.00,
      categoryId: 'sides',
      emoji: '🥦',
      prepMinutes: 7,
    ),
    MenuItem(
      id: 'sd-03',
      name: 'House Garden Salad',
      description: 'Little gem, radish, sherry vinaigrette',
      price: 6.75,
      categoryId: 'sides',
      emoji: '🥗',
      prepMinutes: 5,
    ),
    MenuItem(
      id: 'sd-04',
      name: 'Truffle Mac & Cheese',
      description: 'Three cheeses, herbed crumb',
      price: 11.00,
      categoryId: 'sides',
      emoji: '🧀',
      prepMinutes: 10,
    ),

    // ---- Drinks ---------------------------------------------------------
    MenuItem(
      id: 'dr-01',
      name: 'Old Fashioned',
      description: 'Bourbon, demerara, aromatic bitters, orange',
      price: 15.00,
      categoryId: 'drinks',
      emoji: '🥃',
      isPopular: true,
      prepMinutes: 4,
    ),
    MenuItem(
      id: 'dr-02',
      name: 'House Negroni',
      description: 'Gin, campari, sweet vermouth, on the rocks',
      price: 14.00,
      categoryId: 'drinks',
      emoji: '🍸',
      prepMinutes: 4,
    ),
    MenuItem(
      id: 'dr-03',
      name: 'Craft Lager',
      description: 'Local pilsner, 330ml, ice cold',
      price: 8.50,
      categoryId: 'drinks',
      emoji: '🍺',
      prepMinutes: 2,
    ),
    MenuItem(
      id: 'dr-04',
      name: 'Malbec, Glass',
      description: 'Mendoza, plum and black pepper',
      price: 12.00,
      categoryId: 'drinks',
      emoji: '🍷',
      prepMinutes: 2,
    ),
    MenuItem(
      id: 'dr-05',
      name: 'Flat White',
      description: 'Single-origin espresso, silky microfoam',
      price: 5.25,
      categoryId: 'drinks',
      emoji: '☕',
      isPopular: true,
      prepMinutes: 3,
    ),
    MenuItem(
      id: 'dr-06',
      name: 'Fresh Orange Juice',
      description: 'Cold-pressed to order',
      price: 6.00,
      categoryId: 'drinks',
      emoji: '🍊',
      prepMinutes: 3,
    ),
    MenuItem(
      id: 'dr-07',
      name: 'Sparkling Water',
      description: 'Still or sparkling, 750ml',
      price: 4.50,
      categoryId: 'drinks',
      emoji: '💧',
      prepMinutes: 1,
    ),

    // ---- Desserts -------------------------------------------------------
    MenuItem(
      id: 'ds-01',
      name: 'Basque Cheesecake',
      description: 'Burnt top, vanilla bean, macerated berries',
      price: 11.50,
      categoryId: 'desserts',
      emoji: '🍰',
      isPopular: true,
      prepMinutes: 5,
    ),
    MenuItem(
      id: 'ds-02',
      name: 'Dark Chocolate Fondant',
      description: '70% Valrhona, salted caramel gelato',
      price: 12.50,
      categoryId: 'desserts',
      emoji: '🍫',
      prepMinutes: 14,
    ),
    MenuItem(
      id: 'ds-03',
      name: 'Tiramisu',
      description: 'Mascarpone, espresso-soaked savoiardi, cocoa',
      price: 10.00,
      categoryId: 'desserts',
      emoji: '🍮',
      prepMinutes: 5,
    ),
    MenuItem(
      id: 'ds-04',
      name: 'Gelato Selection',
      description: 'Three scoops, ask for today’s flavours',
      price: 8.50,
      categoryId: 'desserts',
      emoji: '🍨',
      prepMinutes: 3,
    ),
  ];
}
