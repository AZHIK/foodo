import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_couriers.dart';
import '../models/courier.dart';

/// The source of truth for all couriers.
class CouriersNotifier extends Notifier<List<Courier>> {
  @override
  List<Courier> build() => MockCouriers.list;

  void upsert(Courier courier) {
    final index = state.indexWhere((c) => c.id == courier.id);
    if (index == -1) {
      state = [courier, ...state];
      return;
    }
    final next = [...state];
    next[index] = courier;
    state = next;
  }

  void delete(String id) => state = state.where((c) => c.id != id).toList();

  String nextId() => MockCouriers.nextId(state);
}

final couriersProvider =
    NotifierProvider<CouriersNotifier, List<Courier>>(CouriersNotifier.new);

/// Active couriers available for assignment.
final activeCouriersProvider = Provider<List<Courier>>((ref) {
  return ref
      .watch(couriersProvider)
      .where((c) => c.status == CourierStatus.active)
      .toList();
});

/// Lookup by id.
final courierByIdProvider = Provider.family<Courier?, String>((ref, id) {
  for (final courier in ref.watch(couriersProvider)) {
    if (courier.id == id) return courier;
  }
  return null;
});
