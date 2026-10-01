import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/courier.dart';

/// The source of truth for all couriers.
///
/// Starts empty and fills from the courier directory (or local additions) —
/// never from bundled sample data.
class CouriersNotifier extends Notifier<List<Courier>> {
  @override
  List<Courier> build() => const [];

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
