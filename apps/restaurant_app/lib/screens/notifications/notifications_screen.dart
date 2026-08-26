import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/notification.dart';
import '../../providers/notifications_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../../widgets/data_page/status_badge.dart';

/// Persistent notification center showing all app alerts.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () => notifier.markAllRead(),
              child: const Text('Mark all read'),
            ),
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(Insets.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 48,
                      color: context.colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: Insets.lg),
                    Text(
                      'No notifications yet',
                      style: context.text.titleMedium,
                    ),
                    const SizedBox(height: Insets.md),
                    Text(
                      'Orders, low stock alerts and insights will appear here',
                      style: context.text.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: Insets.md),
              itemCount: notifications.length,
              itemBuilder: (context, index) => _NotificationTile(
                notification: notifications[index],
                onTap: () => _handleNotificationTap(context, ref, notifications[index]),
                onMarkRead: () => notifier.markRead(notifications[index].id),
              ),
            ),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    ref.read(notificationsProvider.notifier).markRead(notification.id);

    if (notification.relatedEntityId == null) return;

    switch (notification.type) {
      case NotificationType.newOrder:
      case NotificationType.deliveryUpdate:
        context.go(AppRoute.orderDetail(notification.relatedEntityId!));
      case NotificationType.lowStock:
        context.go(AppRoute.itemDetail(notification.relatedEntityId!));
      case NotificationType.aiInsight:
        // Navigate to insights screen or detail if available
        context.goNamed(AppRoute.insightsName);
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onMarkRead,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final semantic = context.semantic;

    return Material(
      color: notification.isRead
          ? Colors.transparent
          : context.colors.primaryContainer.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg,
            vertical: Insets.md,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: semantic.hairline),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                alignment: Alignment.center,
                child: Icon(
                  notification.type.icon,
                  size: 24,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: Insets.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: context.text.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: Insets.md),
                        StatusBadge(
                          label: notification.type.label,
                          tone: _toneForType(notification.type),
                          dense: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: Insets.xs),
                    Text(
                      notification.body,
                      style: context.text.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Insets.sm),
                    Row(
                      children: [
                        Text(
                          Fmt.relativeDateTime(notification.createdAt),
                          style: context.text.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        if (!notification.isRead)
                          TextButton(
                            onPressed: onMarkRead,
                            child: const Text('Mark as read'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  StatusTone _toneForType(NotificationType type) {
    return switch (type) {
      NotificationType.newOrder => StatusTone.positive,
      NotificationType.lowStock => StatusTone.warning,
      NotificationType.aiInsight => StatusTone.info,
      NotificationType.deliveryUpdate => StatusTone.positive,
    };
  }
}
