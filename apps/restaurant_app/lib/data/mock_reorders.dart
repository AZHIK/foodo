import '../models/reorder.dart';

/// Mock reorder data for development.
abstract final class MockReorders {
  static final list = [
    Reorder(
      id: 'ro-001',
      inventoryItemId: 'inv-01',
      quantity: 50,
      unit: 'kg',
      unitCost: 12.50,
      supplier: 'Fresh Foods Ltd',
      orderedAt: DateTime.now().subtract(const Duration(days: 3)),
      expectedAt: DateTime.now().add(const Duration(days: 2)),
      status: ReorderStatus.pending,
    ),
    Reorder(
      id: 'ro-002',
      inventoryItemId: 'inv-03',
      quantity: 100,
      unit: 'L',
      unitCost: 2.75,
      supplier: 'Beverage Co',
      orderedAt: DateTime.now().subtract(const Duration(days: 7)),
      receivedAt: DateTime.now().subtract(const Duration(days: 1)),
      status: ReorderStatus.received,
      notes: 'Damaged one crate, replaced by supplier',
    ),
    Reorder(
      id: 'ro-003',
      inventoryItemId: 'inv-05',
      quantity: 30,
      unit: 'box',
      unitCost: 8.00,
      supplier: 'Supplier Hub',
      orderedAt: DateTime.now().subtract(const Duration(days: 5)),
      status: ReorderStatus.pending,
      expectedAt: DateTime.now(),
    ),
  ];

  static String nextId(List<Reorder> existing) {
    var highest = 0;
    for (final reorder in existing) {
      final n = int.tryParse(reorder.id.split('-').last);
      if (n != null && n > highest) highest = n;
    }
    return 'ro-${(highest + 1).toString().padLeft(3, '0')}';
  }
}
