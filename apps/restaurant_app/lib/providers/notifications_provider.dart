import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification.dart';
import 'orders_provider.dart';

/// The source of truth for all app notifications.
class NotificationsNotifier extends Notifier<List<AppNotification>> {
  var _nextId = 1;

  @override
  List<AppNotification> build() {
    // Listen for new orders and add notifications.
    ref.listen(ordersProvider, (prev, next) {
      if (prev == null) return;

      // Find orders that weren't in the previous list (new orders).
      for (final order in next) {
        final isNew = prev.indexWhere((o) => o.id == order.id) == -1;
        if (isNew && order.isRecent(DateTime.now())) {
          add(
            AppNotification(
              id: _generateId(),
              type: NotificationType.newOrder,
              title: 'New order received',
              body: '${order.itemCount} items · ${order.id}',
              createdAt: DateTime.now(),
              relatedEntityId: order.id,
            ),
          );
        }
      }
    });

    return const [];
  }

  void add(AppNotification notification) =>
      state = [notification, ...state];

  void markRead(String id) =>
      state = [for (final n in state) n.id == id ? n.copyWith(isRead: true) : n];

  void markAllRead() =>
      state = [for (final n in state) n.copyWith(isRead: true)];

  void delete(String id) => state = state.where((n) => n.id != id).toList();

  String _generateId() => 'notif-${(_nextId++).toString().padLeft(4, '0')}';
}

/// All notifications, newest first.
final notificationsProvider = NotifierProvider<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);

/// Count of unread notifications.
final notificationsUnreadCountProvider = Provider<int>(
  (ref) => ref.watch(notificationsProvider).where((n) => !n.isRead).length,
);
