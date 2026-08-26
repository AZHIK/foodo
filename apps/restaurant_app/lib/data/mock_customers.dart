import '../models/customer.dart';

/// Mock customer data for development.
abstract final class MockCustomers {
  static final list = [
    Customer(
      id: 'cus-01',
      name: 'Alice Johnson',
      phone: '+1 (555) 123-4567',
      email: 'alice@example.com',
      addressLine1: '123 Oak Street',
      createdAt: DateTime(2024, 6, 15),
      lastOrderAt: DateTime.now().subtract(const Duration(days: 2)),
      totalOrders: 8,
      totalSpent: 156.40,
    ),
    Customer(
      id: 'cus-02',
      name: 'Bob Smith',
      phone: '+1 (555) 234-5678',
      email: 'bob@example.com',
      addressLine1: '456 Maple Avenue',
      createdAt: DateTime(2024, 5, 10),
      lastOrderAt: DateTime.now().subtract(const Duration(days: 5)),
      totalOrders: 12,
      totalSpent: 287.65,
    ),
    Customer(
      id: 'cus-03',
      name: 'Carol Wilson',
      phone: '+1 (555) 345-6789',
      email: 'carol@example.com',
      addressLine1: '789 Pine Road',
      createdAt: DateTime(2024, 4, 20),
      lastOrderAt: DateTime.now().subtract(const Duration(days: 1)),
      totalOrders: 15,
      totalSpent: 412.30,
    ),
    Customer(
      id: 'cus-04',
      name: 'David Brown',
      phone: '+1 (555) 456-7890',
      addressLine1: '321 Elm Street',
      createdAt: DateTime(2024, 3, 1),
      lastOrderAt: DateTime.now().subtract(const Duration(days: 10)),
      totalOrders: 6,
      totalSpent: 98.75,
    ),
    Customer(
      id: 'cus-05',
      name: 'Emma Davis',
      phone: '+1 (555) 567-8901',
      email: 'emma@example.com',
      createdAt: DateTime(2024, 2, 15),
      lastOrderAt: DateTime.now().subtract(const Duration(days: 7)),
      totalOrders: 9,
      totalSpent: 189.20,
    ),
    Customer(
      id: 'cus-06',
      name: 'Frank Miller',
      phone: '+1 (555) 678-9012',
      email: 'frank@example.com',
      addressLine1: '654 Cedar Lane',
      createdAt: DateTime(2024, 1, 5),
      lastOrderAt: DateTime.now().subtract(const Duration(days: 3)),
      totalOrders: 18,
      totalSpent: 534.50,
    ),
    Customer(
      id: 'cus-07',
      name: 'Grace Taylor',
      phone: '+1 (555) 789-0123',
      createdAt: DateTime(2023, 12, 20),
      lastOrderAt: DateTime.now().subtract(const Duration(days: 15)),
      totalOrders: 11,
      totalSpent: 267.40,
    ),
    Customer(
      id: 'cus-08',
      name: 'Henry Anderson',
      phone: '+1 (555) 890-1234',
      email: 'henry@example.com',
      addressLine1: '987 Birch Boulevard',
      createdAt: DateTime(2023, 11, 10),
      lastOrderAt: DateTime.now().subtract(const Duration(days: 20)),
      totalOrders: 7,
      totalSpent: 142.85,
    ),
  ];

  /// Generate the next customer id based on the highest existing id.
  static String nextId(List<Customer> existing) {
    var highest = 0;
    for (final customer in existing) {
      final n = int.tryParse(customer.id.split('-').last);
      if (n != null && n > highest) highest = n;
    }
    return 'cus-${(highest + 1).toString().padLeft(2, '0')}';
  }
}
