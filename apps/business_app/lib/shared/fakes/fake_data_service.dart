import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// **Temporary, removable** provider of realistic dummy data for the
/// UI-foundation stages (Inventory UI, POS UI, Dashboard).
///
/// Cleanly separated under `lib/shared/fakes/` so it can be deleted
/// wholesale once real backend integration lands — nothing in the app
/// under test should depend on this except screen-level widget trees.
///
/// Provides:
/// - [inventoryItems]  — ~25 realistic restaurant inventory items with
///   varied categories, prices in TZS senti, stock levels that include
///   items below reorder threshold and some out-of-stock.
/// - [sales]           — ~18 fake sale records with varied statuses
///   (paid/voided/refunded), payment methods (cash/card/mobile),
///   timestamps spread across several days, and at least one
///   `isTimeSuspect: true` and one voided record.
class FakeDataService {
  FakeDataService({Random? random}) : _rand = random ?? Random(42);

  final Random _rand;

  // ── Inventory ───────────────────────────────────────────────────

  /// ~25 inventory items with varied categories, prices, stock levels.
  late final List<FakeInventoryItem> inventoryItems =
      List.unmodifiable(_buildInventory());

  // ── Sales ───────────────────────────────────────────────────────

  /// ~18 sales spanning multiple days with varied statuses/methods.
  late final List<FakeSale> sales = List.unmodifiable(_buildSales());

  // ── Internals ───────────────────────────────────────────────────

  List<FakeInventoryItem> _buildInventory() {
    const defs = <_ItemDef>[
      _ItemDef('Ugali', 'Staples', 200000, 68, 10, 50),
      _ItemDef('Wali (Rice)', 'Staples', 250000, 52, 10, 45),
      _ItemDef('Chapati', 'Staples', 80000, 120, 20, 80),
      _ItemDef('Mandazi', 'Pastries', 50000, 4, 10, 30),
      _ItemDef('Samosas (6 pcs)', 'Pastries', 180000, 22, 5, 25),
      _ItemDef('Beef Pilau', 'Rice Dishes', 850000, 18, 5, 20),
      _ItemDef('Chicken Biryani', 'Rice Dishes', 1200000, 0, 5, 15),
      _ItemDef('Vegetable Curry', 'Mains', 600000, 3, 5, 20),
      _ItemDef('Beef Stew', 'Mains', 750000, 25, 5, 20),
      _ItemDef('Grilled Tilapia', 'Mains', 1500000, 8, 3, 10),
      _ItemDef('Nyama Choma (1/4 kg)', 'Grills', 1200000, 11, 3, 10),
      _ItemDef('Mishkaki (Skewers)', 'Grills', 350000, 2, 10, 30),
      _ItemDef('Kachumbari', 'Sides', 100000, 40, 20, 50),
      _ItemDef('Pilipili Sauce', 'Sides', 40000, 85, 30, 60),
      _ItemDef('Mlenda (Greens)', 'Sides', 250000, 0, 5, 15),
      _ItemDef('Coca-Cola 300ml', 'Drinks', 120000, 36, 10, 30),
      _ItemDef('Fanta Orange 300ml', 'Drinks', 120000, 24, 10, 30),
      _ItemDef('Water 500ml', 'Drinks', 50000, 120, 20, 60),
      _ItemDef('Fresh Mango Juice', 'Drinks', 250000, 7, 5, 15),
      _ItemDef('Masala Chai', 'Drinks', 100000, 58, 10, 40),
      _ItemDef('Coffee (Black)', 'Drinks', 150000, 42, 10, 30),
      _ItemDef('Beer (Tusker)', 'Drinks', 350000, 15, 5, 20),
      _ItemDef('Banana (per bunch)', 'Ingredients', 60000, 6, 5, 15),
      _ItemDef('Onions (kg)', 'Ingredients', 180000, 8, 5, 20),
      _ItemDef('Cooking Oil 1L', 'Ingredients', 450000, 0, 3, 10),
    ];

    return defs.asMap().entries.map((e) {
      final i = e.key;
      final d = e.value;
      return FakeInventoryItem(
        id: 'inv_fake_${(i + 1).toString().padLeft(3, '0')}',
        name: d.name,
        category: d.category,
        sku:
            '${d.category.substring(0, 3).toUpperCase()}-${(1000 + i * 37) % 9000}',
        priceSenti: d.priceSenti,
        stockLevel: d.stockLevel,
        reorderThreshold: d.reorderThreshold,
        costPriceSenti: d.priceSenti ~/ 2,
        unit: _unitFor(d.category),
        barcode: '2${(1000000000 + i * 7919) % 999999999}',
        createdAt: _daysAgo(30 - (i * 13) % 28),
        updatedAt: _daysAgo((i * 3) % 7),
      );
    }).toList();
  }

  List<FakeSale> _buildSales() {
    final now = DateTime.now();
    const statuses = FakeSaleStatus.values;
    const methods = FakePaymentMethod.values;
    final inv = inventoryItems;
    final out = <FakeSale>[];

    for (var i = 0; i < 18; i++) {
      final status = i == 2
          ? FakeSaleStatus.voided
          : statuses[_rand.nextInt(statuses.length)];
      final method = methods[_rand.nextInt(methods.length)];
      final isTimeSuspect = i == 11;
      final dayOffset = (i * 17) % 8;
      final hour = 7 + ((i * 5) % 12);
      final minute = (i * 7) % 60;
      final at = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      ).subtract(Duration(days: dayOffset));

      final lineCount = 1 + _rand.nextInt(4);
      final lines = <FakeSaleLine>[];
      for (var l = 0; l < lineCount; l++) {
        final item = inv[(i * 3 + l * 7) % inv.length];
        final qty = 1 + _rand.nextInt(4);
        lines.add(FakeSaleLine(
          itemId: item.id,
          itemName: item.name,
          quantity: qty,
          unitPriceSenti: item.priceSenti,
          subtotalSenti: item.priceSenti * qty,
        ));
      }
      final totalSenti = lines.fold<int>(0, (a, b) => a + b.subtotalSenti);
      out.add(FakeSale(
        id: 'sale_fake_${(i + 1).toString().padLeft(4, '0')}',
        receiptNumber: 'REC-${2026}${(100000 + i * 719).toString()}',
        status: status,
        paymentMethod: method,
        lines: lines,
        totalSenti: totalSenti,
        tenderedSenti: status == FakeSaleStatus.voided ? 0 : totalSenti,
        staffName: const [
          'Amina Juma',
          'Kelvin Mwangi',
          'Sarah Kombo',
        ][i % 3],
        customerName: i.isEven ? 'Walk-in' : null,
        notes: i == 5 ? 'Customer requested extra sauce' : null,
        isTimeSuspect: isTimeSuspect,
        createdAt: at,
        closedAt: status == FakeSaleStatus.pending ? null : at,
        createdAtOffsetMs: 0,
        closedAtOffsetMs: 0,
      ));
    }
    // Ensure at least one voided and one time-suspect are present even if
    // the randomizer picked other things (defensive, for stable tests).
    out[2] = out[2].copyWith(status: FakeSaleStatus.voided);
    out[11] = out[11].copyWith(isTimeSuspect: true);
    return out;
  }

  DateTime _daysAgo(int n) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).subtract(Duration(days: n));
  }

  static String _unitFor(String category) {
    return switch (category) {
      'Ingredients' => 'kg',
      'Drinks' => 'pcs',
      _ => 'pcs',
    };
  }
}

// ── Models ─────────────────────────────────────────────────────────

/// Realistic fake inventory item. Mirrors the shape of the real
/// inventory domain model closely enough that swapping from fake → real
/// later is a mechanical change.
class FakeInventoryItem {
  const FakeInventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.sku,
    required this.priceSenti,
    required this.stockLevel,
    required this.reorderThreshold,
    required this.costPriceSenti,
    required this.unit,
    required this.barcode,
    required this.createdAt,
    required this.updatedAt,
    this.itemType = 'prepared_item',
    this.reorderQuantity = 20,
    this.allowNegativeStock = false,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String category;
  final String sku;
  final int priceSenti;
  final int stockLevel;
  final int reorderThreshold;
  final int costPriceSenti;
  final String unit;
  final String barcode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String itemType;
  final int reorderQuantity;
  final bool allowNegativeStock;
  final bool isActive;

  bool get isOutOfStock => stockLevel <= 0;
  bool get isLowStock =>
      stockLevel > 0 && stockLevel <= reorderThreshold;

  FakeInventoryItem copyWith({
    String? id,
    String? name,
    String? category,
    String? sku,
    int? priceSenti,
    int? stockLevel,
    int? reorderThreshold,
    int? costPriceSenti,
    String? unit,
    String? barcode,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? itemType,
    int? reorderQuantity,
    bool? allowNegativeStock,
    bool? isActive,
  }) {
    return FakeInventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      sku: sku ?? this.sku,
      priceSenti: priceSenti ?? this.priceSenti,
      stockLevel: stockLevel ?? this.stockLevel,
      reorderThreshold: reorderThreshold ?? this.reorderThreshold,
      costPriceSenti: costPriceSenti ?? this.costPriceSenti,
      unit: unit ?? this.unit,
      barcode: barcode ?? this.barcode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      itemType: itemType ?? this.itemType,
      reorderQuantity: reorderQuantity ?? this.reorderQuantity,
      allowNegativeStock: allowNegativeStock ?? this.allowNegativeStock,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Fake stock movement log record.
class FakeMovement {
  const FakeMovement({
    required this.id,
    required this.itemId,
    required this.type,
    required this.quantityDelta,
    required this.reason,
    required this.actor,
    required this.createdAt,
  });

  final String id;
  final String itemId;
  final String type;
  final int quantityDelta;
  final String reason;
  final String actor;
  final DateTime createdAt;
}

/// Riverpod [StateNotifier] for mutating fake inventory state in-memory.
class FakeInventoryNotifier extends StateNotifier<List<FakeInventoryItem>> {
  FakeInventoryNotifier(FakeDataService dataService)
      : super(dataService.inventoryItems) {
    _initMovements();
  }

  final Map<String, List<FakeMovement>> _movements = {};

  List<FakeMovement> getMovements(String itemId) =>
      _movements[itemId] ?? const [];

  void _initMovements() {
    for (final item in state) {
      _movements[item.id] = [
        FakeMovement(
          id: 'mov_init_${item.id}',
          itemId: item.id,
          type: 'Stock Intake',
          quantityDelta: item.stockLevel,
          reason: 'Initial stock setup',
          actor: 'System Manager',
          createdAt: item.createdAt,
        ),
      ];
    }
  }

  /// Replaces the whole item list with [items] and rebuilds the movement
  /// log to match — used by tests to seed a deterministic fake dataset.
  void loadItems(List<FakeInventoryItem> items) {
    _movements.clear();
    for (final item in items) {
      _movements[item.id] = [
        FakeMovement(
          id: 'mov_init_${item.id}',
          itemId: item.id,
          type: 'Stock Intake',
          quantityDelta: item.stockLevel,
          reason: 'Initial stock setup',
          actor: 'System Manager',
          createdAt: item.createdAt,
        ),
      ];
    }
    state = items;
  }

  void addItem(FakeInventoryItem item) {
    state = [item, ...state];
    _movements[item.id] = [
      FakeMovement(
        id: 'mov_${DateTime.now().millisecondsSinceEpoch}',
        itemId: item.id,
        type: 'Item Created',
        quantityDelta: item.stockLevel,
        reason: 'Initial creation',
        actor: 'Store Admin',
        createdAt: DateTime.now(),
      ),
    ];
  }

  void updateItem(FakeInventoryItem item) {
    state = [
      for (final existing in state)
        if (existing.id == item.id) item else existing,
    ];
  }

  void adjustStock(String itemId, int delta, String reason) {
    state = [
      for (final item in state)
        if (item.id == itemId)
          item.copyWith(
            stockLevel: item.stockLevel + delta,
            updatedAt: DateTime.now(),
          )
        else
          item,
    ];

    final list = _movements[itemId] ?? [];
    _movements[itemId] = [
      FakeMovement(
        id: 'mov_${DateTime.now().millisecondsSinceEpoch}',
        itemId: itemId,
        type: delta >= 0 ? 'Adjustment (+)' : 'Adjustment (-)',
        quantityDelta: delta,
        reason: reason,
        actor: 'Store Admin',
        createdAt: DateTime.now(),
      ),
      ...list,
    ];
  }

  void recordWaste(String itemId, int quantity, String reason) {
    adjustStock(itemId, -quantity, 'Waste: $reason');
  }

  void transferStock(String itemId, String source, String destination, int quantity) {
    adjustStock(itemId, -quantity, 'Transfer: $source → $destination');
  }
}

final fakeInventoryProvider =
    StateNotifierProvider<FakeInventoryNotifier, List<FakeInventoryItem>>((ref) {
  final service = FakeDataService();
  return FakeInventoryNotifier(service);
});

final fakeMovementsProvider = Provider.family<List<FakeMovement>, String>((ref, itemId) {
  final notifier = ref.watch(fakeInventoryProvider.notifier);
  return notifier.getMovements(itemId);
});

enum FakeSaleStatus {
  pending,
  paid,
  voided,
  refunded,
}

enum FakePaymentMethod {
  cash,
  card,
  mobileMoney,
}

class FakeSaleLine {
  const FakeSaleLine({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitPriceSenti,
    required this.subtotalSenti,
  });

  final String itemId;
  final String itemName;
  final int quantity;
  final int unitPriceSenti;
  final int subtotalSenti;
}

class FakeSale {
  const FakeSale({
    required this.id,
    required this.receiptNumber,
    required this.status,
    required this.paymentMethod,
    required this.lines,
    required this.totalSenti,
    required this.tenderedSenti,
    required this.staffName,
    required this.customerName,
    required this.notes,
    required this.isTimeSuspect,
    required this.createdAt,
    required this.closedAt,
    required this.createdAtOffsetMs,
    required this.closedAtOffsetMs,
  });

  final String id;
  final String receiptNumber;
  final FakeSaleStatus status;
  final FakePaymentMethod paymentMethod;
  final List<FakeSaleLine> lines;
  final int totalSenti;
  final int tenderedSenti;
  final String staffName;
  final String? customerName;
  final String? notes;
  final bool isTimeSuspect;
  final DateTime createdAt;
  final DateTime? closedAt;
  final int createdAtOffsetMs;
  final int? closedAtOffsetMs;

  FakeSale copyWith({
    FakeSaleStatus? status,
    bool? isTimeSuspect,
  }) =>
      FakeSale(
        id: id,
        receiptNumber: receiptNumber,
        status: status ?? this.status,
        paymentMethod: paymentMethod,
        lines: lines,
        totalSenti: totalSenti,
        tenderedSenti: tenderedSenti,
        staffName: staffName,
        customerName: customerName,
        notes: notes,
        isTimeSuspect: isTimeSuspect ?? this.isTimeSuspect,
        createdAt: createdAt,
        closedAt: closedAt,
        createdAtOffsetMs: createdAtOffsetMs,
        closedAtOffsetMs: closedAtOffsetMs,
      );
}

class _ItemDef {
  const _ItemDef(
    this.name,
    this.category,
    this.priceSenti,
    this.stockLevel,
    this.reorderThreshold,
    this.idealStock,
  );
  final String name;
  final String category;
  final int priceSenti;
  final int stockLevel;
  final int reorderThreshold;
  final int idealStock;
}
