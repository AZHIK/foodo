import '../models/supplier.dart';

/// Mock supplier data for development.
abstract final class MockSuppliers {
  static final list = [
    Supplier(
      id: 'sup-01',
      name: 'Fresh Foods Ltd',
      phone: '+1 (555) 010-1001',
      email: 'orders@freshfoods.test',
      createdAt: DateTime(2024, 1, 10),
    ),
    Supplier(
      id: 'sup-02',
      name: 'Beverage Co',
      phone: '+1 (555) 010-1002',
      email: 'sales@beverageco.test',
      createdAt: DateTime(2024, 2, 5),
    ),
    Supplier(
      id: 'sup-03',
      name: 'Supplier Hub',
      phone: '+1 (555) 010-1003',
      createdAt: DateTime(2024, 3, 20),
    ),
  ];

  static String nextId(List<Supplier> existing) {
    var highest = 0;
    for (final supplier in existing) {
      final n = int.tryParse(supplier.id.split('-').last);
      if (n != null && n > highest) highest = n;
    }
    return 'sup-${(highest + 1).toString().padLeft(2, '0')}';
  }
}
