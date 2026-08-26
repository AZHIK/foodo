import '../models/courier.dart';

/// Mock courier data for development.
abstract final class MockCouriers {
  static final list = [
    Courier(
      id: 'cur-01',
      name: 'James Chen',
      phone: '+1 (555) 111-2222',
      vehicle: 'Honda Civic - JX22KPL',
      status: CourierStatus.active,
    ),
    Courier(
      id: 'cur-02',
      name: 'Maria Rodriguez',
      phone: '+1 (555) 222-3333',
      vehicle: 'Ford Transit - MR21FLD',
      status: CourierStatus.active,
    ),
    Courier(
      id: 'cur-03',
      name: 'Dev Patel',
      phone: '+1 (555) 333-4444',
      vehicle: 'Bicycle - N/A',
      status: CourierStatus.active,
    ),
    Courier(
      id: 'cur-04',
      name: 'Emma White',
      phone: '+1 (555) 444-5555',
      vehicle: 'Vespa - EW19VES',
      status: CourierStatus.inactive,
    ),
  ];

  static String nextId(List<Courier> existing) {
    var highest = 0;
    for (final courier in existing) {
      final n = int.tryParse(courier.id.split('-').last);
      if (n != null && n > highest) highest = n;
    }
    return 'cur-${(highest + 1).toString().padLeft(2, '0')}';
  }
}
