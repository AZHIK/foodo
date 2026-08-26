import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_reorders.dart';
import '../models/reorder.dart';

/// The source of truth for all reorders.
class ReordersNotifier extends Notifier<List<Reorder>> {
  @override
  List<Reorder> build() => MockReorders.list;

  void upsert(Reorder reorder) {
    final index = state.indexWhere((r) => r.id == reorder.id);
    if (index == -1) {
      state = [reorder, ...state];
      return;
    }
    final next = [...state];
    next[index] = reorder;
    state = next;
  }

  void delete(String id) => state = state.where((r) => r.id != id).toList();

  String nextId() => MockReorders.nextId(state);
}

final reordersProvider =
    NotifierProvider<ReordersNotifier, List<Reorder>>(ReordersNotifier.new);

/// Active (pending) reorders sorted by expected arrival.
final activeReordersProvider = Provider<List<Reorder>>((ref) {
  final all = ref.watch(reordersProvider);
  final active = all.where((r) => r.status == ReorderStatus.pending).toList();
  active.sort((a, b) {
    final aExp = a.expectedAt ?? DateTime(2099);
    final bExp = b.expectedAt ?? DateTime(2099);
    return aExp.compareTo(bExp);
  });
  return active;
});

/// Lookup reorders by inventory item id.
final reordersByItemProvider = Provider.family<List<Reorder>, String>((ref, itemId) {
  return ref
      .watch(reordersProvider)
      .where((r) => r.inventoryItemId == itemId)
      .toList();
});
